import Foundation

// Port of the Android Chat.kt (filter + elf brain). Keep them in sync.

/// One chat message. `from` is an elf's name or "me" (the player).
struct ChatMsg: Codable, Hashable {
    var from: String
    var text: String
    var time: Double
    var options: [String] = []
    var qid: String?
}

let groupThread = "group"
let me = "me"

// MARK: - Safety filter

enum ChatFilter {
    enum Flag { case ok, unkind, violent, grown, personal, hurting }

    private static let leet: [Character: Character] = ["0": "o", "1": "i", "3": "e", "4": "a", "5": "s", "7": "t", "@": "a", "$": "s", "!": "i"]
    private static let swears: Set<String> = [
        "fuck", "fuk", "fck", "fuq", "shit", "sht", "bitch", "biatch", "bastard", "damn", "crap", "dick", "piss", "cunt",
        "asshole", "ass", "arse", "wtf", "stfu", "slut", "whore", "fag", "retard", "bollocks", "wanker", "twat", "prick", "bullshit",
    ]
    private static let swearStarts = ["fuck", "shit", "bitch", "asshol", "dickhead", "motherf"]
    private static let unkind: Set<String> = ["stupid", "dumb", "idiot", "loser", "ugly", "moron", "dork", "sucks", "suck"]
    private static let violent: Set<String> = ["kill", "killed", "killing", "murder", "die", "dead", "blood", "bloody", "gun", "guns", "shoot", "shooting", "stab", "knife", "bomb", "weapon", "torture", "strangle"]
    private static let grown: Set<String> = ["sex", "sexy", "naked", "nude", "nudes", "boob", "boobs", "penis", "vagina", "porn", "horny", "dildo", "condom", "kinky"]
    private static let hurtingPhrases = ["killmyself", "hurtmyself", "wanttodie", "wannadie", "endmylife", "hatemylife", "nobodylovesme", "nobodylikesme", "iwanttodie"]

    /// Squash repeated letters: "fuuuuck" -> "fuck".
    private static func squash(_ s: String) -> String {
        var out = ""
        for c in s where out.last != c { out.append(c) }
        return out
    }

    private static func tokens(_ text: String) -> [String] {
        let normal = String(text.lowercased().map { leet[$0] ?? $0 })
        return normal.split(whereSeparator: { !("a"..."z").contains($0) }).map(String.init)
    }

    private static func hit(_ token: String, _ words: Set<String>) -> Bool {
        if words.contains(token) { return true }
        let sq = squash(token)
        return sq.count >= 3 && words.contains { squash($0) == sq && token.count > $0.count }
    }

    /// The text with bad words starred out, plus what kind of problem (if any) we found.
    static func check(_ raw: String) -> (String, Flag) {
        let joined = squash(tokens(raw).joined())
        if hurtingPhrases.contains(where: { joined.contains(squash($0)) }) { return (raw, .hurting) }

        let lower = raw.lowercased()
        let personal = raw.filter(\.isNumber).count >= 7 || raw.range(of: #"\S+@\S+\.\S+"#, options: .regularExpression) != nil ||
            ["my address", "i live at", "i live on", "my phone number", "my number is", "my password", "my school is"].contains { lower.contains($0) }

        var flag = Flag.ok
        func raise(_ f: Flag) { if flag == .ok || f == .grown { flag = f } }
        var out = ""
        var word = ""
        func flush() {
            guard !word.isEmpty else { return }
            let t = tokens(word).joined()
            let stars = String(repeating: "★", count: min(max(word.count, 3), 8))
            if t.isEmpty { out += word }
            else if hit(t, swears) || swearStarts.contains(where: { t.hasPrefix($0) }) { raise(.unkind); out += stars }
            else if hit(t, grown) { raise(.grown); out += stars }
            else if hit(t, violent) { raise(.violent); out += word }
            else if hit(t, unkind) { raise(.unkind); out += word }
            else { out += word }
            word = ""
        }
        for ch in raw {
            if ch.isWhitespace { flush(); out.append(ch) } else { word.append(ch) }
        }
        flush()
        if flag == .ok && ["shutup", "hateyou", "ihateu"].contains(where: { joined.contains(squash($0)) }) { flag = .unkind }
        if flag == .violent && ["snowbal", "deadtired", "dielaughing"].contains(where: { joined.contains(squash($0)) }) { flag = .ok }
        if flag == .ok && personal { flag = .personal }
        return (out, flag)
    }

    static func safetyReply(_ flag: Flag, elf: String) -> String {
        switch flag {
        case .hurting: return "I'm really glad you told me. 💖 That sounds really hard. Please talk to a grown-up you trust RIGHT NOW, like a parent, teacher or family member. They love you and want to help."
        case .personal: return "Whoa, wait! 🔒 Never share your address, phone number, school or passwords online, even with elves. Let's keep that secret safe!"
        case .violent: return ["Eek! 😳 Let's keep things cozy and safe in Christmas Town. Want to talk about cookies instead? 🍪", "Yikes, that sounds scary! Let's talk about something happy, like reindeer! 🦌"].randomElement()!
        case .grown: return "Hmm, let's keep our chat kid-friendly! 🎄 Ask me about toys, cookies or reindeer!"
        case .unkind:
            switch elf {
            case "Pepper": return "Ooh, let's use kind words, sweetie. 💖 Kind words are like warm cookies!"
            case "Sprout": return "Um... that's not very kind. 🥺 Let's be nice to each other, okay?"
            case "Twinkle": return "Nooo, mean words aren't sparkly! ✨ Let's use kind ones!"
            case "Holly": return "Hmm, my kindness-o-meter just beeped 📟 Let's try nicer words!"
            case "Frost": return "Brrr, that was a chilly thing to say! 🥶 Let's keep it warm and kind."
            default: return "Whoa, let's use kind words in Christmas Town! 💖"
            }
        case .ok: return ""
        }
    }
}

// MARK: - Questions elves ask you

struct Question {
    let id: String
    let ask: String
    let options: [String]
    var memory: String? = nil
    let react: (String) -> String
}

private let dmQuestions: [String: [Question]] = [
    "Jingle": [
        Question(id: "j_toy", ask: "What's your favorite toy to make? 🧸", options: ["Teddy bears", "Candy canes", "Trains"], memory: "favToy") { "\($0)?! Awesome choice! 🔧 I'll save you the best parts!" },
        Question(id: "j_build", ask: "If you could invent ANY toy, what would it be? 🤔", options: ["Flying bike", "Robot dog", "Rainbow yo-yo"]) { "A \($0)?! That's GENIUS. Let's build it after Christmas! 🛠️" },
    ],
    "Twinkle": [
        Question(id: "t_theme", ask: "What should my next party theme be? ✨", options: ["Candy Land", "Snow Princess", "Pajama Party"], memory: "favParty") { "\($0)!!! OMG yes, I'm already planning the decorations! 🎉" },
        Question(id: "t_color", ask: "What's your favorite color? 🌈", options: ["Pink", "Blue", "Green", "Purple"], memory: "favColor") { "\($0) is SO pretty! I'll use lots of \($0) glitter just for you ✨" },
    ],
    "Pepper": [
        Question(id: "p_cookie", ask: "What's your favorite cookie? 🍪", options: ["Sugar", "Berry", "Choc chip"], memory: "favCookie") { "Ooh, \($0) cookies! I'll bake an extra batch just for you, sweetie 💕" },
        Question(id: "p_drink", ask: "Hot cocoa or warm milk? ☕", options: ["Hot cocoa", "Warm milk"]) { "\($0) it is! With a cinnamon sprinkle on top 😋" },
    ],
    "Holly": [
        Question(id: "h_invent", ask: "If I built you a robot helper, what should it do? 🤖", options: ["Make cookies", "Walk my pet", "Wrap presents"]) { "A robot that can \($0)? Drawing the plans RIGHT NOW! 📐" },
        Question(id: "h_power", ask: "Which superpower would you pick? ⚡", options: ["Flying", "Invisibility", "Talking to animals"]) { "\($0)! I'll try to invent it. No promises! 🔬" },
    ],
    "Frost": [
        Question(id: "f_joke", ask: "Want to hear a joke or tell me one? 😆", options: ["Tell me one!", "I'll tell you!"]) { $0.contains("me") ? "What's a snowman's favorite snack? ICE crispy treats! ❄️😂" : "Ooh, go go go! I'm ready to laugh! 😆" },
        Question(id: "f_build", ask: "What should I sculpt out of snow next? ⛄", options: ["A dragon", "Santa", "A giant cookie"]) { "\($0) made of snow?! That's going to be EPIC. ❄️" },
    ],
    "Sprout": [
        Question(id: "s_deer", ask: "Which reindeer do you like best? 🦌", options: ["Dasher", "Comet", "Rudolph"], memory: "favReindeer") { "\($0) is really sweet. 🥰 I'll tell them you said hi." },
        Question(id: "s_pet", ask: "Do you have a favorite animal? 🐾", options: ["Dogs", "Cats", "Bunnies", "Reindeer!"]) { "\($0) are the best! Animals make everything cozier. 🌱" },
    ],
]

private let groupQuestions: [Question] = [
    Question(id: "g_topping", ask: "@{me} quick poll: sprinkles or chocolate chips? 🍪", options: ["Sprinkles ✨", "Chocolate chips 🍫"], memory: "favTopping") { "\($0.split(separator: " ").dropLast().joined(separator: " ")) gang!! 🙌" },
    Question(id: "g_fast", ask: "@{me} which reindeer is the FASTEST? 🦌💨", options: ["Dasher", "Comet", "Rudolph"]) { "\($0)?! Great pick! I'll tell them, they'll be so proud 🏆" },
    Question(id: "g_hat", ask: "@{me} what color should my new hat be? 🎩", options: ["Red", "Green", "Sparkly gold"]) { "\($0) hat coming right up! 🧵" },
    Question(id: "g_snow", ask: "@{me} snowball fight or build a snowman? ⛄", options: ["Snowball fight!", "Snowman!"]) { "\($0.replacingOccurrences(of: "!", with: "")) it is! Meet us outside after work! ❄️" },
    Question(id: "g_next", ask: "@{me} what toy should we make next? 🧸", options: ["Teddy bear", "Robot", "Toy train"]) { "A \($0)! On it! 🔨" },
    Question(id: "g_time", ask: "@{me} are you a morning elf or a night elf? 🌙", options: ["Morning ☀️", "Night 🌙"]) { $0.contains("Morning") ? "Early bird! ☀️ You must get SO much done!" : "Night owl! 🦉 Same here, the stars are the best." },
    Question(id: "g_cocoa", ask: "@{me} hot cocoa: marshmallows or whipped cream? ☕", options: ["Marshmallows", "Whipped cream", "BOTH"]) { $0 == "BOTH" ? "BOTH?! Legendary. 😎☕" : "\($0)! Yum yum yum 😋" },
    Question(id: "g_song", ask: "@{me} what's the best Christmas song? 🎶", options: ["Jingle Bells", "Rudolph", "Let It Snow"]) { "🎶 \($0) 🎶 now it's stuck in my head 😂" },
    Question(id: "g_santa", ask: "@{me} does Santa like cookies or carrots more? 😂", options: ["Cookies!", "Carrots!"]) { $0.contains("Carrots") ? "Carrots?! Those are for the reindeer, silly! 🥕😂" : "Cookies, OBVIOUSLY! 🍪🎅" },
    Question(id: "g_party", ask: "@{me} want to come to the snow party on Friday? 🎉", options: ["Yes!", "Maybe"]) { $0 == "Yes!" ? "YAY!! It won't be a party without you! 🎉" : "Hope you can make it! There'll be cake 🎂" },
    Question(id: "g_gift", ask: "@{me} what present would YOU want from Santa? 🎁", options: ["A puppy", "A bike", "Art supplies", "A surprise"]) { "\($0)! I'll whisper it to Santa 🤫🎅" },
]

private let allQuestions: [String: Question] = Dictionary(uniqueKeysWithValues: (dmQuestions.values.flatMap { $0 } + groupQuestions).map { ($0.id, $0) })

// MARK: - Group chat scenes. Each line is (speaker slot, text); {me} = player name.

private let groupScenes: [[(Int, String)]] = [
    [(0, "Has anyone seen my other mitten? 🧤"), (1, "Is it the one on your head? 😂"), (0, "...oh.")],
    [(0, "Rudolph sneezed and the whole stable glowed red 🔴😂")],
    [(0, "Who put glitter in the cocoa machine?? ✨☕"), (1, "...it's festive?")],
    [(0, "I baked 200 cookies today 🍪"), (1, "How many are left?"), (0, "...three.")],
    [(0, "Snowball fight after work? ❄️"), (1, "I'm IN! ⛄")],
    [(0, "Santa laughed so hard the whole workshop shook 🎅😂")],
    [(0, "The toy trains are racing each other again 🚂🚂"), (1, "My money's on the red one!")],
    [(0, "Comet ate my sandwich 🥪🦌"), (1, "Reindeer gotta eat too!")],
    [(0, "I'm making a teddy bear with a tiny scarf! 🧸🧣"), (1, "That's the cutest thing EVER")],
    [(0, "Fun fact: every snowflake has six sides! ❄️"), (1, "Whoa, I didn't know that!")],
    [(0, "My hat keeps falling over my eyes 🎩"), (1, "Is that why you walked into the Christmas tree yesterday? 🎄😂")],
    [(0, "Who's ready for Christmas?? 🎄🎄🎄"), (1, "MEEEEE")],
    [(0, "I tried to wrap a present and wrapped myself instead 🎁😅")],
    [(0, "Dasher and Dancer are racing around the stable 🦌💨"), (1, "Who's winning?"), (0, "The carrot bucket 🥕")],
    [(0, "The robots learned to dance! 🤖🕺"), (1, "Is that safe??"), (0, "Probably!")],
    [(0, "Hot cocoa break, anyone? ☕"), (1, "With marshmallows please!")],
    [(0, "Good morning, Christmas Town! ☀️❄️")],
    [(0, "How do you fix a squeaky sleigh? 🛷"), (1, "A little oil. Or sing to it. 🎶")],
    [(0, "I found a candy cane in my pocket from LAST year 🍬"), (1, "...please don't eat it 😂")],
    [(0, "The northern lights look amazing tonight 🌌"), (1, "So pretty!!")],
    [(0, "Prancer just did a backflip!! 🦌"), (1, "Pics or it didn't happen 📸")],
    [(0, "I'm practicing Jingle Bells on the drum 🥁"), (1, "We can hear... 😅")],
    [(0, "Who wants to build a snow elf? ⛄🧝"), (1, "Me! I'll bring the carrot nose 🥕")],
    [(0, "Gingerbread house contest this weekend! 🏠🍪"), (1, "I'm making a CASTLE!")],
    [(0, "{me} has been working SO hard lately! 💪"), (1, "Go {me}!! 🎉")],
    [(0, "Shh, Santa's napping 😴🎅"), (1, "His snore sounds like 'ho ho ho' 😂")],
    [(0, "I named a snowflake Steve ❄️"), (1, "Where's Steve now?"), (0, "...he melted 😢")],
    [(0, "Who left the workshop door open? It's snowing INSIDE ❄️😂")],
    [(0, "Tip of the day: brush the reindeer AND feed them, or the job won't count! 🦌")],
    [(0, "Tip: eat a snack when your energy gets low! ⚡🍪")],
    [(0, "Did everyone finish Santa's jobs today? 📋"), (1, "Almost! Just the toys left 🧸")],
    [(0, "Knock knock 🚪"), (1, "Who's there?"), (0, "Snow."), (1, "Snow who?"), (0, "Snow time to waste, Christmas is coming! 🎄")],
    [(0, "My cookies came out shaped like reindeer by accident 🍪🦌"), (1, "That's not an accident, that's ART")],
    [(0, "I can't find the tape 😩🎁"), (1, "It's stuck to your elbow")],
]

let jokes = [
    "What do elves learn in school? The ELF-abet! 🔤😂",
    "Why was the snowman looking through the carrots? He was picking his nose! 🥕😂",
    "What do you call an elf who sings? A WRAPPER! 🎤🎁",
    "What's a snowman's favorite snack? Ice Krispies! ❄️😂",
    "How does a gingerbread man make his bed? With cookie sheets! 🍪🛏️",
    "Why are Christmas trees bad at knitting? They always drop their needles! 🎄😂",
    "What do reindeer hang on their trees? Horn-aments! 🦌✨",
    "What do you call Santa when he takes a break? Santa PAUSE! ⏸️🎅",
    "What do you get if you cross a bell and a skunk? Jingle SMELLS! 🔔😂",
    "Why did Rudolph get a bad report card? He went down in history! 📚🦌",
]

// MARK: - The elf brain (offline, scripted: elves can only say lines written here)

enum ElfBrain {
    /// Short words must match whole ("hi" but not "his"); longer ones can start a word ("decorat" -> "decorate").
    private static func has(_ t: String, _ words: String...) -> Bool {
        words.contains { w in
            let e = NSRegularExpression.escapedPattern(for: w)
            let pattern = w.count <= 4 ? "\\b\(e)s?\\b" : "\\b\(e)"
            return t.range(of: pattern, options: .regularExpression) != nil
        }
    }

    private static func flavor(_ elf: String) -> String {
        switch elf {
        case "Jingle": [" 🔧", " Awesome!", " 🧸", ""].randomElement()!
        case "Twinkle": [" ✨", " 💖✨", " 🎉", " OMG!"].randomElement()!
        case "Pepper": [" 🍪", " 💕", " sweetie!", ""].randomElement()!
        case "Sprout": [" 🌱", " 🦌", " 🥰", ""].randomElement()!
        case "Holly": [" 🔬", " Eureka!", " 🤖", ""].randomElement()!
        case "Frost": [" ❄️", " 😆", " ⛄", " Brrr!"].randomElement()!
        default: ""
        }
    }

    static func question(_ id: String?) -> Question? { id.flatMap { allQuestions[$0] } }

    private static func answer(_ q: Question, _ text: String) -> String {
        q.options.first { text.lowercased().contains($0.lowercased().prefix(5)) } ?? String(text.trimmingCharacters(in: .whitespaces).prefix(30))
    }

    /// What an elf says back in a private chat. May add a follow-up question.
    @MainActor static func reply(_ game: GameState, elf: String, text: String, answering: Question?) -> [ChatMsg] {
        let now = Date().timeIntervalSince1970
        let s = game.s
        let name = s.name
        let t = text.lowercased()

        if let q = answering {
            let ans = answer(q, text)
            if let key = q.memory { game.remember(key, ans) }
            return [ChatMsg(from: elf, text: q.react(ans), time: now)]
        }

        let carrots = s.crops[.carrot, default: 0]
        let hungry = game.reindeer.filter { !s.fed.contains($0) }
        let jobsLeft = s.jobs.filter { !$0.finished }
        let favCookie = s.memory["favCookie"], favReindeer = s.memory["favReindeer"]

        let main: String
        if has(t, "hi", "hello", "hey", "hiya", "howdy", "yo", "sup", "good morning", "morning") {
            switch elf {
            case "Jingle": main = "Hey hey, \(name)! 🔧 Ready to build some toys?"
            case "Twinkle": main = "HIIII \(name)!! ✨💖 I was JUST thinking about you!"
            case "Pepper": main = "Hello, sweetie! 🍪 " + (favCookie.map { "Still loving \($0) cookies?" } ?? "Want a warm cookie?")
            case "Holly": main = "Greetings, \(name)! 🔬 I just finished inventing... a better spoon."
            case "Frost": main = "Yo yo, \(name)! ❄️ Why are you so cool? Oh wait, that's me. 😎"
            default: main = "Oh! Hi \(name) 👋 " + (favReindeer.map { "\($0) says hi too! 🦌" } ?? "The reindeer say hi! 🦌")
            }
        } else if has(t, "how are you", "how r u", "hru", "how's it going", "hows it going", "how are u", "you ok", "u ok") {
            main = ["Jingle": "SUPER good! I just made a teddy bear with button eyes! 🧸 How are YOU?",
                    "Twinkle": "Amazing!!! I'm planning a surprise party ✨ (shh!) How are you?",
                    "Pepper": "Warm and toasty, thank you! 🍪 My oven smells like cinnamon. How are you, dear?",
                    "Holly": "Excellent! Only one small explosion today 💥 (it was glitter). How are you?",
                    "Frost": "Ice to see you! 🧊 Get it? I'm great! How are you?"][elf]
                ?? "Pretty good! Comet licked my face this morning 🦌😊 How are you?"
        } else if has(t, "sad", "upset", "cry", "crying", "lonely", "bad day", "mad", "angry", "scared", "worried", "tired") {
            main = "Aww, I'm sorry you feel that way. 💖 Want a virtual hug? 🤗 If something's really wrong, telling a grown-up you trust always helps. I'm here to chat too!"
        } else if has(t, "happy", "yay", "excited", "great", "good", "awesome", "fine", "amazing", "fantastic") {
            main = ["Yay! That makes me happy too! 😄", "Woohoo! 🎉 Happy elves make the best toys!", "That's the best news! ✨"].randomElement()!
        } else if has(t, "joke", "jokes", "funny", "laugh", "make me laugh") {
            main = jokes.randomElement()!
        } else if has(t, "are you real", "are you a robot", "are you ai", "are you a bot", "are you human", "is this real") {
            main = "I'm \(elf), an elf in Christmas Town! 🧝 I'm a character in this game, so I live inside your phone. But our friendship is real fun! 💖"
        } else if has(t, "your name", "who are you", "what's your name", "whats your name") {
            main = "I'm \(elf)! " + (["Jingle": "Toy maker extraordinaire 🔧🧸", "Twinkle": "Party planner and glitter expert ✨🎉", "Pepper": "Head baker of Christmas Town 🍪", "Holly": "Inventor of mostly-working gadgets 🔬", "Frost": "Snow sculptor and joke champion ❄️😆"][elf] ?? "I look after Santa's reindeer 🦌")
        } else if has(t, "what do you do", "your job", "what's your job", "whats your job") {
            main = ["Jingle": "I make toys! Trains, robots, teddy bears... ALL the toys! 🔧", "Twinkle": "I plan the BEST parties in the North Pole ✨🎉", "Pepper": "I bake cookies for Santa and everyone! 🍪", "Holly": "I invent things! Toy machines, snow cannons, self-stirring bowls... 🔬", "Frost": "I make snow sculptures and tell the BEST jokes ⛄😆"][elf]
                ?? "I feed and brush the reindeer. They're my best friends 🦌🥕"
        } else if has(t, "money", "paid", "pay", "rich", "coins", "dollars") {
            main = s.paidToday ? "You already got your \(money(dailyPay)) today! 💰 Spend it on something fun in the Shop!" : "Santa pays \(money(dailyPay)) when you finish ALL your jobs. You have \(jobsLeft.count) left today! 📋"
        } else if has(t, "help", "what should i do", "what do i do", "stuck", "how do i", "confused", "what now") {
            main = jobsLeft.first.map { "Next up: \($0.text)! \($0.kind.emoji) Tap the icons on the main screen to get there." } ?? "You're all done for today! 🎉 Go to sleep 💤 to start a new day, or decorate your house!"
        } else if has(t, "reindeer", "rudolph", "dasher", "comet", "carrot", "feed", "brush", "stable") {
            main = hungry.isEmpty ? "All the reindeer are fed and happy! 🦌💖" : carrots == 0 ? "\(hungry[0]) is hungry but you're out of carrots! Grow some in the Greenhouse 🥕🌱" : "\(hungry[0]) is still hungry! You have \(carrots) carrots 🥕 Go to the Stable!"
        } else if has(t, "cookie", "bake", "baking", "oven", "biscuit") {
            main = "Cookies need wheat from the Greenhouse! 🌾 " + (game.level < 2 ? "Berry cookies unlock at Level 2!" : game.level < 3 ? "Choc chip unlocks at Level 3!" : "You can bake ALL the cookies now! 🍪")
        } else if has(t, "toy", "teddy", "train", "doll", "robot", "drum", "workshop", "candy cane") {
            main = "You've made \(s.toys.values.reduce(0, +)) toys ready to give! 🧸 " + (Toy.allCases.first { $0.unlockLevel > game.level }.map { "\($0.title)s unlock at Level \($0.unlockLevel)!" } ?? "")
        } else if has(t, "santa", "naughty", "nice", "list") {
            main = game.level < 2 ? "Santa's list unlocks at Level 2! Keep working hard 📜" : "Santa LOVES when you help with his list. Read carefully: naughty or nice? 😇😈"
        } else if has(t, "plant", "seed", "grow", "garden", "greenhouse", "wheat", "water") {
            main = "Plant seeds, water them 💧, wait a bit, then pick them! 🌱 Seeds are in the Shop if you run out."
        } else if has(t, "party", "decorat", "celebrate") {
            main = elf == "Twinkle" ? "PARTY?! Did someone say PARTY?! 🎉✨ Plan one with me in Friends when we're good friends!" : "Twinkle throws the BEST parties. Ask her! 🎉"
        } else if has(t, "shop", "buy", "clothes", "hat", "dress", "crown") {
            main = "The Shop has clothes, hats, furniture and food! 🛍️ The Crown is SO fancy 👑"
        } else if has(t, "christmas", "present", "gift", "snow", "winter", "xmas") {
            main = ["Christmas is the BEST time of year! 🎄", "Did you know it's always snowing in Christmas Town? ❄️", "I already wrapped my presents! 🎁 Well, most of them."].randomElement()!
        } else if has(t, "favorite", "favourite", "like best", "love most") {
            main = ["Jingle": "My favorite thing? Robots! 🤖 They beep!", "Twinkle": "Glitter. Obviously. ✨✨✨", "Pepper": "Warm cookies straight from the oven 🍪 nothing better!", "Holly": "Gears! Springs! Anything that goes BOING! 🔩", "Frost": "Snow days. And puns. Snow-puns are the best. ❄️"][elf] ?? "Reindeer. All of them. Even the grumpy ones 🦌💕"
        } else if has(t, "love you", "you're cool", "youre cool", "you are cool", "you're nice", "you're awesome", "you're funny", "best friend", "like you") {
            main = ["Aww, you're the BEST! 💖", "You just made my whole day! 🥰", "Best friends forever! 🤝✨"].randomElement()!
        } else if has(t, "thank", "thx", "ty", "thanks") {
            main = ["You're welcome! 😊", "Anytime, friend! 💖", "No problem!"].randomElement()!
        } else if has(t, "bye", "goodnight", "good night", "see you", "see ya", "gtg", "got to go", "later") {
            main = ["Bye \(name)! 👋 Come back soon!", "See you later! ❄️", "Night night! Dream of sugarplums 🌙"].randomElement()!
        } else if has(t, "yes", "yeah", "yep", "sure", "ok", "okay") {
            main = ["Yay! 😄", "Awesome! 🎉", "Great!"].randomElement()!
        } else if has(t, "no", "nope", "nah") {
            main = ["Oh okay! No worries 😊", "That's okay!", "Hmm, fair enough!"].randomElement()!
        } else if t.trimmingCharacters(in: .whitespaces).hasSuffix("?") {
            main = ["Hmm, good question! 🤔 I'm not sure, but I think the answer is... more cookies! 🍪", "Ooh, I don't know! What do YOU think?", "Hmm! Let me ask Santa and get back to you 🎅"].randomElement()!
        } else {
            main = ["Hmm, I'm just an elf so I didn't quite get that 😅 Want to talk about cookies, toys or reindeer?", "Ooh interesting! Tell me more! 😄", "Haha, you're funny! 😂", "Really? Wow! 😮"].randomElement()!
        }

        var out = [ChatMsg(from: elf, text: main + flavor(elf), time: now)]
        if Double.random(in: 0...1) < 0.35, let q = dmQuestions[elf]?.filter({ $0.memory == nil || s.memory[$0.memory!] == nil }).randomElement() {
            out.append(ChatMsg(from: elf, text: q.ask, time: now + 0.001, options: q.options, qid: q.id))
        }
        return out
    }

    /// 1–3 new group messages spread out between `since` and `now`, as if the chat kept going without you.
    @MainActor static func groupEvents(_ game: GameState, met: [String], since: Double, now: Double, count: Int) -> [ChatMsg] {
        guard !met.isEmpty else { return [] }
        var out: [ChatMsg] = []
        let span = max(now - since, 60)
        for i in 0..<count {
            let time = since + span * Double(i + 1) / Double(count + 1)
            if Double.random(in: 0...1) < 0.3, let q = groupQuestions.randomElement() {
                out.append(ChatMsg(from: met.randomElement()!, text: q.ask.replacingOccurrences(of: "{me}", with: game.s.name), time: time, options: q.options, qid: q.id))
            } else {
                var cast = met.shuffled()
                if cast.count == 1 { cast.append(cast[0]) }
                let usable = groupScenes.filter { scene in met.count > 1 || scene.allSatisfy { $0.0 == 0 } }
                for (j, line) in usable.randomElement()!.enumerated() {
                    out.append(ChatMsg(from: cast[line.0], text: line.1.replacingOccurrences(of: "{me}", with: game.s.name), time: time + Double(j) * 20))
                }
            }
        }
        return out
    }

    /// How the group reacts when you answer a question or post something.
    @MainActor static func groupReply(_ game: GameState, met: [String], text: String, answering: Question?, askedBy: String?) -> [ChatMsg] {
        let now = Date().timeIntervalSince1970
        guard !met.isEmpty else { return [] }
        if let q = answering {
            let ans = answer(q, text)
            if let key = q.memory { game.remember(key, ans) }
            let first = askedBy ?? met.randomElement()!
            var out = [ChatMsg(from: first, text: q.react(ans), time: now)]
            if let other = met.filter({ $0 != first }).randomElement(), Double.random(in: 0...1) < 0.6 {
                out.append(ChatMsg(from: other, text: ["Agreed!! 🙌", "Hmm I'd pick something else 😜", "Ooh good one, \(game.s.name)!", "Same!! 😄"].randomElement()!, time: now + 0.001))
            }
            return out
        }
        return Array(reply(game, elf: met.randomElement()!, text: text, answering: nil).prefix(1))
    }
}

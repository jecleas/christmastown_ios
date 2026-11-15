import SwiftUI

// Same game content as the Android version (christmas_town/…/Data.kt). Keep them in sync.

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB, red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255, opacity: opacity)
    }
}

enum Pal {
    static let ink = Color(hex: 0x2B1D2E)
    static let red = Color(hex: 0xE5394B)
    static let darkRed = Color(hex: 0xA02338)
    static let green = Color(hex: 0x3FAF5A)
    static let darkGreen = Color(hex: 0x2E7D4A)
    static let gold = Color(hex: 0xFFCC4D)
    static let night = Color(hex: 0x1D2B53)
    static let blue = Color(hex: 0x3D6FD6)
    static let purple = Color(hex: 0x9B6BE0)
    static let pink = Color(hex: 0xFF8FB0)
    static let brown = Color(hex: 0x9A5B34)
    static let cream = Color(hex: 0xFFF6E6)
    static let orange = Color(hex: 0xE0843A)
    static let grey = Color(hex: 0x8D96A8)
    static let paleGold = Color(hex: 0xFFF1B8)
    static let paleGreen = Color(hex: 0xD8F5DD)
}

// MARK: - Your elf

enum HairStyle: String, Codable, CaseIterable {
    case short, long, pigtails, bun, bob
    var title: String { rawValue.capitalized }
    var price: Int { self == .short || self == .long ? 0 : 300 }
    var sprite: String { "hair_\(rawValue)" }
}

enum Outfit: String, Codable, CaseIterable {
    case tunic, sweater, dress, overalls, pajamas, snowsuit
    var title: String { ["tunic": "Elf Tunic", "sweater": "Christmas Sweater", "dress": "Party Dress", "overalls": "Overalls", "pajamas": "Polka Pajamas", "snowsuit": "Snowsuit"][rawValue]! }
    var price: Int { ["tunic": 0, "sweater": 500, "dress": 400, "overalls": 450, "pajamas": 350, "snowsuit": 550][rawValue]! }
    var sprite: String? { self == .tunic ? nil : "outfit_\(rawValue)" }
}

enum Hat: String, Codable, CaseIterable {
    case none, elf, beanie, santa, antlers, crown, earmuffs, topHat
    var title: String { ["none": "No Hat", "elf": "Elf Hat", "beanie": "Beanie", "santa": "Santa Hat", "antlers": "Antlers", "crown": "Crown", "earmuffs": "Earmuffs", "topHat": "Top Hat"][rawValue]! }
    var price: Int { ["none": 0, "elf": 0, "beanie": 300, "santa": 600, "antlers": 500, "crown": 1500, "earmuffs": 350, "topHat": 700][rawValue]! }
    var sprite: String? { self == .none ? nil : self == .topHat ? "hat_tophat" : "hat_\(rawValue)" }
}

enum Accessory: String, Codable, CaseIterable {
    case none, scarf, bell
    var title: String { ["none": "Nothing", "scarf": "Scarf", "bell": "Jingle Bell"][rawValue]! }
    var price: Int { ["none": 0, "scarf": 250, "bell": 200][rawValue]! }
    var sprite: String? { self == .none ? nil : "acc_\(rawValue)" }
}

enum ElfColors {
    static let skins: [UInt32] = [0xFFE0C8, 0xF5C29A, 0xD69A6E, 0x9C6648]
    static let hairs: [UInt32] = [0x6B4130, 0x2E2A35, 0xF2C65B, 0xE0743C, 0xFF8FB8, 0xB79CFF, 0xF4F4F4]
    static let eyes: [UInt32] = [0x6B4A3A, 0x3D6FD6, 0x2E9E5B, 0x7E57C2]
    static let clothes: [UInt32] = [0x3FAF5A, 0xE5394B, 0x3D6FD6, 0x9B6BE0, 0xFF8FB8, 0xF2B632, 0x2EB5A5, 0xF0F0F0]
}

struct ElfLook: Codable, Hashable {
    var girl = true
    var skin = 0
    var hairStyle: HairStyle = .long
    var hairColor = 0
    var eye = 0
    var outfit: Outfit = .tunic
    var outfitColor = 0
    var hat: Hat = .elf
    var hatColor = 1
    var accessory: Accessory = .none
}

// MARK: - Greenhouse, bakery, workshop, food

enum Crop: String, Codable, CaseIterable {
    case wheat, carrot, berry, cocoa, ginger, peppermint
    var title: String { rawValue.capitalized }
    var plural: String { ["wheat": "wheat", "carrot": "carrots", "berry": "berries", "cocoa": "cocoa pods", "ginger": "ginger roots", "peppermint": "peppermint leaves"][rawValue]! }
    var seedPrice: Int { ["wheat": 20, "carrot": 20, "berry": 40, "cocoa": 60, "ginger": 70, "peppermint": 80][rawValue]! }
    var growSeconds: Double { ["wheat": 10, "carrot": 10, "berry": 14, "cocoa": 18, "ginger": 20, "peppermint": 22][rawValue]! }
    var unlockLevel: Int { ["wheat": 1, "carrot": 1, "berry": 2, "cocoa": 3, "ginger": 6, "peppermint": 7][rawValue]! }
    var sprite: String { rawValue }
}

let harvest = 3

enum Cookie: String, Codable, CaseIterable {
    case sugar, berryJam, choco, gingerbread, candyCane, reindeer
    var title: String { ["sugar": "Sugar Cookie", "berryJam": "Berry Cookie", "choco": "Choc Chip Cookie", "gingerbread": "Gingerbread Person", "candyCane": "Candy Cane Cookie", "reindeer": "Reindeer Cookie"][rawValue]! }
    var recipe: [(Crop, Int)] {
        switch self {
        case .sugar: [(.wheat, 2)]
        case .berryJam: [(.wheat, 2), (.berry, 1)]
        case .choco: [(.wheat, 2), (.cocoa, 1)]
        case .gingerbread: [(.wheat, 2), (.ginger, 1)]
        case .candyCane: [(.wheat, 2), (.peppermint, 1)]
        case .reindeer: [(.wheat, 2), (.cocoa, 1), (.berry, 1)]
        }
    }
    var unlockLevel: Int { ["sugar": 1, "berryJam": 2, "choco": 3, "gingerbread": 6, "candyCane": 7, "reindeer": 8][rawValue]! }
    var energy: Int { ["sugar": 15, "berryJam": 20, "choco": 25, "gingerbread": 30, "candyCane": 30, "reindeer": 40][rawValue]! }
    var sprite: String { ["sugar": "cookie_sugar", "berryJam": "cookie_berry", "choco": "cookie_choco", "gingerbread": "cookie_ginger", "candyCane": "cookie_candycane", "reindeer": "cookie_reindeer"][rawValue]! }
}

enum Toy: String, Codable, CaseIterable {
    case teddy, candyCane, train, doll, drum, robot, rockingHorse, yoYo, snowGlobe
    var title: String { ["teddy": "Teddy Bear", "candyCane": "Candy Cane", "train": "Toy Train", "doll": "Doll", "drum": "Drum", "robot": "Robot", "rockingHorse": "Rocking Horse", "yoYo": "Yo-Yo", "snowGlobe": "Snow Globe"][rawValue]! }
    var unlockLevel: Int { ["teddy": 1, "candyCane": 1, "train": 2, "doll": 3, "drum": 4, "robot": 5, "rockingHorse": 6, "yoYo": 7, "snowGlobe": 8][rawValue]! }
    var sprite: String { ["candyCane": "candycane", "rockingHorse": "rockinghorse", "yoYo": "yoyo", "snowGlobe": "snowglobe"][rawValue] ?? rawValue }
    var steps: [String] {
        switch self {
        case .teddy: ["Stuff it with cotton", "Sew it up", "Pick a fur color"]
        case .candyCane: ["Pull the sugar", "Pick a stripe color", "Bend the hook"]
        case .train: ["Build the engine", "Screw on the wheels", "Paint it"]
        case .doll: ["Sew the face", "Brush the hair", "Pick a dress"]
        case .drum: ["Stretch the top", "Paint the drum", "Add the sticks"]
        case .robot: ["Bolt the body", "Charge the battery", "Pick a paint"]
        case .rockingHorse: ["Carve the rockers", "Brush the mane", "Paint the saddle"]
        case .yoYo: ["Wind the string", "Glue the halves", "Pick a color"]
        case .snowGlobe: ["Shake in the snow", "Seal the glass", "Paint the base"]
        }
    }
}

enum Food: String, Codable, CaseIterable {
    case candy, hotCocoa, pie
    var title: String { ["candy": "Candy", "hotCocoa": "Hot Cocoa", "pie": "Apple Pie"][rawValue]! }
    var price: Int { ["candy": 30, "hotCocoa": 50, "pie": 90][rawValue]! }
    var energy: Int { ["candy": 15, "hotCocoa": 40, "pie": 60][rawValue]! }
    var sprite: String { ["candy": "candy", "hotCocoa": "cocoa_mug", "pie": "pie"][rawValue]! }
}

// MARK: - House stuff

enum Spot { case floor, wall, rug }
enum ItemKind { case furniture, decoration }

enum Item: String, Codable, CaseIterable {
    case tree, fireplace, couch, armchair, bed, table, lamp, bookshelf, rug, clock, picture
    case stocking, wreath, garland, snowman, presents, poinsettia, gingerbreadHouse, candles
    case rockingChair, toyChest, nutcracker, sled

    var title: String {
        ["tree": "Christmas Tree", "fireplace": "Fireplace", "couch": "Couch", "armchair": "Armchair", "bed": "Bed", "table": "Table",
         "lamp": "Lamp", "bookshelf": "Bookshelf", "rug": "Rug", "clock": "Clock", "picture": "Picture", "stocking": "Stocking",
         "wreath": "Wreath", "garland": "Twinkle Lights", "snowman": "Snowman", "presents": "Presents", "poinsettia": "Poinsettia",
         "gingerbreadHouse": "Gingerbread House", "candles": "Candles", "rockingChair": "Rocking Chair", "toyChest": "Toy Chest", "nutcracker": "Nutcracker", "sled": "Sled"][rawValue]!
    }
    var price: Int {
        ["tree": 800, "fireplace": 900, "couch": 600, "armchair": 400, "bed": 700, "table": 300, "lamp": 200, "bookshelf": 500, "rug": 250,
         "clock": 200, "picture": 150, "stocking": 100, "wreath": 150, "garland": 200, "snowman": 350, "presents": 300, "poinsettia": 150,
         "gingerbreadHouse": 250, "candles": 120, "rockingChair": 450, "toyChest": 500, "nutcracker": 300, "sled": 350][rawValue]!
    }
    var sprite: String { ["gingerbreadHouse": "ginghouse", "rockingChair": "rockchair", "toyChest": "toychest"][rawValue] ?? rawValue }
    var spot: Spot { [.clock, .picture, .stocking, .wreath, .garland].contains(self) ? .wall : self == .rug ? .rug : .floor }
    var kind: ItemKind { [.tree, .stocking, .wreath, .garland, .snowman, .presents, .poinsettia, .gingerbreadHouse, .candles, .nutcracker, .sled].contains(self) ? .decoration : .furniture }
}

/// One thing placed in the house. x/y are fractions of the room (0…1). Floor 0 = downstairs.
struct Placed: Codable, Hashable {
    var id: Int
    var item: Item
    var floor: Int
    var x: Double
    var y: Double = 0.3
}

let startingHouse: [Placed] = [
    Placed(id: 1, item: .rug, floor: 0, x: 0.45), Placed(id: 2, item: .fireplace, floor: 0, x: 0.42), Placed(id: 3, item: .tree, floor: 0, x: 0.12),
    Placed(id: 4, item: .couch, floor: 0, x: 0.75), Placed(id: 5, item: .wreath, floor: 0, x: 0.42, y: 0.08), Placed(id: 6, item: .stocking, floor: 0, x: 0.3, y: 0.45),
    Placed(id: 7, item: .lamp, floor: 0, x: 0.94),
    Placed(id: 8, item: .bed, floor: 1, x: 0.22), Placed(id: 9, item: .table, floor: 1, x: 0.62), Placed(id: 10, item: .clock, floor: 1, x: 0.6, y: 0.15),
    Placed(id: 11, item: .picture, floor: 1, x: 0.22, y: 0.12), Placed(id: 12, item: .bookshelf, floor: 1, x: 0.88),
]

// MARK: - Reindeer, levels, jobs

let reindeerNames = ["Dasher", "Dancer", "Prancer", "Vixen", "Comet", "Cupid", "Donner", "Blitzen", "Rudolph"]
/// Rudolph (the last name) only joins at the top level.
func reindeerCount(_ level: Int) -> Int { [2, 3, 4, 5, 6, 7, 8, 9][max(0, min(maxLevel - 1, level - 1))] }

/// Things you can put on a reindeer in its care screen. They show everywhere the reindeer does.
enum Deco: String, Codable, CaseIterable, Comparable {
    case bells, scarf, lights, blanket
    var title: String { ["bells": "Jingle Bells", "scarf": "Cozy Scarf", "lights": "Antler Lights", "blanket": "Saddle Blanket"][rawValue]! }
    var emoji: String { ["bells": "🔔", "scarf": "🧣", "lights": "💡", "blanket": "🟥"][rawValue]! }
    var price: Int { ["bells": 150, "scarf": 200, "lights": 250, "blanket": 300][rawValue]! }
    var sprite: String { "rd_\(rawValue)" }
    static func < (a: Deco, b: Deco) -> Bool { allCases.firstIndex(of: a)! < allCases.firstIndex(of: b)! }
}

/// Reindeer you've fully cared for and harnessed pull the sleigh better.
let teamSize = 4

let levelTitles = ["Helper Elf", "Cookie Elf", "Toy Elf", "Sleigh Elf", "Workshop Star", "Gift Wrapper", "Tree Trimmer", "Santa's Best Elf"]
let maxLevel = 8
let dailyPay = 1000
let christmasEveWorkdays = 10

/// Rudolph joins two days before Christmas Eve (10 workdays).
func levelFor(_ workdays: Int) -> Int {
    workdays >= 8 ? 8 : workdays >= 7 ? 7 : workdays >= 6 ? 6 : workdays >= 5 ? 5 : workdays >= 3 ? 4 : workdays >= 2 ? 3 : workdays >= 1 ? 2 : 1
}

enum JobKind: String, Codable {
    case bake, toys, reindeer, sortList, deliver, wrap, tree
    var emoji: String { ["bake": "🍪", "toys": "🧸", "reindeer": "🦌", "sortList": "📜", "deliver": "🛷", "wrap": "🎁", "tree": "🎄"][rawValue]! }
}

struct Job: Codable, Hashable {
    var kind: JobKind
    var goal: Int
    var done = 0
    var finished: Bool { done >= goal }
    var text: String {
        switch kind {
        case .bake: "Bake \(goal) cookies"
        case .toys: "Make \(goal) toys"
        case .reindeer: "Feed & brush every reindeer"
        case .sortList: "Sort \(goal) kids on Santa's list"
        case .deliver: "Deliver \(goal) presents"
        case .wrap: "Wrap \(goal) presents"
        case .tree: "Decorate the Town Tree"
        }
    }
}

func jobsFor(_ level: Int) -> [Job] {
    let i = max(1, min(maxLevel, level)) - 1
    var jobs = [Job(kind: .bake, goal: [2, 3, 3, 4, 4, 4, 5, 5][i]), Job(kind: .toys, goal: [2, 3, 4, 4, 5, 5, 5, 6][i]), Job(kind: .reindeer, goal: 1)]
    if level >= 2 { jobs.append(Job(kind: .sortList, goal: [0, 5, 5, 5, 5, 5, 6, 6][i])) }
    if level >= 3 { jobs.append(Job(kind: .deliver, goal: [0, 0, 4, 4, 5, 6, 6, 7][i])) }
    if level >= 6 { jobs.append(Job(kind: .wrap, goal: [0, 0, 0, 0, 0, 2, 2, 3][i])) }
    if level >= 7 { jobs.append(Job(kind: .tree, goal: 1)) }
    return jobs
}

/// How tricky the sleigh flight is: faster, more clouds, naughty houses, and a dark foggy night at the top.
struct Flight { let speed: CGFloat; let cloudEvery: CGFloat; let naughtyChance: Double; let foggy: Bool }

func flightFor(_ level: Int, christmasEve: Bool) -> Flight {
    if christmasEve { return Flight(speed: 95, cloudEvery: 260, naughtyChance: 0.2, foggy: true) }
    return Flight(speed: 70 + 5 * CGFloat(max(0, level - 3)),
                  cloudEvery: [520, 520, 520, 460, 400, 340, 300, 260][max(0, min(7, level - 1))],
                  naughtyChance: level >= 5 ? 0.25 : 0.15, foggy: level >= 8)
}

// MARK: - Pets (bought with in-game money only)

enum PetKind: String, Codable, CaseIterable {
    case penguin, puppy, kitten, bunny, owl, fox
    var title: String { ["penguin": "Penguin", "puppy": "Puppy", "kitten": "Kitten", "bunny": "Bunny", "owl": "Snowy Owl", "fox": "Arctic Fox"][rawValue]! }
    var price: Int { ["penguin": 600, "puppy": 700, "kitten": 700, "bunny": 650, "owl": 900, "fox": 1000][rawValue]! }
    var sprite: String { "pet_\(rawValue)" }
    var noise: String { ["penguin": "Squawk!", "puppy": "Woof!", "kitten": "Mew!", "bunny": "*thump thump*", "owl": "Hoo hoo!", "fox": "Yip yip!"][rawValue]! }
    var food: String { ["penguin": "🐟", "puppy": "🦴", "kitten": "🐟", "bunny": "🥕", "owl": "🐭", "fox": "🍗"][rawValue]! }
    var jokes: [String] {
        switch self {
        case .penguin: ["*waddles in a circle*", "*slides on its tummy* Wheee!", "*bows politely*", "I'm wearing a tuxedo because I'm FANCY."]
        case .puppy: ["*chases own tail*", "*steals a sock* 🧦", "Is it walkies time?!", "*rolls over for tummy rubs*"]
        case .kitten: ["*knocks an ornament off the tree*", "*naps in a box* 📦", "*bats at the tinsel*", "Purrrrr..."]
        case .bunny: ["*binky jump!*", "*wiggles nose*", "*hides in a stocking*", "Carrot? CARROT?!"]
        case .owl: ["*turns head ALL the way around*", "Hoo is the best elf? YOU!", "*fluffs feathers*", "*winks slowly*"]
        case .fox: ["*pounces into a snow pile*", "*curls up with tail as a blanket*", "*does a happy zoomie*", "Yip! I hid your cookie. Somewhere."]
        }
    }
}

/// One pet you own. Meters are worked out from when you last fed, washed and played with it (seconds since 1970).
struct Pet: Codable, Hashable, Identifiable {
    var id: Int
    var kind: PetKind
    var name: String
    var fedAt: Double = 0
    var washedAt: Double = 0
    var pettedAt: Double = 0
    var giftDay = 0

    func fullness(_ now: Double) -> Double { meter(fedAt, now, hours: 8) }
    func cleanness(_ now: Double) -> Double { meter(washedAt, now, hours: 24) }
    func happiness(_ now: Double) -> Double { meter(pettedAt, now, hours: 6) * 0.5 + fullness(now) * 0.25 + cleanness(now) * 0.25 }
}

/// 0…1 meters that go down slowly over real time (full → empty in `hours`).
func meter(_ at: Double, _ now: Double, hours: Double) -> Double { at == 0 ? 0.3 : min(1, max(0, 1 - (now - at) / (hours * 3600))) }

let petNames = ["Pip", "Biscuit", "Snowball", "Mochi", "Waffles", "Noodle", "Pickle", "Sprinkles", "Muffin", "Ziggy", "Bean", "Tinsel"]

func money(_ n: Int) -> String {
    let f = NumberFormatter(); f.numberStyle = .decimal
    return "$" + (f.string(from: NSNumber(value: n)) ?? "\(n)")
}

// MARK: - Santa's list

struct Kid: Codable, Hashable { var name: String; var deed: String; var nice: Bool }

private let kidNames = ["Mia", "Leo", "Ava", "Noah", "Zoe", "Max", "Lily", "Sam", "Ella", "Ben", "Ruby", "Jack", "Chloe", "Oscar", "Ivy", "Theo", "Grace", "Finn", "Lucy", "Kai"]
private let niceDeeds = [
    "Shared toys with their little brother", "Helped grandma carry the groceries", "Fed the neighbor's cat",
    "Cleaned up their room without being asked", "Said thank you to the bus driver", "Made a card for a sick friend",
    "Helped plant flowers at school", "Gave half their cookie to a friend", "Walked the dog every single day", "Helped a new kid make friends",
]
private let naughtyDeeds = [
    "Put a frog in the teacher's desk", "Ate all the cookies and blamed the dog", "Drew on the walls with crayons",
    "Pulled their sister's pigtails", "Never brushed their teeth", "Hid dad's car keys in the fish tank",
    "Threw snowballs at the mail carrier", "Said NO to bedtime 47 times", "Put salt in the sugar bowl", "Fed their broccoli to the dog under the table",
]

func makeKids(_ n: Int) -> [Kid] {
    let names = kidNames.shuffled()
    return (0..<n).map { i in
        let nice = Double.random(in: 0...1) < 0.55
        return Kid(name: names[i], deed: (nice ? niceDeeds : naughtyDeeds).randomElement()!, nice: nice)
    }
}

// MARK: - Elf friends

struct Npc: Identifiable, Hashable {
    let name: String
    let look: ElfLook
    let job: String
    let lines: [String]
    let bestFriendGift: Item
    var id: String { name }
}

let npcs: [Npc] = [
    Npc(name: "Jingle", look: ElfLook(girl: false, skin: 1, hairStyle: .short, hairColor: 3, eye: 2, outfit: .overalls, outfitColor: 0, hat: .beanie, hatColor: 1), job: "Toy Maker", lines: [
        "Santa pays $1,000 every day you finish ALL your jobs!",
        "Making toys and baking use energy. Eat something if you're tired!",
        "Tap the 📋 Jobs button to see what Santa needs today.",
        "New toys unlock when you level up. I can't wait to make robots!",
        "If you skip work, you don't get paid. Santa's strict about that!",
    ], bestFriendGift: .garland),
    Npc(name: "Twinkle", look: ElfLook(girl: true, skin: 0, hairStyle: .pigtails, hairColor: 4, eye: 3, outfit: .dress, outfitColor: 4, hat: .elf, hatColor: 3), job: "Party Planner", lines: [
        "I LOVE parties! Be my friend and I'll invite you to one!",
        "You can drag your furniture around. Tap Decorate!",
        "The Shop has the cutest decorations. Twinkle lights are my favorite.",
        "Your house can have two floors of Christmas cheer!",
    ], bestFriendGift: .presents),
    Npc(name: "Pepper", look: ElfLook(girl: true, skin: 2, hairStyle: .bun, hairColor: 1, eye: 0, outfit: .sweater, outfitColor: 1, hat: .none, hatColor: 0, accessory: .scarf), job: "Head Baker", lines: [
        "Cookies need wheat. Grow it in the Greenhouse!",
        "Berry cookies unlock at Level 2, and choc chip at Level 3. Yum!",
        "Elves LOVE cookies. Try giving one to a friend.",
        "Hot cocoa from the Shop gives you lots of energy.",
    ], bestFriendGift: .gingerbreadHouse),
    Npc(name: "Sprout", look: ElfLook(girl: false, skin: 3, hairStyle: .bob, hairColor: 2, eye: 1, outfit: .tunic, outfitColor: 6, hat: .antlers, hatColor: 0, accessory: .bell), job: "Reindeer Keeper", lines: [
        "Reindeer love carrots! Grow them in the Greenhouse.",
        "Feed AND brush every reindeer to finish the reindeer job.",
        "Rudolph joins the stable at Level 8. His nose glows!",
        "Seeds need water before they grow. 💧",
    ], bestFriendGift: .poinsettia),
    Npc(name: "Holly", look: ElfLook(girl: true, skin: 1, hairStyle: .bob, hairColor: 3, eye: 2, outfit: .overalls, outfitColor: 2, hat: .topHat, hatColor: 0), job: "Inventor", lines: [
        "EUREKA! I invented a cookie that eats itself. Wait, that's bad.",
        "Wrapped presents go on the sleigh first. I measured it! 📏",
        "Happy reindeer steer better. That's SCIENCE. 🔬",
        "My next invention: a snowball that comes back like a yo-yo!",
        "Pets get hungry over time, so check on them every day! 🐾",
    ], bestFriendGift: .toyChest),
    Npc(name: "Frost", look: ElfLook(girl: false, skin: 0, hairStyle: .short, hairColor: 6, eye: 1, outfit: .snowsuit, outfitColor: 6, hat: .earmuffs, hatColor: 2), job: "Snow Sculptor", lines: [
        "What do snowmen eat for breakfast? Frosted flakes! ❄️😂",
        "I built a snowman of Santa. He said it looked 'a bit chilly'.",
        "Snowball fight in the Snow Park? I'm SO in. Bring it! ⛄",
        "Why did the reindeer cross the road? To get to the other SLEIGH! 🦌",
        "The Town Tree needs ornaments, tinsel AND a star. Don't forget the star!",
    ], bestFriendGift: .sled),
]

func npc(_ name: String) -> Npc? { npcs.first { $0.name == name } }

let partyThemes: [(String, Item)] = [("Candy Land 🍭", .gingerbreadHouse), ("Winter Wonderland ⛄", .snowman), ("Cozy Cabin 🕯️", .candles)]

// MARK: - The icons on the main screen

enum Side { case left, right, hidden }   // hidden places open from the buttons at the bottom of the main screen

enum Place: String, CaseIterable, Identifiable {
    case greenhouse, bakery, stable, workshop, santaList, sleigh, park, decorate, shop, closet, friends, phone, snacks, pets, advent, stickers
    var id: String { rawValue }
    var title: String {
        ["greenhouse": "Greenhouse", "bakery": "Bakery", "stable": "Stable", "workshop": "Workshop", "santaList": "Santa's List", "sleigh": "Sleigh", "park": "Snow Park", "pets": "Pets", "advent": "Advent Calendar", "stickers": "Sticker Book",
         "decorate": "Decorate", "shop": "Shop", "closet": "Closet", "friends": "Friends", "phone": "Phone", "snacks": "Snacks"][rawValue]!
    }
    var sprite: String {
        ["greenhouse": "wheat", "bakery": "cookie_sugar", "stable": "reindeer", "workshop": "teddy", "santaList": "santa", "sleigh": "sleigh", "park": "snowman", "pets": "pet_penguin", "advent": "gift", "stickers": "teddy",
         "decorate": "tree", "shop": "presents", "closet": "", "friends": "", "phone": "phone", "snacks": "cocoa_mug"][rawValue]!
    }
    var side: Side { [.advent, .stickers].contains(self) ? .hidden : [.greenhouse, .bakery, .stable, .workshop, .santaList, .sleigh, .park].contains(self) ? .left : .right }
    var color: Color {
        switch self {
        case .greenhouse: Color(hex: 0x3FAF5A)
        case .bakery: Color(hex: 0xE0843A)
        case .stable: Color(hex: 0x9A5B34)
        case .workshop: Color(hex: 0xE5394B)
        case .santaList: Color(hex: 0xA02338)
        case .sleigh, .phone: Color(hex: 0x3D6FD6)
        case .decorate: Color(hex: 0x2E7D4A)
        case .shop: Color(hex: 0x9B6BE0)
        case .closet: Color(hex: 0xFF8FB0)
        case .friends: Color(hex: 0x2EB5A5)
        case .snacks: Color(hex: 0xC98B5E)
        case .park: Color(hex: 0x5BA4D9)
        case .pets: Color(hex: 0xF2A93B)
        case .advent: Color(hex: 0xA02338)
        case .stickers: Color(hex: 0x9B6BE0)
        }
    }
    var dark: Bool { [.decorate, .snacks, .phone, .stable, .santaList, .sleigh, .friends, .closet, .park, .advent, .stickers].contains(self) }
}

// MARK: - Advent calendar (1–24 December, real dates)

/// A surprise behind an advent door. `give` adds it to your save.
struct Surprise {
    let title: String
    let sprite: String
    let give: (inout Save) -> Void
}

private func itemGift(_ i: Item) -> Surprise { Surprise(title: i.title, sprite: i.sprite) { $0.owned[i, default: 0] += 1 } }
private func foodGift(_ f: Food, _ n: Int = 1) -> Surprise { Surprise(title: n > 1 ? "\(n) \(f.title)" : f.title, sprite: f.sprite) { $0.food[f, default: 0] += n } }
private func seedGift(_ c: Crop, _ n: Int) -> Surprise { Surprise(title: "\(n) \(c.title) seeds", sprite: c.sprite) { $0.seeds[c, default: 0] += n } }
private func hatGift(_ h: Hat) -> Surprise { Surprise(title: h.title, sprite: "gift") { $0.hats.insert(h) } }
private func outfitGift(_ o: Outfit) -> Surprise { Surprise(title: o.title, sprite: "gift") { $0.outfits.insert(o) } }

/// Door 1…24. Day 24 is the best one.
let adventSurprises: [Surprise] = [
    foodGift(.candy, 2), itemGift(.stocking), foodGift(.hotCocoa), itemGift(.wreath), seedGift(.wheat, 6), itemGift(.candles),
    itemGift(.poinsettia), foodGift(.pie), hatGift(.earmuffs), itemGift(.garland), itemGift(.nutcracker), seedGift(.carrot, 6),
    itemGift(.snowman), itemGift(.sled), outfitGift(.pajamas), itemGift(.presents), seedGift(.ginger, 3), itemGift(.rockingChair),
    foodGift(.hotCocoa, 2), itemGift(.toyChest), hatGift(.topHat), itemGift(.gingerbreadHouse), outfitGift(.snowsuit), hatGift(.crown),
]

/// Where each day's door sits in the 4 × 6 grid (mixed up, like a real calendar).
let adventOrder = [13, 2, 20, 7, 17, 10, 4, 24, 15, 1, 9, 22, 6, 19, 12, 3, 23, 8, 16, 11, 21, 5, 18, 14]

// MARK: - Sticker book: one sticker for everything you collect or do

struct Sticker: Hashable { let id: String; let title: String; let sprite: String }

/// Ids match Android (Kotlin enum names), so the two books line up.
private func kname<T: RawRepresentable>(_ v: T) -> String where T.RawValue == String { v.rawValue.prefix(1).uppercased() + v.rawValue.dropFirst() }

let stickers: [Sticker] = {
    var out: [Sticker] = []
    Cookie.allCases.forEach { out.append(Sticker(id: "cookie:\(kname($0))", title: "Baked a \($0.title)", sprite: $0.sprite)) }
    Toy.allCases.forEach { out.append(Sticker(id: "toy:\(kname($0))", title: "Made a \($0.title)", sprite: $0.sprite)) }
    reindeerNames.forEach { out.append(Sticker(id: "deer:\($0)", title: "Pampered \($0) (fed, brushed & washed)", sprite: "reindeer")) }
    PetKind.allCases.forEach { out.append(Sticker(id: "pet:\(kname($0))", title: "Adopted a \($0.title)", sprite: $0.sprite)) }
    Item.allCases.forEach { out.append(Sticker(id: "item:\(kname($0))", title: "Owned a \($0.title)", sprite: $0.sprite)) }
    out += [
        Sticker(id: "wrap", title: "Wrapped a present", sprite: "gift"), Sticker(id: "ginger", title: "Built a gingerbread house", sprite: "ginghouse"),
        Sticker(id: "tree", title: "Decorated the Town Tree", sprite: "tree"), Sticker(id: "snowball", title: "Snowball champion (10 hits)", sprite: "snowman"),
        Sticker(id: "flight", title: "Finished a sleigh flight", sprite: "sleigh"), Sticker(id: "friend", title: "Made a best friend", sprite: "candy"),
        Sticker(id: "level8", title: "Became Santa's Best Elf", sprite: "santa"), Sticker(id: "christmas", title: "Saved Christmas!", sprite: "presents"),
        Sticker(id: "advent", title: "Opened an advent door", sprite: "candycane"),
    ]
    return out
}()

/// Sticker milestones and their prizes.
let stickerPrizes: [(Int, Surprise)] = [(10, itemGift(.presents)), (25, hatGift(.topHat)), (40, itemGift(.toyChest)), (60, hatGift(.crown))]

// MARK: - The house: two storeys to start, more floors as upgrades

/// One floor of the house, bottom (0) to top. `price` is the upgrade cost (0 = you start with it).
struct Room { let title: String; let emoji: String; let price: Int; let wall: UInt32; let stripe: UInt32 }

let rooms = [
    Room(title: "Living Room", emoji: "🛋️", price: 0, wall: 0xE3F0D8, stripe: 0xD3E6C4),
    Room(title: "Bedroom", emoji: "🛏️", price: 0, wall: 0xF6D7E3, stripe: 0xEFC3D3),
    Room(title: "Attic Playroom", emoji: "🧸", price: 3000, wall: 0xFFF1C9, stripe: 0xF6E2A6),
    Room(title: "Starlight Loft", emoji: "🔭", price: 6000, wall: 0xD9D4F7, stripe: 0xC6BFF0),
]
let startFloors = 2

/// Little things your pets get up to. "%@" is the pet's name.
let petHappenings = [
    "%@ is napping on the rug 💤", "%@ is chasing a dust bunny 🐾", "%@ found a sock! 🧦", "%@ is staring out the window ❄️",
    "%@ is doing zoomies! 💨", "%@ is playing with a ribbon 🎀", "%@ is hiding under the bed 👀", "%@ is guarding the presents 🎁",
]
let roomHappenings = ["The fire is crackling 🔥", "Someone left cookie crumbs on the pillow 🍪", "The toy train is going round and round 🚂", "The stars are twinkling through the telescope ✨"]

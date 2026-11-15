import SwiftUI
import Observation

// Port of the Android GameState.kt. Same rules, same numbers.

struct Plot: Codable, Hashable {
    var id: Int
    var crop: Crop?
    var wateredAt: Double?

    func progress(_ now: Double) -> Double {
        guard let crop, let wateredAt else { return 0 }
        return min(1, max(0, (now - wateredAt) / crop.growSeconds))
    }
    /// 0 empty, 1 needs water, 2 growing, 3 ready
    func stage(_ now: Double) -> Int { crop == nil ? 0 : wateredAt == nil ? 1 : progress(now) < 1 ? 2 : 3 }
}

enum Overlay: Equatable {
    case none
    case paid(newLevel: Int?)
    case morning(day: Int, worked: Bool)
    case christmasEve
    case won
}

/// Everything that gets saved. Every field has a default, and missing fields load as the default,
/// so adding new things later never breaks an old save.
struct Save: Codable {
    var name = ""
    var look = ElfLook()
    var hasElf = false
    var hair: Set<HairStyle> = [.short, .long]
    var outfits: Set<Outfit> = [.tunic]
    var hats: Set<Hat> = [.none, .elf]
    var accessories: Set<Accessory> = [.none]
    var money = 1000
    var day = 1
    var workdays = 0
    var energy = 100
    var paidToday = false
    var christmasDone = false
    var seeds: [Crop: Int] = [.wheat: 4, .carrot: 4]
    var crops: [Crop: Int] = [.wheat: 4, .carrot: 4]
    var cookies: [Cookie: Int] = [:]
    var toys: [Toy: Int] = [:]
    var food: [Food: Int] = [.hotCocoa: 1]
    var plots: [Plot] = (0..<6).map { Plot(id: $0) }
    var fed: Set<String> = []
    var brushed: Set<String> = []
    var owned: [Item: Int] = Dictionary(startingHouse.map { ($0.item, 1) }, uniquingKeysWith: +)
    var placed: [Placed] = startingHouse
    var hearts: [String: Int] = [:]
    var talkedToday: Set<String> = []
    var partyDone = false
    var bestGifts: Set<String> = []
    var jobs: [Job] = jobsFor(1)
    var kids: [Kid] = makeKids(5)
    var kidIndex = 0
    var chats: [String: [ChatMsg]] = [:]
    var lastRead: [String: Double] = [:]
    var lastGroupVisit: Double = 0
    var memory: [String: String] = [:]
    var musicOn = true
    var soundOn = true

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Save()
        func v<T: Decodable>(_ k: CodingKeys, _ fallback: T) -> T { (try? c.decodeIfPresent(T.self, forKey: k)) ?? fallback }
        name = v(.name, d.name); look = v(.look, d.look); hasElf = v(.hasElf, d.hasElf)
        hair = v(.hair, d.hair); outfits = v(.outfits, d.outfits); hats = v(.hats, d.hats); accessories = v(.accessories, d.accessories)
        money = v(.money, d.money); day = v(.day, d.day); workdays = v(.workdays, d.workdays); energy = v(.energy, d.energy)
        paidToday = v(.paidToday, d.paidToday); christmasDone = v(.christmasDone, d.christmasDone)
        seeds = v(.seeds, d.seeds); crops = v(.crops, d.crops); cookies = v(.cookies, d.cookies); toys = v(.toys, d.toys); food = v(.food, d.food)
        plots = v(.plots, d.plots); fed = v(.fed, d.fed); brushed = v(.brushed, d.brushed)
        owned = v(.owned, d.owned); placed = v(.placed, d.placed)
        hearts = v(.hearts, d.hearts); talkedToday = v(.talkedToday, d.talkedToday); partyDone = v(.partyDone, d.partyDone); bestGifts = v(.bestGifts, d.bestGifts)
        jobs = v(.jobs, d.jobs); kids = v(.kids, d.kids); kidIndex = v(.kidIndex, d.kidIndex)
        chats = v(.chats, d.chats); lastRead = v(.lastRead, d.lastRead); lastGroupVisit = v(.lastGroupVisit, d.lastGroupVisit); memory = v(.memory, d.memory)
        musicOn = v(.musicOn, d.musicOn); soundOn = v(.soundOn, d.soundOn)
    }
}

@MainActor @Observable
final class GameState {
    private(set) var s: Save

    // Right-now stuff (not saved)
    var place: Place?            // nil = main screen
    var overlay: Overlay = .none
    var toast: String?
    var showCreator = false
    var showJobs = false
    var delivering = false
    var christmasEveRide = false
    var selectedSeed: Crop = .wheat
    var now = Date().timeIntervalSince1970

    @ObservationIgnored private var toastUntil = 0.0
    @ObservationIgnored private var timer: Timer?
    private static let key = "christmas-town-save"

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.key), let saved = try? JSONDecoder().decode(Save.self, from: data) {
            s = saved
        } else {
            s = Save()
        }
        Audio.shared.soundOn = s.soundOn
        Audio.shared.musicOn = s.musicOn
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
    }

    private func update(_ change: (inout Save) -> Void) {
        change(&s)
        if let data = try? JSONEncoder().encode(s) { UserDefaults.standard.set(data, forKey: Self.key) }
    }

    private func tick() {
        now = Date().timeIntervalSince1970
        if toast != nil && now > toastUntil { toast = nil }
    }

    func say(_ msg: String) { toast = msg; toastUntil = Date().timeIntervalSince1970 + 3 }

    var level: Int { levelFor(s.workdays) }
    var levelTitle: String { levelTitles[level - 1] }
    var reindeer: [String] { Array(reindeerNames.prefix(reindeerCount(level))) }
    var unlockedCrops: [Crop] { Crop.allCases.filter { $0.unlockLevel <= level } }
    var jobsDone: Int { s.jobs.filter(\.finished).count }

    // MARK: Energy

    private func useEnergy(_ amount: Int) -> Bool {
        guard s.energy >= amount else { say("Too tired! 😴 Eat a cookie or some food, or go to sleep."); Audio.shared.play(.oops); return false }
        update { $0.energy -= amount }
        return true
    }

    func eat(_ f: Food) {
        guard s.food[f, default: 0] > 0 else { return }
        guard s.energy < 100 else { say("You're already full of energy! ⚡"); return }
        update { $0.food[f, default: 0] -= 1; $0.energy = min(100, $0.energy + f.energy) }
        say("Yum! +\(f.energy) energy ⚡")
    }

    func eat(_ c: Cookie) {
        guard s.cookies[c, default: 0] > 0 else { return }
        guard s.energy < 100 else { say("You're already full of energy! ⚡"); return }
        update { $0.cookies[c, default: 0] -= 1; $0.energy = min(100, $0.energy + c.energy) }
        say("Crunch! +\(c.energy) energy ⚡")
    }

    // MARK: Jobs & pay

    private func progress(_ kind: JobKind, _ amount: Int = 1) {
        guard !s.paidToday else { return }
        update { save in
            for i in save.jobs.indices where save.jobs[i].kind == kind { save.jobs[i].done = min(save.jobs[i].goal, save.jobs[i].done + amount) }
        }
        if s.jobs.allSatisfy(\.finished) { payDay() }
    }

    private func payDay() {
        let before = level
        update { $0.money += dailyPay; $0.paidToday = true; $0.workdays += 1 }
        overlay = .paid(newLevel: level > before ? level : nil)
        Audio.shared.play(level > before ? .levelUp : .coins)
        if level >= 3 { update { save in while save.plots.count < 9 { save.plots.append(Plot(id: save.plots.count)) } } }
    }

    func afterPaid() { overlay = s.workdays >= christmasEveWorkdays && !s.christmasDone ? .christmasEve : .none }

    func sleep() {
        let worked = s.paidToday
        update { save in
            save.day += 1; save.energy = 100; save.paidToday = false; save.fed = []; save.brushed = []; save.talkedToday = []
            save.jobs = jobsFor(levelFor(save.workdays)); save.kids = makeKids(5); save.kidIndex = 0
        }
        overlay = .morning(day: s.day, worked: worked)
        place = nil
    }

    // MARK: Greenhouse

    func tapPlot(_ id: Int) {
        guard let i = s.plots.firstIndex(where: { $0.id == id }) else { return }
        let t = Date().timeIntervalSince1970
        switch s.plots[i].stage(t) {
        case 0:
            let c = selectedSeed
            guard s.seeds[c, default: 0] > 0 else { say("No \(c.title.lowercased()) seeds! Buy some at the Shop 🛍️"); Audio.shared.play(.oops); return }
            update { $0.seeds[c, default: 0] -= 1; $0.plots[i].crop = c }
            Audio.shared.play(.pop)
        case 1:
            update { $0.plots[i].wateredAt = t }
            Audio.shared.play(.tap)
        case 2: say("Still growing… 🌱")
        default:
            let c = s.plots[i].crop!
            update { $0.crops[c, default: 0] += harvest; $0.plots[i] = Plot(id: id) }
            say("Picked \(harvest) \(c.plural)!")
            Audio.shared.play(.pop)
        }
    }

    func plantAll() {
        let c = selectedSeed
        var n = 0
        update { save in
            for i in save.plots.indices where save.plots[i].crop == nil && save.seeds[c, default: 0] > 0 {
                save.seeds[c, default: 0] -= 1; save.plots[i].crop = c; n += 1
            }
        }
        say(n == 0 ? "No empty pots, or no \(c.title.lowercased()) seeds!" : "Planted \(n) seeds 🌱")
        Audio.shared.play(n == 0 ? .oops : .pop)
    }

    func waterAll() {
        let t = Date().timeIntervalSince1970
        update { save in for i in save.plots.indices where save.plots[i].stage(t) == 1 { save.plots[i].wateredAt = t } }
        Audio.shared.play(.tap)
    }

    func pickAll() {
        let t = Date().timeIntervalSince1970
        var picked = 0
        update { save in
            for i in save.plots.indices where save.plots[i].stage(t) == 3 {
                save.crops[save.plots[i].crop!, default: 0] += harvest; picked += harvest; save.plots[i] = Plot(id: save.plots[i].id)
            }
        }
        say(picked == 0 ? "Nothing is ready yet 🌱" : "Picked \(picked) crops!")
        if picked > 0 { Audio.shared.play(.pop) }
    }

    // MARK: Bakery

    func canBake(_ c: Cookie) -> Bool { c.recipe.allSatisfy { s.crops[$0.0, default: 0] >= $0.1 } }

    @discardableResult func bake(_ c: Cookie) -> Bool {
        guard canBake(c) else { say("Not enough ingredients! Grow some in the Greenhouse 🌱"); Audio.shared.play(.oops); return false }
        guard useEnergy(5) else { return false }
        update { save in for (crop, n) in c.recipe { save.crops[crop, default: 0] -= n }; save.cookies[c, default: 0] += 1 }
        Audio.shared.play(.ding)
        progress(.bake)
        return true
    }

    // MARK: Workshop

    func startToy() -> Bool { useEnergy(5) }

    func finishToy(_ t: Toy) {
        update { $0.toys[t, default: 0] += 1 }
        say("You made a \(t.title)! 🎁")
        Audio.shared.play(.ding)
        progress(.toys)
    }

    // MARK: Stable

    func feed(_ name: String) {
        guard !s.fed.contains(name) else { say("\(name) is full! 🥕"); return }
        guard s.crops[.carrot, default: 0] > 0 else { say("No carrots! Grow some in the Greenhouse 🥕"); Audio.shared.play(.oops); return }
        guard useEnergy(2) else { return }
        update { $0.fed.insert(name); $0.crops[.carrot, default: 0] -= 1 }
        say("\(name) munches happily! 🥕")
        Audio.shared.play(.munch)
        checkReindeer()
    }

    func brush(_ name: String) {
        guard !s.brushed.contains(name) else { say("\(name) is already super shiny! ✨"); return }
        guard useEnergy(2) else { return }
        update { $0.brushed.insert(name) }
        say("\(name) looks so shiny! ✨")
        Audio.shared.play(.sleighBells)
        checkReindeer()
    }

    private func checkReindeer() {
        if reindeer.allSatisfy({ s.fed.contains($0) && s.brushed.contains($0) }) { progress(.reindeer) }
    }

    // MARK: Santa's list

    var currentKid: Kid? { s.kidIndex < s.kids.count ? s.kids[s.kidIndex] : nil }

    func sortKid(nice: Bool) -> Bool {
        guard let kid = currentKid else { return true }
        guard useEnergy(1) else { return true }
        update { $0.kidIndex += 1 }
        progress(.sortList)
        Audio.shared.play(kid.nice == nice ? .ding : .oops)
        return kid.nice == nice
    }

    // MARK: Delivery

    var presents: Int { s.toys.values.reduce(0, +) }

    func deliver() -> Bool {
        if christmasEveRide { Audio.shared.play(.presentDrop); return true }
        guard let toy = s.toys.first(where: { $0.value > 0 })?.key else { say("No presents left! Make toys in the Workshop 🧸"); Audio.shared.play(.oops); return false }
        update { $0.toys[toy, default: 0] -= 1 }
        Audio.shared.play(.presentDrop)
        progress(.deliver)
        return true
    }

    func startDelivery() {
        guard let job = s.jobs.first(where: { $0.kind == .deliver }) else { say("Deliveries start at Level 3! 🛷"); return }
        if job.finished { say("All of today's presents are delivered! 🎉"); return }
        guard useEnergy(10) else { return }
        delivering = true
        Audio.shared.play(.sleighBells)
    }

    func startChristmasEve() {
        overlay = .none
        christmasEveRide = true
        delivering = true
        Audio.shared.play(.sleighBells)
    }

    func endDelivery(finishedChristmas: Bool) {
        delivering = false
        if christmasEveRide {
            christmasEveRide = false
            if finishedChristmas { update { $0.christmasDone = true }; overlay = .won }
        }
    }

    // MARK: Shop

    private func pay(_ price: Int) -> Bool {
        guard s.money >= price else { say("Not enough money! 💸 Work for Santa to earn $1,000 a day."); Audio.shared.play(.oops); return false }
        update { $0.money -= price }
        Audio.shared.play(.coins)
        return true
    }

    func buyItem(_ i: Item) { if pay(i.price) { update { $0.owned[i, default: 0] += 1 }; say("Bought \(i.title)! Place it with Decorate 🎄") } }
    func buyFood(_ f: Food) { if pay(f.price) { update { $0.food[f, default: 0] += 1 } } }
    func buySeed(_ c: Crop) {
        guard c.unlockLevel <= level else { say("\(c.title) seeds unlock at Level \(c.unlockLevel) 🔒"); return }
        if pay(c.seedPrice) { update { $0.seeds[c, default: 0] += 1 } }
    }
    func buyHair(_ h: HairStyle) { if !s.hair.contains(h) && pay(h.price) { update { $0.hair.insert(h); $0.look.hairStyle = h }; say("New hairstyle! 💇") } }
    func buyOutfit(_ o: Outfit) { if !s.outfits.contains(o) && pay(o.price) { update { $0.outfits.insert(o); $0.look.outfit = o }; say("Ooh, stylish! 👗") } }
    func buyHat(_ h: Hat) { if !s.hats.contains(h) && pay(h.price) { update { $0.hats.insert(h); $0.look.hat = h }; say("Nice hat! 🎩") } }
    func buyAccessory(_ a: Accessory) { if !s.accessories.contains(a) && pay(a.price) { update { $0.accessories.insert(a); $0.look.accessory = a }; say("So cute! ✨") } }

    func setLook(_ look: ElfLook) { update { $0.look = look } }

    func saveElf(name: String, look: ElfLook) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        update { $0.name = String((trimmed.isEmpty ? "Lexi" : trimmed).prefix(12)); $0.look = look; $0.hasElf = true }
        showCreator = false
    }

    // MARK: House

    func available(_ i: Item) -> Int { s.owned[i, default: 0] - s.placed.filter { $0.item == i }.count }

    func place(_ i: Item, floor: Int) -> Int? {
        guard available(i) > 0 else { return nil }
        let id = (s.placed.map(\.id).max() ?? 0) + 1
        update { $0.placed.append(Placed(id: id, item: i, floor: floor, x: 0.5, y: 0.3)) }
        Audio.shared.play(.pop)
        return id
    }

    func move(_ id: Int, x: Double, y: Double) {
        update { save in
            guard let i = save.placed.firstIndex(where: { $0.id == id }) else { return }
            save.placed[i].x = min(0.96, max(0.04, x)); save.placed[i].y = min(0.7, max(0, y))
        }
    }

    func switchFloor(_ id: Int) { update { save in if let i = save.placed.firstIndex(where: { $0.id == id }) { save.placed[i].floor = 1 - save.placed[i].floor } } }
    func putAway(_ id: Int) { update { $0.placed.removeAll { $0.id == id } } }

    // MARK: Elf friends

    func hearts(_ n: Npc) -> Int { s.hearts[n.name, default: 0] }

    func chat(_ n: Npc) {
        if !s.talkedToday.contains(n.name) { update { $0.hearts[n.name] = min(5, $0.hearts[n.name, default: 0] + 1); $0.talkedToday.insert(n.name) } }
        checkBestFriend(n)
    }

    func giveCookie(_ n: Npc) {
        guard let cookie = s.cookies.first(where: { $0.value > 0 })?.key else { say("You don't have any cookies! Bake some 🍪"); Audio.shared.play(.oops); return }
        update { $0.cookies[cookie, default: 0] -= 1; $0.hearts[n.name] = min(5, $0.hearts[n.name, default: 0] + 2) }
        say("\(n.name) loves the \(cookie.title)! 💖")
        Audio.shared.play(.ding)
        checkBestFriend(n)
    }

    private func checkBestFriend(_ n: Npc) {
        if hearts(n) >= 5 && !s.bestGifts.contains(n.name) {
            update { $0.bestGifts.insert(n.name); $0.owned[n.bestFriendGift, default: 0] += 1 }
            say("\(n.name) is your BEST FRIEND! They gave you a \(n.bestFriendGift.title)! 🎁")
        }
    }

    func throwParty(_ reward: Item) {
        update { $0.partyDone = true; $0.owned[reward, default: 0] += 1; $0.hearts["Twinkle"] = min(5, $0.hearts["Twinkle", default: 0] + 1) }
        say("Best party ever! 🎉 You got a \(reward.title) for your house!")
    }

    func go(_ p: Place?) { place = p }

    // MARK: Settings

    func toggleMusic() { update { $0.musicOn.toggle() }; Audio.shared.musicOn = s.musicOn }
    func toggleSound() { update { $0.soundOn.toggle() }; Audio.shared.soundOn = s.soundOn; Audio.shared.play(.tap) }

    // MARK: Phone

    /// Elves you've met (talked to in Friends) are in your phone.
    var met: [String] { npcs.filter { s.hearts[$0.name, default: 0] > 0 }.map(\.name) }
    func messages(_ thread: String) -> [ChatMsg] { s.chats[thread] ?? [] }
    func unread(_ thread: String) -> Int { messages(thread).filter { $0.from != me && $0.time > s.lastRead[thread, default: 0] }.count }
    var groupHasNews: Bool { !met.isEmpty && Date().timeIntervalSince1970 - s.lastGroupVisit > 120 }

    func remember(_ key: String, _ value: String) { update { $0.memory[key] = value } }

    func post(_ thread: String, _ msgs: [ChatMsg]) {
        guard !msgs.isEmpty else { return }
        if msgs.contains(where: { $0.from != me }) { Audio.shared.play(.message) }
        update { $0.chats[thread] = Array(((($0.chats[thread]) ?? []) + msgs).suffix(80)) }
    }

    func markRead(_ thread: String) { update { $0.lastRead[thread] = Date().timeIntervalSince1970 } }

    /// Opening the group chat: 1–3 things happened while you were away.
    func openGroup() {
        let t = Date().timeIntervalSince1970
        let since = s.lastGroupVisit
        if !met.isEmpty {
            if since == 0 {
                post(groupThread, met.enumerated().map { i, n in
                    ChatMsg(from: n, text: ["Welcome to the group chat, \(s.name)! 🎄", "Yay, \(s.name) is here!! ✨", "Hi hi hi! 👋", "Hello! 🦌"].randomElement()!, time: t - Double(met.count - i) * 30)
                })
            } else if t - since > 60 {
                let count = t - since > 30 * 60 ? 3 : Int.random(in: 1...3)
                post(groupThread, ElfBrain.groupEvents(self, met: met, since: since, now: t, count: count))
            }
        }
        update { $0.lastGroupVisit = t }
    }

    /// While you're watching, the group chat sometimes keeps going.
    func liveGroupEvent() {
        let t = Date().timeIntervalSince1970
        post(groupThread, ElfBrain.groupEvents(self, met: met, since: t - 30, now: t, count: 1).map { var m = $0; m.time = min(m.time, t); return m })
        update { $0.lastGroupVisit = t }
    }

    func chatFriendship(_ elf: String) { if let n = npc(elf) { chat(n) } }
}

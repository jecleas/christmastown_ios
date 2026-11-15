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
    case tunic, sweater, dress, overalls
    var title: String { ["tunic": "Elf Tunic", "sweater": "Christmas Sweater", "dress": "Party Dress", "overalls": "Overalls"][rawValue]! }
    var price: Int { ["tunic": 0, "sweater": 500, "dress": 400, "overalls": 450][rawValue]! }
    var sprite: String? { self == .tunic ? nil : "outfit_\(rawValue)" }
}

enum Hat: String, Codable, CaseIterable {
    case none, elf, beanie, santa, antlers, crown
    var title: String { ["none": "No Hat", "elf": "Elf Hat", "beanie": "Beanie", "santa": "Santa Hat", "antlers": "Antlers", "crown": "Crown"][rawValue]! }
    var price: Int { ["none": 0, "elf": 0, "beanie": 300, "santa": 600, "antlers": 500, "crown": 1500][rawValue]! }
    var sprite: String? { self == .none ? nil : "hat_\(rawValue)" }
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
    case wheat, carrot, berry, cocoa
    var title: String { rawValue.capitalized }
    var plural: String { ["wheat": "wheat", "carrot": "carrots", "berry": "berries", "cocoa": "cocoa pods"][rawValue]! }
    var seedPrice: Int { ["wheat": 20, "carrot": 20, "berry": 40, "cocoa": 60][rawValue]! }
    var growSeconds: Double { ["wheat": 10, "carrot": 10, "berry": 14, "cocoa": 18][rawValue]! }
    var unlockLevel: Int { ["wheat": 1, "carrot": 1, "berry": 2, "cocoa": 3][rawValue]! }
    var sprite: String { rawValue }
}

let harvest = 3

enum Cookie: String, Codable, CaseIterable {
    case sugar, berryJam, choco
    var title: String { ["sugar": "Sugar Cookie", "berryJam": "Berry Cookie", "choco": "Choc Chip Cookie"][rawValue]! }
    var recipe: [(Crop, Int)] { self == .sugar ? [(.wheat, 2)] : self == .berryJam ? [(.wheat, 2), (.berry, 1)] : [(.wheat, 2), (.cocoa, 1)] }
    var unlockLevel: Int { ["sugar": 1, "berryJam": 2, "choco": 3][rawValue]! }
    var energy: Int { ["sugar": 15, "berryJam": 20, "choco": 25][rawValue]! }
    var sprite: String { ["sugar": "cookie_sugar", "berryJam": "cookie_berry", "choco": "cookie_choco"][rawValue]! }
}

enum Toy: String, Codable, CaseIterable {
    case teddy, candyCane, train, doll, drum, robot
    var title: String { ["teddy": "Teddy Bear", "candyCane": "Candy Cane", "train": "Toy Train", "doll": "Doll", "drum": "Drum", "robot": "Robot"][rawValue]! }
    var unlockLevel: Int { ["teddy": 1, "candyCane": 1, "train": 2, "doll": 3, "drum": 4, "robot": 5][rawValue]! }
    var sprite: String { self == .candyCane ? "candycane" : rawValue }
    var steps: [String] {
        switch self {
        case .teddy: ["Stuff it with cotton", "Sew it up", "Pick a fur color"]
        case .candyCane: ["Pull the sugar", "Pick a stripe color", "Bend the hook"]
        case .train: ["Build the engine", "Screw on the wheels", "Paint it"]
        case .doll: ["Sew the face", "Brush the hair", "Pick a dress"]
        case .drum: ["Stretch the top", "Paint the drum", "Add the sticks"]
        case .robot: ["Bolt the body", "Charge the battery", "Pick a paint"]
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

    var title: String {
        ["tree": "Christmas Tree", "fireplace": "Fireplace", "couch": "Couch", "armchair": "Armchair", "bed": "Bed", "table": "Table",
         "lamp": "Lamp", "bookshelf": "Bookshelf", "rug": "Rug", "clock": "Clock", "picture": "Picture", "stocking": "Stocking",
         "wreath": "Wreath", "garland": "Twinkle Lights", "snowman": "Snowman", "presents": "Presents", "poinsettia": "Poinsettia",
         "gingerbreadHouse": "Gingerbread House", "candles": "Candles"][rawValue]!
    }
    var price: Int {
        ["tree": 800, "fireplace": 900, "couch": 600, "armchair": 400, "bed": 700, "table": 300, "lamp": 200, "bookshelf": 500, "rug": 250,
         "clock": 200, "picture": 150, "stocking": 100, "wreath": 150, "garland": 200, "snowman": 350, "presents": 300, "poinsettia": 150,
         "gingerbreadHouse": 250, "candles": 120][rawValue]!
    }
    var sprite: String { self == .gingerbreadHouse ? "ginghouse" : rawValue }
    var spot: Spot { [.clock, .picture, .stocking, .wreath, .garland].contains(self) ? .wall : self == .rug ? .rug : .floor }
    var kind: ItemKind { [.tree, .stocking, .wreath, .garland, .snowman, .presents, .poinsettia, .gingerbreadHouse, .candles].contains(self) ? .decoration : .furniture }
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
func reindeerCount(_ level: Int) -> Int { [2, 4, 6, 8, 9][max(0, min(4, level - 1))] }

let levelTitles = ["Helper Elf", "Cookie Elf", "Toy Elf", "Sleigh Elf", "Santa's Best Elf"]
let maxLevel = 5
let dailyPay = 1000
let christmasEveWorkdays = 10

func levelFor(_ workdays: Int) -> Int { workdays >= 8 ? 5 : workdays >= 6 ? 4 : workdays >= 4 ? 3 : workdays >= 2 ? 2 : 1 }

enum JobKind: String, Codable {
    case bake, toys, reindeer, sortList, deliver
    var emoji: String { ["bake": "🍪", "toys": "🧸", "reindeer": "🦌", "sortList": "📜", "deliver": "🛷"][rawValue]! }
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
        }
    }
}

func jobsFor(_ level: Int) -> [Job] {
    var jobs = [Job(kind: .bake, goal: [2, 3, 3, 4, 4][level - 1]), Job(kind: .toys, goal: [2, 3, 4, 5, 6][level - 1]), Job(kind: .reindeer, goal: 1)]
    if level >= 2 { jobs.append(Job(kind: .sortList, goal: 5)) }
    if level >= 3 { jobs.append(Job(kind: .deliver, goal: [0, 0, 4, 5, 6][level - 1])) }
    return jobs
}

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
        "Rudolph joins the stable at Level 5. His nose glows!",
        "Seeds need water before they grow. 💧",
    ], bestFriendGift: .poinsettia),
]

func npc(_ name: String) -> Npc? { npcs.first { $0.name == name } }

let partyThemes: [(String, Item)] = [("Candy Land 🍭", .gingerbreadHouse), ("Winter Wonderland ⛄", .snowman), ("Cozy Cabin 🕯️", .candles)]

// MARK: - The icons on the main screen

enum Side { case left, right }

enum Place: String, CaseIterable, Identifiable {
    case greenhouse, bakery, stable, workshop, santaList, sleigh, decorate, shop, closet, friends, phone, snacks
    var id: String { rawValue }
    var title: String {
        ["greenhouse": "Greenhouse", "bakery": "Bakery", "stable": "Stable", "workshop": "Workshop", "santaList": "Santa's List", "sleigh": "Sleigh",
         "decorate": "Decorate", "shop": "Shop", "closet": "Closet", "friends": "Friends", "phone": "Phone", "snacks": "Snacks"][rawValue]!
    }
    var sprite: String {
        ["greenhouse": "wheat", "bakery": "cookie_sugar", "stable": "reindeer", "workshop": "teddy", "santaList": "santa", "sleigh": "sleigh",
         "decorate": "tree", "shop": "presents", "closet": "", "friends": "", "phone": "phone", "snacks": "cocoa_mug"][rawValue]!
    }
    var side: Side { [.greenhouse, .bakery, .stable, .workshop, .santaList, .sleigh].contains(self) ? .left : .right }
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
        }
    }
    var dark: Bool { [.decorate, .snacks, .phone, .stable, .santaList, .sleigh, .friends, .closet].contains(self) }
}

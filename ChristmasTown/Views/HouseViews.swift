import SwiftUI

private let houseW: CGFloat = 800
private let roofH: CGFloat = 90
private let roomH: CGFloat = 230
private let roomX: CGFloat = 16
private let roomW: CGFloat = houseW - 32
private let pixel: CGFloat = 5

private func houseH(_ floors: Int) -> CGFloat { roofH + roomH * CGFloat(floors) + 16 }
private func roomTop(_ floor: Int, _ floors: Int) -> CGFloat { roofH + CGFloat(floors - 1 - floor) * roomH }   // the top floor is drawn first
private func floorLine(_ floor: Int, _ floors: Int) -> CGFloat { roomTop(floor, floors) + roomH - 14 }

// MARK: - Decorate (your house: two storeys, more with upgrades)

struct DecorateView: View {
    let game: GameState
    @State private var selected: Int?
    @State private var targetFloor = 0
    @State private var zoom: Int?

    var body: some View {
        let floors = game.s.floors
        VStack(spacing: 8) {
            if let inside = zoom {
                HStack(spacing: 8) {
                    Btn("🏠 Whole house", Pal.brown, size: 14, width: 150) { zoom = nil }
                    Txt("\(rooms[inside].emoji) \(rooms[inside].title)", 20, .white, lines: 1)
                    Spacer(minLength: 0)
                }
                RoomScene(game: game, floor: inside, hub: false)
                    .frame(height: 440)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Pal.ink, lineWidth: 3))
            } else {
                let hh = houseH(floors)
                let k = min(406 / houseW, 400 / hh)
                House(game: game, selected: $selected) { zoom = $0 }
                    .frame(width: houseW, height: hh)
                    .scaleEffect(k)
                    .frame(width: houseW * k, height: hh * k)
                Txt("Tap a room to look inside. Drag things to move them.", 14, .white, align: .center)
            }

            ScrollView {
                VStack(spacing: 8) {
                    if zoom == nil, let room = game.nextRoom {
                        HStack(spacing: 8) {
                            Txt("🏗️ Add a \(room.title) \(room.emoji) on top!", 15)
                            Spacer()
                            Btn("Build \(money(room.price))", Pal.blue, size: 14, width: 150) { game.upgradeHouse() }
                        }
                        .padding(8).panel(Color(hex: 0xDDE7FF))
                    }
                    if zoom == nil, let sel = game.s.placed.first(where: { $0.id == selected }) {
                        HStack(spacing: 6) {
                            Txt(sel.item.title, 16)
                            Spacer()
                            Btn("🔁 \(rooms[(sel.floor + 1) % floors].emoji)", Pal.blue, size: 14, width: 80) { game.switchFloor(sel.id) }
                            Btn("📦 Away", Pal.brown, size: 14, width: 100) { game.putAway(sel.id); selected = nil }
                        }
                        .padding(8).panel(Pal.paleGold)
                    }
                    if let inside = zoom {
                        Txt("Put things in the \(rooms[inside].title):", 15).frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                Txt("Place in:", 15)
                                ForEach(0..<floors, id: \.self) { f in
                                    Tap(action: { targetFloor = f }) {
                                        Txt("\(rooms[f].emoji) \(rooms[f].title)", 13, targetFloor == f ? .white : Pal.ink).padding(.horizontal, 8).padding(.vertical, 3).panel(targetFloor == f ? Pal.green : .white)
                                    }
                                }
                            }
                        }
                    }
                    let stored = Item.allCases.filter { game.available($0) > 0 }
                    if stored.isEmpty { Txt("Everything is out! Buy more in the Shop 🛍️", 14) }
                    ForEach(stored, id: \.self) { i in
                        HStack(spacing: 8) {
                            Px(i.sprite, 38).frame(width: 44, height: 44)
                            Txt("\(i.title) ×\(game.available(i))", 15)
                            Spacer()
                            Btn("Place", Pal.green, size: 14, width: 80) { selected = game.place(i, floor: zoom ?? targetFloor) }
                        }
                        .padding(6).panel(.white)
                    }
                }
                .padding(10)
            }
            .panel()
        }
    }
}

private struct House: View {
    let game: GameState
    @Binding var selected: Int?
    let onZoom: (Int) -> Void

    var body: some View {
        let floors = game.s.floors
        ZStack(alignment: .topLeading) {
            Canvas { ctx, _ in
                func r(_ c: Color, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) { ctx.fill(Path(CGRect(x: x, y: y, width: w, height: h)), with: .color(c)) }
                var roof = Path(); roof.move(to: CGPoint(x: 0, y: roofH)); roof.addLine(to: CGPoint(x: houseW / 2, y: 0)); roof.addLine(to: CGPoint(x: houseW, y: roofH)); roof.closeSubpath()
                ctx.fill(roof, with: .color(Pal.darkRed))
                var snow = Path()
                snow.move(to: CGPoint(x: 40, y: roofH - 18)); snow.addLine(to: CGPoint(x: houseW / 2, y: 6)); snow.addLine(to: CGPoint(x: houseW - 40, y: roofH - 18))
                snow.addLine(to: CGPoint(x: houseW - 40, y: roofH - 8)); snow.addLine(to: CGPoint(x: houseW / 2, y: 20)); snow.addLine(to: CGPoint(x: 40, y: roofH - 8)); snow.closeSubpath()
                ctx.fill(snow, with: .color(Color(hex: 0xF4F8FF)))
                r(Color(hex: 0x6B4A3A), houseW - 190, 10, 40, 60); r(Color(hex: 0xF4F8FF), houseW - 196, 6, 52, 10)
                r(Pal.ink, 0, roofH, houseW, roomH * CGFloat(floors) + 16)
                for f in 0..<floors {
                    let top = roomTop(f, floors), room = rooms[f]
                    r(Color(hex: room.wall), roomX, top + 8, roomW, roomH - 8)
                    var x = roomX
                    while x < roomX + roomW { r(Color(hex: room.stripe), x, top + 8, 10, roomH - 22); x += 40 }
                    let wx = f % 2 == 1 ? roomX + roomW * 0.42 : roomX + roomW * 0.58
                    r(Pal.ink, wx - 4, top + 40, 88, 78); r(Pal.night, wx, top + 44, 80, 70)
                    for i in 0..<8 { r(.white, wx + CGFloat((i * 23) % 76), top + 48 + CGFloat((i * 31) % 62), 4, 4) }
                    r(Color(hex: 0xF4F8FF), wx, top + 106, 80, 8); r(Pal.ink, wx + 38, top + 44, 4, 70)
                    r(Pal.brown, roomX, top + roomH - 14, roomW, 14); r(Color(hex: 0x7A4428), roomX, top + roomH - 14, roomW, 3)
                }
                r(Color(hex: 0xF4F8FF), -20, roofH + roomH * CGFloat(floors) + 8, houseW + 40, 12)
            }
            // Tap the empty part of a room to go inside. Room name + the pets in there.
            ForEach(0..<floors, id: \.self) { f in
                Tap(action: { onZoom(f); Audio.shared.play(.tap) }) {
                    ZStack(alignment: .topLeading) {
                        Color.clear.contentShape(Rectangle())
                        HStack(spacing: 6) {
                            Txt("\(rooms[f].emoji) \(rooms[f].title)  🔍", 26)
                            ForEach(game.petsIn(f).prefix(3)) { Px($0.kind.sprite, 34) }
                            if f == 0, let m = game.mainPet { Px(m.kind.sprite, 34) }
                        }
                        .padding(.horizontal, 10).padding(.vertical, 4).panel(.white.opacity(0.9)).padding(8)
                    }
                    .frame(width: roomW, height: roomH - 8)
                }
                .position(x: roomX + roomW / 2, y: roomTop(f, floors) + 8 + (roomH - 8) / 2)
            }
            ForEach(game.s.placed.filter { $0.floor < floors }.sorted { order($0) < order($1) }, id: \.id) { p in
                PlacedItem(game: game, p: p, floors: floors, isSelected: p.id == selected) { selected = p.id }
            }
        }
    }

    private func order(_ p: Placed) -> Int { (p.item.spot == .rug ? 0 : 1) * 2 + (p.id == selected ? 1 : 0) }
}

private struct PlacedItem: View {
    let game: GameState
    let p: Placed
    let floors: Int
    let isSelected: Bool
    let select: () -> Void
    @State private var last: CGSize = .zero

    var body: some View {
        let img = Sprites.named(p.item.sprite)
        let h = img.size.height * pixel
        let wallRange = max(10, roomH - 60 - h)
        let top: CGFloat = switch p.item.spot {
        case .floor: floorLine(p.floor, floors) - h
        case .rug: floorLine(p.floor, floors) - h + 10
        case .wall: roomTop(p.floor, floors) + 16 + p.y * wallRange
        }
        Px(img, h)
            .overlay { if isSelected { RoundedRectangle(cornerRadius: 4).stroke(Pal.gold, lineWidth: 4) } }
            .onTapGesture(perform: select)
            .gesture(DragGesture()
                .onChanged { v in
                    select()
                    let dx = v.translation.width - last.width, dy = v.translation.height - last.height
                    last = v.translation
                    game.move(p.id, x: p.x + dx / roomW, y: p.y + dy / wallRange)
                }
                .onEnded { _ in last = .zero })
            .position(x: roomX + p.x * roomW, y: top + h / 2)
    }
}

// MARK: - Snacks

struct SnacksView: View {
    let game: GameState
    var body: some View {
        VStack(spacing: 8) {
            Txt("Snacks give you energy ⚡ for working.", 17, .white, align: .center)
            let snacks = Food.allCases.filter { game.s.food[$0, default: 0] > 0 }
            let cookies = Cookie.allCases.filter { game.s.cookies[$0, default: 0] > 0 }
            if snacks.isEmpty && cookies.isEmpty {
                VStack(spacing: 6) {
                    Txt("No snacks! 😮", 20)
                    Txt("Bake cookies in the Bakery, or buy food in the Shop.", 15, align: .center)
                }
                .padding(16).frame(maxWidth: .infinity).panel()
            }
            ForEach(snacks, id: \.self) { f in row(f.sprite, "\(f.title) ×\(game.s.food[f, default: 0])", "+\(f.energy) energy") { game.eat(f) } }
            ForEach(cookies, id: \.self) { c in row(c.sprite, "\(c.title) ×\(game.s.cookies[c, default: 0])", "+\(c.energy) energy (Santa needs cookies too!)") { game.eat(c) } }
        }
    }

    private func row(_ sprite: String, _ title: String, _ energy: String, _ eat: @escaping () -> Void) -> some View {
        HStack(spacing: 10) {
            Px(sprite, 44)
            VStack(alignment: .leading) { Txt(title, 17); Txt(energy, 13, Pal.darkGreen) }
            Spacer()
            Btn("Eat", Pal.red, size: 16, width: 80, action: eat)
        }
        .padding(8).panel(.white)
    }
}

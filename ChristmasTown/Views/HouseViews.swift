import SwiftUI

private let houseW: CGFloat = 800
private let roofH: CGFloat = 90
private let roomH: CGFloat = 230
private let roomX: CGFloat = 16
private let roomW: CGFloat = houseW - 32
private let pixel: CGFloat = 5
private let houseH: CGFloat = roofH + roomH * 2 + 16

private func roomTop(_ floor: Int) -> CGFloat { roofH + CGFloat(1 - floor) * roomH }   // upstairs (1) is on top
private func floorLine(_ floor: Int) -> CGFloat { roomTop(floor) + roomH - 14 }

// MARK: - Decorate (the two-story house)

struct DecorateView: View {
    let game: GameState
    @State private var selected: Int?
    @State private var targetFloor = 0

    var body: some View {
        let k: CGFloat = 406 / houseW
        VStack(spacing: 8) {
            House(game: game, selected: $selected)
                .frame(width: houseW, height: houseH)
                .scaleEffect(k)
                .frame(width: houseW * k, height: houseH * k)
            Txt("Drag things to move them. Tap one to pick it.", 14, .white)

            ScrollView {
                VStack(spacing: 8) {
                    if let sel = game.s.placed.first(where: { $0.id == selected }) {
                        HStack(spacing: 6) {
                            Txt(sel.item.title, 16)
                            Spacer()
                            Btn(sel.floor == 0 ? "⬆ Up" : "⬇ Down", Pal.blue, size: 14, width: 90) { game.switchFloor(sel.id) }
                            Btn("📦 Away", Pal.brown, size: 14, width: 100) { game.putAway(sel.id); selected = nil }
                        }
                        .padding(8).panel(Pal.paleGold)
                    }
                    HStack(spacing: 8) {
                        Txt("Storage. Place on:", 16)
                        ForEach([(0, "Downstairs"), (1, "Upstairs")], id: \.0) { f, label in
                            Tap(action: { targetFloor = f }) {
                                Txt(label, 14, targetFloor == f ? .white : Pal.ink).padding(.horizontal, 8).padding(.vertical, 3).panel(targetFloor == f ? Pal.green : .white)
                            }
                        }
                        Spacer()
                    }
                    let stored = Item.allCases.filter { game.available($0) > 0 }
                    if stored.isEmpty { Txt("Everything is out! Buy more in the Shop 🛍️", 14) }
                    ForEach(stored, id: \.self) { i in
                        HStack(spacing: 8) {
                            Px(i.sprite, 38).frame(width: 44, height: 44)
                            Txt("\(i.title) ×\(game.available(i))", 15)
                            Spacer()
                            Btn("Place", Pal.green, size: 14, width: 80) { selected = game.place(i, floor: targetFloor) }
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

    var body: some View {
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
                r(Pal.ink, 0, roofH, houseW, roomH * 2 + 16)
                for f in 0...1 {
                    let top = roomTop(f)
                    r(f == 1 ? Color(hex: 0xF6D7E3) : Color(hex: 0xE3F0D8), roomX, top + 8, roomW, roomH - 8)
                    var x = roomX
                    while x < roomX + roomW { r(f == 1 ? Color(hex: 0xEFC3D3) : Color(hex: 0xD3E6C4), x, top + 8, 10, roomH - 22); x += 40 }
                    let wx = f == 1 ? roomX + roomW * 0.42 : roomX + roomW * 0.58
                    r(Pal.ink, wx - 4, top + 40, 88, 78); r(Pal.night, wx, top + 44, 80, 70)
                    for i in 0..<8 { r(.white, wx + CGFloat((i * 23) % 76), top + 48 + CGFloat((i * 31) % 62), 4, 4) }
                    r(Color(hex: 0xF4F8FF), wx, top + 106, 80, 8); r(Pal.ink, wx + 38, top + 44, 4, 70)
                    r(Pal.brown, roomX, top + roomH - 14, roomW, 14); r(Color(hex: 0x7A4428), roomX, top + roomH - 14, roomW, 3)
                }
                r(Color(hex: 0xF4F8FF), -20, roofH + roomH * 2 + 8, houseW + 40, 12)
            }
            ForEach(game.s.placed.sorted { order($0) < order($1) }, id: \.id) { p in
                PlacedItem(game: game, p: p, isSelected: p.id == selected) { selected = p.id }
            }
        }
    }

    private func order(_ p: Placed) -> Int { (p.item.spot == .rug ? 0 : 1) * 2 + (p.id == selected ? 1 : 0) }
}

private struct PlacedItem: View {
    let game: GameState
    let p: Placed
    let isSelected: Bool
    let select: () -> Void
    @State private var last: CGSize = .zero

    var body: some View {
        let img = Sprites.named(p.item.sprite)
        let h = img.size.height * pixel
        let wallRange = max(10, roomH - 60 - h)
        let top: CGFloat = switch p.item.spot {
        case .floor: floorLine(p.floor) - h
        case .rug: floorLine(p.floor) - h + 10
        case .wall: roomTop(p.floor) + 16 + p.y * wallRange
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

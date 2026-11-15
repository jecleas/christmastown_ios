import SwiftUI

/// The main screen: your living room with the activity icons down both sides.
struct HubView: View {
    let game: GameState
    @State private var confirmSleep = false

    var body: some View {
        let s = game.s
        VStack(spacing: 8) {
            // Profile card + money, like the reference game
            HStack(spacing: 8) {
                Tap(action: { game.showCreator = true }) {
                    HStack(spacing: 8) {
                        ElfPx(look: s.look, height: 66).offset(y: 10).frame(width: 50, height: 50, alignment: .top)
                            .background(Color(hex: 0xBFE9F5)).clipShape(RoundedRectangle(cornerRadius: 8))
                        VStack(alignment: .leading, spacing: 3) {
                            Txt("\(s.name) ✏️", 18, lines: 1)
                            HStack(spacing: 6) { Tag("Day \(s.day)", Pal.night, size: 12); Tag("Lv \(game.level)", Pal.green, size: 12) }
                            GeometryReader { g in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3).fill(Color(hex: 0xD5DBE6))
                                    RoundedRectangle(cornerRadius: 3).fill(s.paidToday ? Pal.green : Pal.gold)
                                        .frame(width: g.size.width * (s.paidToday ? 1 : CGFloat(game.jobsDone) / CGFloat(max(1, s.jobs.count))))
                                }
                            }
                            .frame(height: 10)
                        }
                    }
                    .padding(6).frame(maxWidth: .infinity, alignment: .leading).panel()
                }
                VStack(alignment: .trailing, spacing: 4) { MoneyChip(game: game); EnergyChip(game: game) }
                VStack(spacing: 4) {
                    toggle(s.musicOn ? "🎵" : "🔇", s.musicOn) { game.toggleMusic() }
                    toggle(s.soundOn ? "🔔" : "🔕", s.soundOn) { game.toggleSound() }
                }
            }

            ZStack(alignment: .top) {
                LivingRoom(game: game)
                HStack(alignment: .top) {
                    VStack(spacing: 6) { ForEach(Place.allCases.filter { $0.side == .left }) { PlaceIcon(game: game, place: $0) } }
                    Spacer()
                    VStack(spacing: 6) { ForEach(Place.allCases.filter { $0.side == .right }) { PlaceIcon(game: game, place: $0) } }
                }
                .padding(6)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))

            HStack(spacing: 10) {
                Btn(s.paidToday ? "📋 Jobs ✅" : "📋 Jobs \(game.jobsDone)/\(s.jobs.count)", s.paidToday ? Pal.green : Pal.red, size: 20) { game.showJobs = true }
                Btn("💤 Sleep", Pal.night, size: 20) { if s.paidToday { game.sleep() } else { confirmSleep = true } }
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 8)
        .overlay {
            if confirmSleep {
                ZStack {
                    Color.black.opacity(0.5)
                    VStack(spacing: 10) {
                        Txt("😴 Go to sleep?", 24)
                        Txt("You haven't finished Santa's jobs yet, so you WON'T get paid today.", 16, Pal.red, align: .center)
                        HStack(spacing: 10) {
                            Btn("Keep working", Pal.green, size: 16) { confirmSleep = false }
                            Btn("Sleep anyway", Pal.night, size: 16) { confirmSleep = false; game.sleep() }
                        }
                    }
                    .padding(18).frame(width: 360).panel()
                }
            }
        }
    }

    private func toggle(_ icon: String, _ on: Bool, _ action: @escaping () -> Void) -> some View {
        Tap(action: action) { Txt(icon, 14).frame(width: 28, height: 24).panel(on ? .white : Color(hex: 0xD5DBE6)) }
    }
}

/// "!" = something to do, "✓" = done, "🔒" = locked, "New" = decorations waiting, numbers = unread messages.
@MainActor func placeBadge(_ game: GameState, _ p: Place) -> String? {
    let s = game.s
    func job(_ k: JobKind, unlock: Int) -> String? {
        if game.level < unlock { return "🔒" }
        if s.paidToday || s.jobs.first(where: { $0.kind == k })?.finished == true { return "✓" }
        return "!"
    }
    switch p {
    case .greenhouse: return s.plots.contains { [1, 3].contains($0.stage(game.now)) } ? "!" : nil
    case .bakery: return job(.bake, unlock: 1)
    case .stable: return job(.reindeer, unlock: 1)
    case .workshop: return job(.toys, unlock: 1)
    case .santaList: return job(.sortList, unlock: 2)
    case .sleigh: return job(.deliver, unlock: 3)
    case .decorate: return Item.allCases.contains { game.available($0) > 0 } ? "New" : nil
    case .friends: return npcs.contains { !s.talkedToday.contains($0.name) } ? "!" : nil
    case .phone:
        let unread = ([groupThread] + game.met).map(game.unread).reduce(0, +)
        return unread > 0 ? "\(unread)" : game.groupHasNews ? "!" : nil
    default: return nil
    }
}

struct PlaceIcon: View {
    let game: GameState
    let place: Place

    var body: some View {
        Tap(action: { if place == .closet { game.showCreator = true } else { game.go(place) } }) {
            VStack(spacing: 2) {
                ZStack(alignment: .topTrailing) {
                    picture
                        .frame(width: 56, height: 56)
                        .background(RoundedRectangle(cornerRadius: 11).fill(.white.opacity(0.92)))
                        .padding(3)
                        .background(RoundedRectangle(cornerRadius: 14).fill(place.color))
                    if let b = placeBadge(game, place) {
                        Txt(b, 12, .white).padding(.horizontal, 5).padding(.vertical, 1)
                            .background(RoundedRectangle(cornerRadius: 8).fill(b == "✓" ? Pal.green : b == "🔒" ? Pal.grey : Pal.red))
                            .offset(x: 6, y: -4)
                    }
                }
                Txt(place.title, 12, .white, align: .center, lines: 1)
                    .padding(.horizontal, 4).background(RoundedRectangle(cornerRadius: 5).fill(Pal.ink.opacity(0.75)))
            }
            .frame(width: 76)
        }
    }

    @ViewBuilder private var picture: some View {
        switch place {
        case .closet: ElfPx(look: game.s.look, height: 60).offset(y: 6).frame(width: 50, height: 50, alignment: .top).clipped()
        case .friends: ElfPx(look: npcs[1].look, height: 60).offset(y: 6).frame(width: 50, height: 50, alignment: .top).clipped()
        case .stable: Px("reindeer", 34)
        case .sleigh: Px("sleigh", 28)
        case .santaList: Px("santa", 50)
        case .phone: Px("phone", 46)
        default: Px(place.sprite, 42)
        }
    }
}

/// Your downstairs room, big: the decorations you placed, your elf, a reindeer buddy and a table of goodies.
struct LivingRoom: View {
    let game: GameState
    private let pixel: CGFloat = 3.2

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let floorY = h * 0.66
            ZStack(alignment: .topLeading) {
                Canvas { ctx, size in
                    ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(hex: 0xE3F0D8)))
                    var x: CGFloat = 0
                    while x < w { ctx.fill(Path(CGRect(x: x, y: 0, width: 12, height: floorY)), with: .color(Color(hex: 0xD3E6C4))); x += 44 }
                    let wx = w / 2 - 60, wy: CGFloat = 30
                    ctx.fill(Path(CGRect(x: wx - 5, y: wy - 5, width: 130, height: 110)), with: .color(Pal.ink))
                    ctx.fill(Path(CGRect(x: wx, y: wy, width: 120, height: 100)), with: .color(Pal.night))
                    for i in 0..<12 {
                        let sy = wy + CGFloat((Int(Double(i * 31) + game.now * 25)) % 96)
                        ctx.fill(Path(CGRect(x: wx + CGFloat((i * 37) % 114), y: sy, width: 4, height: 4)), with: .color(.white))
                    }
                    ctx.fill(Path(CGRect(x: wx, y: wy + 88, width: 120, height: 12)), with: .color(.white))
                    ctx.fill(Path(CGRect(x: wx + 57, y: wy, width: 6, height: 100)), with: .color(Pal.ink))
                    ctx.fill(Path(CGRect(x: 0, y: floorY, width: size.width, height: size.height - floorY)), with: .color(Pal.brown))
                    var y = floorY + 18
                    while y < h { ctx.fill(Path(CGRect(x: 0, y: y, width: size.width, height: 3)), with: .color(Color(hex: 0x7A4428))); y += 22 }
                }

                ForEach(game.s.placed.filter { $0.floor == 0 }.sorted { ($0.item.spot == .rug ? 0 : 1) < ($1.item.spot == .rug ? 0 : 1) }, id: \.id) { p in
                    let img = Sprites.named(p.item.sprite)
                    let ih = img.size.height * pixel
                    let cx = 14 + p.x * (w - 28)
                    let top: CGFloat = switch p.item.spot {
                    case .floor: floorY - ih + 6
                    case .rug: floorY + 8
                    case .wall: 20 + p.y * max(10, floorY - 150 - ih)
                    }
                    Px(img, ih).position(x: cx, y: top + ih / 2)
                }

                // Your elf and a baby reindeer buddy
                HStack(alignment: .bottom, spacing: 0) {
                    ElfPx(look: game.s.look, height: 200).bob(4, 0.9)
                    Px(Sprites.reindeer(rudolph: true), 54).bob(3, 0.65)
                }
                .position(x: w / 2, y: floorY + 70 - 100)

                // Table of today's goodies
                VStack(spacing: 0) {
                    let goodies = Cookie.allCases.flatMap { c in Array(repeating: c.sprite, count: min(game.s.cookies[c, default: 0], 3)) }
                        + Toy.allCases.flatMap { t in Array(repeating: t.sprite, count: min(game.s.toys[t, default: 0], 2)) }
                    HStack(alignment: .bottom, spacing: 2) {
                        if goodies.isEmpty {
                            Txt("Bake cookies & make toys!", 13, .white).padding(.horizontal, 6).background(RoundedRectangle(cornerRadius: 5).fill(Pal.ink.opacity(0.6)))
                        }
                        ForEach(Array(goodies.prefix(7).enumerated()), id: \.offset) { _, g in Px(g, 34) }
                    }
                    .frame(height: 38, alignment: .bottom)
                    Color.clear.frame(width: 244, height: 10).panel(Color(hex: 0xC98B5E), radius: 5)
                }
                .position(x: w / 2, y: h - 32)
            }
        }
    }
}

import SwiftUI

// Port of the Android Stable.kt. Keep the two in sync.

// ======================================================================
// MARK: - Stable: tap a reindeer to open its close-up care screen
// ======================================================================

struct StableView: View {
    let game: GameState
    @State private var caring: String?

    var body: some View {
        if let name = caring, game.reindeer.contains(name) {
            ReindeerCareView(game: game, name: name) { caring = nil }
        } else {
            VStack(spacing: 10) {
                JobChip(game: game, kind: .reindeer)
                HStack(spacing: 4) {
                    Px("carrot", 24)
                    Txt("×\(game.s.crops[.carrot, default: 0])  ·  🛷 Team \(game.teamPower)/\(game.sleighTeam.count) happy  ·  Tap a reindeer!", 14)
                }
                .padding(.horizontal, 10).padding(.vertical, 4).panel()
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(128), spacing: 8), count: 3), spacing: 8) {
                        ForEach(game.reindeer, id: \.self) { r in
                            Tap(action: { caring = r; Audio.shared.play(.sleighBells) }) { ReindeerTile(game: game, name: r) }
                        }
                    }
                }
            }
        }
    }
}

private struct ReindeerTile: View {
    let game: GameState
    let name: String
    var body: some View {
        let s = game.s
        let fed = s.fed.contains(name), brushed = s.brushed.contains(name), washed = s.washed.contains(name)
        VStack(spacing: 2) {
            ReindeerPx(name: name, decos: game.decosOn(name), height: 62)
                .bob(fed && brushed ? 5 : 2, fed && brushed ? 0.4 : 0.9)
                .frame(height: 72, alignment: .bottom)
            Txt(name, 15, lines: 1)
            Txt((fed ? "🥕" : "▫️") + (brushed ? "✨" : "▫️") + (washed ? "🛁" : "▫️") + (game.sleighTeam.contains(name) ? "🛷" : ""), 12)
        }
        .padding(6).frame(width: 128).panel(fed && brushed ? Pal.paleGreen : Pal.cream)
    }
}

private enum CareTool: String, CaseIterable { case feed = "🥕 Feed", brush = "✨ Brush", wash = "🛁 Wash", decorate = "🎀 Dress up", sleigh = "🛷 Sleigh" }
private enum WashStep { case idle, scrub, rinse }

private let rubDistance: CGFloat = 450   // how far you rub to finish brushing
private let bubblesNeeded = 16
private let reindeerLines = [
    "*sniffs your pocket for carrots*", "*nuzzles you* 🥰", "Snort! (that means thank you)", "*does a little prance*",
    "*sneezes glitter* ✨", "I can fly, you know. Just saying.", "*wiggles ears*", "Is it Christmas yet? Is it? IS IT?",
]

/// Full-screen close-up of one reindeer: feed, brush, wash, dress up and hitch to the sleigh.
private struct ReindeerCareView: View {
    let game: GameState
    let name: String
    let onBack: () -> Void
    @State private var tool: CareTool = .feed
    @State private var bites = -1        // -1 = no carrot out
    @State private var rubbed: CGFloat = 0
    @State private var wash = WashStep.idle
    @State private var bubbles: [CGPoint] = []
    @State private var say: String?
    @State private var drops: CGPoint?
    @State private var last: CGPoint?

    var body: some View {
        let s = game.s
        let fed = s.fed.contains(name), brushed = s.brushed.contains(name), washed = s.washed.contains(name)
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Btn("🦌 All", Pal.brown, size: 15, width: 96, action: onBack)
                Txt(name == "Rudolph" ? "\(name) 🔴" : name, 26, .white)
                Spacer(minLength: 0)
                Txt((fed ? "🥕✅" : "🥕") + (brushed ? " ✨✅" : " ✨") + (washed ? " 🛁✅" : " 🛁"), 14, .white)
            }

            // The stall with the big reindeer
            ZStack(alignment: .topLeading) {
                Canvas { ctx, size in
                    ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(hex: 0x6C4A3A)))
                    var x: CGFloat = 0
                    while x < size.width { ctx.fill(Path(CGRect(x: x, y: 0, width: 4, height: size.height * 0.72)), with: .color(Color(hex: 0x5E3E30))); x += 34 }
                    ctx.fill(Path(CGRect(x: 0, y: size.height * 0.72, width: size.width, height: size.height * 0.28)), with: .color(Color(hex: 0xE8C77A)))
                    for i in 0..<30 { ctx.fill(Path(CGRect(x: CGFloat((i * 53) % 400), y: size.height * 0.74 + CGFloat((i * 29) % 70), width: 14, height: 2)), with: .color(Color(hex: 0xC9A050))) }
                    if tool == .wash && wash != .idle { ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(hex: 0x7EC8F0, opacity: 0.25))) }
                }
                ReindeerPx(name: name, decos: game.decosOn(name), height: 200)
                    .bob(fed && brushed ? 6 : 2, fed && brushed ? 0.42 : 0.9)
                    .frame(width: 406, height: 274, alignment: .bottom)
                if tool == .brush && !brushed && rubbed > 0 {
                    ForEach(0..<min(9, Int(rubbed / 50)), id: \.self) { i in
                        Txt("✨", 20).position(x: CGFloat(80 + (i * 41) % 260), y: CGFloat(70 + (i * 37) % 150))
                    }
                }
                ForEach(Array(bubbles.enumerated()), id: \.offset) { _, b in
                    Circle().fill(.white.opacity(0.6)).overlay(Circle().stroke(Color(hex: 0x9BD3FF), lineWidth: 2)).frame(width: 32, height: 32).position(b)
                }
                if let d = drops { Txt("🚿", 40).position(x: d.x, y: d.y - 40) }
                if bites >= 0 {
                    Tap(action: {
                        bites += 1
                        Audio.shared.play(.munch)
                        if bites >= 3 { game.feed(name); bites = -1; say = "Crunch crunch! Best. Carrot. EVER. 🥕" }
                    }) { Px("carrot", CGFloat(80 - bites * 20)) }
                    .position(x: 60, y: 150)
                }
                if let say {
                    Txt(say, 15, align: .center).padding(.horizontal, 10).padding(.vertical, 6).panel(.white)
                        .frame(width: 406).padding(.top, 8)
                }
            }
            .frame(width: 406, height: 300)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Pal.ink, lineWidth: 3))
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 2)
                .onChanged { v in
                    let d = last.map { hypot(v.location.x - $0.x, v.location.y - $0.y) } ?? 0
                    last = v.location
                    rub(at: v.location, distance: d)
                }
                .onEnded { _ in last = nil; drops = nil })
            .simultaneousGesture(TapGesture().onEnded {
                if tool != .feed || bites < 0 { say = reindeerLines.randomElement(); Audio.shared.play(.sleighBells) }
            })

            // Tools
            HStack(spacing: 5) {
                ForEach(CareTool.allCases, id: \.self) { t in
                    Tap(action: { tool = t; bites = -1; Audio.shared.play(.tap) }) {
                        Txt(t.rawValue, 13, tool == t ? .white : Pal.ink, align: .center).padding(.vertical, 7).frame(maxWidth: .infinity)
                            .panel(tool == t ? Pal.red : .white)
                    }
                }
            }

            VStack(spacing: 8) { toolPanel(fed: fed, brushed: brushed, washed: washed) }
                .padding(12).frame(maxWidth: .infinity).panel()
        }
    }

    private func rub(at p: CGPoint, distance: CGFloat) {
        switch tool {
        case .brush:
            guard !game.s.brushed.contains(name) else { return }
            let before = rubbed
            rubbed += distance
            if Int(rubbed / 90) > Int(before / 90) { Audio.shared.play(.tap) }
            if rubbed >= rubDistance { game.brush(name); say = "Ooh, that's the spot! ✨" }
        case .wash:
            switch wash {
            case .scrub:
                if bubbles.last.map({ hypot($0.x - p.x, $0.y - p.y) > 26 }) ?? true {
                    bubbles.append(p); if bubbles.count % 3 == 0 { Audio.shared.play(.pop) }
                    if bubbles.count >= bubblesNeeded { wash = .rinse; say = "So bubbly! Now rinse with the water 🚿" }
                }
            case .rinse:
                drops = p
                let before = bubbles.count
                bubbles.removeAll { hypot($0.x - p.x, $0.y - p.y) < 44 }
                if bubbles.count < before { Audio.shared.play(.tap) }
                if bubbles.isEmpty { wash = .idle; drops = nil; game.wash(name); say = "*shakes like a dog* Splish splash! 💦" }
            case .idle: break
            }
        default: break
        }
    }

    @ViewBuilder private func toolPanel(fed: Bool, brushed: Bool, washed: Bool) -> some View {
        let s = game.s
        switch tool {
        case .feed:
            if fed { Txt("\(name) is full and happy! 🥕✅", 17, Pal.darkGreen) }
            else if bites >= 0 { Txt("Tap the carrot! 🥕 (\(bites)/3 bites)", 17, Pal.darkGreen) }
            else {
                Txt("Carrots: \(s.crops[.carrot, default: 0])", 15)
                Btn("Give a carrot 🥕 (⚡2)", Pal.orange, size: 17, width: 260) {
                    if s.crops[.carrot, default: 0] <= 0 { game.feed(name) } else if game.hasEnergy(2) { bites = 0 }
                }
            }
        case .brush:
            if brushed { Txt("\(name) is super shiny! ✨", 17, Pal.darkGreen) }
            else {
                Txt("Rub \(name) with your finger to brush and pet! (⚡2)", 16, align: .center)
                Bar(frac: rubbed / rubDistance, color: Pal.gold)
            }
        case .wash:
            if washed { Txt("\(name) is squeaky clean! 🛁✅", 17, Pal.darkGreen) }
            else if wash == .idle {
                Txt("A bubble bath makes reindeer extra happy!", 15, align: .center)
                Btn("🧽 Start the bath (⚡2)", Pal.blue, size: 17, width: 260) {
                    if game.hasEnergy(2) { bubbles = []; wash = .scrub; say = "Scrub scrub! Rub to make bubbles 🧽" }
                }
            } else if wash == .scrub {
                Txt("Rub to make bubbles! 🧽", 16)
                Bar(frac: CGFloat(bubbles.count) / CGFloat(bubblesNeeded), color: Color(hex: 0x9BD3FF))
            } else {
                Txt("Drag the water over the bubbles to rinse! 🚿", 16, align: .center)
                Txt("\(bubbles.count) bubbles left", 14)
            }
        case .decorate:
            Txt("Tap to put on or take off. They show everywhere \(name) goes!", 14, align: .center)
            HStack(spacing: 6) {
                ForEach(Deco.allCases, id: \.self) { d in
                    let on = game.decosOn(name).contains(d)
                    Tap(action: { game.toggleDeco(name, d) }) {
                        VStack(spacing: 2) {
                            Txt(d.emoji, 22)
                            Txt(d.title, 11, align: .center, lines: 2)
                            Txt(!s.decos.contains(d) ? money(d.price) : on ? "On ✨" : "Put on", 11, !s.decos.contains(d) ? Pal.red : Pal.darkGreen)
                        }
                        .padding(4).frame(maxWidth: .infinity).panel(on ? Pal.paleGold : .white, border: on ? Pal.red : Pal.ink)
                    }
                }
            }
        case .sleigh:
            let inTeam = s.team.filter { game.reindeer.contains($0) }.contains(name)
            Txt("Sleigh team: " + game.sleighTeam.map { s.fed.contains($0) && s.brushed.contains($0) ? "\($0) 😊" : "\($0) 😐" }.joined(separator: ", "), 14, align: .center)
            Txt("Fed + brushed team reindeer steer the sleigh better and fly faster through clouds!", 13, Pal.brown, align: .center)
            Btn(inTeam ? "Unhitch \(name)" : "🛷 Hitch \(name) to the sleigh", inTeam ? Pal.brown : Pal.green, size: 16) { game.toggleTeam(name) }
        }
    }
}

/// A simple progress bar.
struct Bar: View {
    let frac: CGFloat
    let color: Color
    var width: CGFloat = 260
    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 4).fill(.white)
            Rectangle().fill(color).frame(width: width * min(1, max(0, frac)))
        }
        .frame(width: width, height: 14)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Pal.ink, lineWidth: 2))
    }
}

/// Little tabs at the top of a place that has more than one thing to do.
struct Tabs<T: Hashable>: View {
    let options: [T]
    let selected: T
    let label: (T) -> String
    var color: Color = Pal.red
    let onPick: (T) -> Void
    var body: some View {
        HStack(spacing: 6) {
            ForEach(options, id: \.self) { o in
                Tap(action: { onPick(o); Audio.shared.play(.tap) }) {
                    Txt(label(o), 15, o == selected ? .white : Pal.ink, align: .center).padding(.vertical, 7).frame(maxWidth: .infinity)
                        .panel(o == selected ? color : .white)
                }
            }
        }
    }
}

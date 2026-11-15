import SwiftUI
import Combine
import Observation

// Port of the Android MoreGames.kt (Snow Park: Town Tree + snowball fight). Keep the two in sync.

private enum ParkGame: String, CaseIterable { case tree = "🎄 Town Tree", snowball = "❄️ Snowball Fight" }

struct ParkView: View {
    let game: GameState
    @State private var tab: ParkGame?
    @State private var playing = false

    var body: some View {
        let current = tab ?? (game.s.jobs.contains { $0.kind == .tree && !$0.finished } ? .tree : .snowball)
        VStack(spacing: 8) {
            if !playing { Tabs(options: ParkGame.allCases, selected: current, label: { $0.rawValue }, color: Pal.blue) { tab = $0 } }
            switch current {
            case .tree: TreeView(game: game, playing: $playing)
            case .snowball: SnowballView(game: game, playing: $playing)
            }
        }
    }
}

// MARK: - Town Tree

private enum TreePhase: Int, Comparable {
    case look, hang, tinsel, star, lights, done
    static func < (a: TreePhase, b: TreePhase) -> Bool { a.rawValue < b.rawValue }
}
private let ornamentColors: [Color] = [0xE5394B, 0xFFCC4D, 0x3D6FD6, 0x9B6BE0, 0xFF8FB0, 0xF4F8FF].map { Color(hex: $0) }
private let treeW: CGFloat = 400, treeH: CGFloat = 400
private let treeTop = CGPoint(x: 200, y: 40)
private func insideTree(_ x: CGFloat, _ y: CGFloat) -> Bool { (60...330).contains(y) && abs(x - 200) < (y - 40) * 0.55 }
private let tinselRub: CGFloat = 900

private func drawOrnament(_ ctx: inout GraphicsContext, _ kind: Int, _ color: Color, _ c: CGPoint) {
    switch kind {
    case 0: // ball
        ctx.fill(Path(CGRect(x: c.x - 3, y: c.y - 15, width: 6, height: 5)), with: .color(Color(hex: 0xC9CED8)))
        ctx.fill(Path(ellipseIn: CGRect(x: c.x - 12, y: c.y - 12, width: 24, height: 24)), with: .color(Pal.ink))
        ctx.fill(Path(ellipseIn: CGRect(x: c.x - 10, y: c.y - 10, width: 20, height: 20)), with: .color(color))
        ctx.fill(Path(ellipseIn: CGRect(x: c.x - 7, y: c.y - 7, width: 6, height: 6)), with: .color(.white.opacity(0.6)))
    case 1: // bell
        var p = Path()
        p.move(to: CGPoint(x: c.x - 11, y: c.y + 8))
        p.addCurve(to: CGPoint(x: c.x + 11, y: c.y + 8), control1: CGPoint(x: c.x - 9, y: c.y - 14), control2: CGPoint(x: c.x + 9, y: c.y - 14))
        p.closeSubpath()
        ctx.fill(p, with: .color(color)); ctx.stroke(p, with: .color(Pal.ink), lineWidth: 2)
        ctx.fill(Path(ellipseIn: CGRect(x: c.x - 3, y: c.y + 7, width: 6, height: 6)), with: .color(Pal.ink))
    default: // candy cane
        var hook = Path()
        hook.addArc(center: CGPoint(x: c.x, y: c.y - 9), radius: 8, startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
        hook.addLine(to: CGPoint(x: c.x + 8, y: c.y + 14))
        ctx.stroke(hook, with: .color(Pal.ink), lineWidth: 7)
        ctx.stroke(hook, with: .color(color), lineWidth: 4)
    }
}

private struct TreeView: View {
    let game: GameState
    @Binding var playing: Bool
    @State private var phase = TreePhase.look
    @State private var ornaments: [Ornament]?
    @State private var dragging: Ornament?
    @State private var tinsel: CGFloat = 0
    @State private var star: CGPoint?
    @State private var lightsOn: Bool?
    @State private var steps = DragSteps()

    var body: some View {
        let orn = ornaments ?? game.s.townTree
        let lit = lightsOn ?? !game.s.townTree.isEmpty
        let job = game.s.jobs.first { $0.kind == .tree }
        VStack(spacing: 8) {
            if job != nil { JobChip(game: game, kind: .tree) }
            Txt(title, 17, .white, align: .center)
            ZStack(alignment: .bottomTrailing) {
                Canvas { ctx, size in draw(&ctx, size, orn, lit) }
                    .contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance: 2)
                        .onChanged { v in
                            let start = steps.last == nil
                            let d = steps.step(v)
                            onDrag(start: start, at: start ? v.startLocation : v.location, d: d)
                        }
                        .onEnded { _ in steps.last = nil; onEnd() })
                if phase == .lights {
                    Btn("💡 Switch!", Pal.red, size: 18, width: 140) {
                        lightsOn = true; phase = .done
                        game.finishTree(ornaments ?? [])
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { phase = .look; ornaments = nil; lightsOn = nil; star = nil; playing = false }
                    }
                    .padding(12)
                }
                if phase == .done { Txt("🎉 Hooray! 🎉", 26, .white).bob(8, 0.3).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top).padding(.top, 6) }
            }
            .frame(width: treeW, height: treeH)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Pal.ink, lineWidth: 3))

            switch phase {
            case .look:
                Btn("🎄 Decorate! (⚡5)", Pal.green, size: 20, width: 240) {
                    if game.spend(5) { ornaments = []; tinsel = 0; star = nil; lightsOn = false; phase = .hang; playing = true }
                }
            case .done: EmptyView()
            default:
                Btn("✖ Stop", Pal.grey, size: 14, width: 110) { ornaments = nil; star = nil; lightsOn = nil; phase = .look; playing = false }
            }
        }
    }

    private var title: String {
        switch phase {
        case .look: game.s.townTree.isEmpty ? "The Town Tree is bare! Let's decorate it 🎄" : "The Town Tree! Want to redecorate it?"
        case .hang: "Drag ornaments from the box onto the tree! (\(ornaments?.count ?? 0)/8)"
        case .tinsel: "Rub back and forth across the tree for tinsel!"
        case .star: "Drag the ⭐ to the top of the tree!"
        case .lights: "Tap the switch to turn on the lights! 💡"
        case .done: "WOW! The whole town is cheering! 🎉"
        }
    }

    private func onDrag(start: Bool, at: CGPoint, d: CGPoint) {
        switch phase {
        case .hang:
            if start && at.y > treeH - 60 {
                let slot = max(0, min(5, Int((at.x - 20) / 60)))
                dragging = Ornament(kind: slot % 3, color: slot, x: at.x, y: at.y)
            }
            if var o = dragging { o.x += d.x; o.y += d.y; dragging = o }
        case .tinsel:
            let before = tinsel
            tinsel += hypot(d.x, d.y)
            if Int(tinsel / 150) > Int(before / 150) { Audio.shared.play(.tap) }
            if tinsel >= tinselRub { phase = .star; game.say("Sparkly! Now drag the ⭐ to the very top!") }
        case .star:
            if start && star == nil && at.y > treeH - 70 && at.x > treeW - 90 { star = at }
            if let s = star { star = CGPoint(x: s.x + d.x, y: s.y + d.y) }
        default: break
        }
    }

    private func onEnd() {
        if phase == .hang, let o = dragging {
            if insideTree(o.x, o.y) {
                ornaments = (ornaments ?? []) + [Ornament(kind: o.kind, color: o.color, x: o.x / treeW, y: o.y / treeH)]
                Audio.shared.play(.pop)
                if (ornaments?.count ?? 0) >= 8 { phase = .tinsel; game.say("So pretty! Now rub across the tree for tinsel ✨") }
            }
            dragging = nil
        }
        if phase == .star, let s = star {
            if hypot(s.x - treeTop.x, s.y - treeTop.y) < 50 { star = treeTop; phase = .lights; Audio.shared.play(.ding); game.say("Perfect! Flip the switch for the lights 💡") }
            else { star = nil }
        }
    }

    private func draw(_ ctx: inout GraphicsContext, _ size: CGSize, _ orn: [Ornament], _ lit: Bool) {
        ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(Gradient(colors: [Pal.night, Color(hex: 0x3B4A8A)]), startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))
        ctx.fill(Path(CGRect(x: 0, y: 340, width: size.width, height: size.height - 340)), with: .color(.white))
        let layers: [(CGFloat, CGFloat, CGFloat)] = [(40, 150, 70), (100, 240, 110), (170, 335, 150)]
        let greens: [Color] = [Color(hex: 0x3FAF5A), Color(hex: 0x349A4E), Color(hex: 0x2E7D4A)]
        for (i, (top, bottom, half)) in layers.enumerated() {
            var p = Path(); p.move(to: CGPoint(x: 200, y: top)); p.addLine(to: CGPoint(x: 200 + half, y: bottom)); p.addLine(to: CGPoint(x: 200 - half, y: bottom)); p.closeSubpath()
            ctx.fill(p, with: .color(greens[i])); ctx.stroke(p, with: .color(Pal.ink), lineWidth: 3)
        }
        ctx.fill(Path(CGRect(x: 182, y: 333, width: 36, height: 30)), with: .color(Pal.ink))
        ctx.fill(Path(CGRect(x: 185, y: 335, width: 30, height: 26)), with: .color(Color(hex: 0x8A5A3A)))
        let swags = phase >= .star || (phase == .look && !game.s.townTree.isEmpty) ? 4 : Int(tinsel / tinselRub * 4)
        for i in 0..<swags {
            let y = 110 + CGFloat(i) * 55, half = 40 + CGFloat(i) * 30
            var arc = Path()
            for (k, deg) in stride(from: 20.0, through: 160.0, by: 10.0).enumerated() {
                let pt = CGPoint(x: 200 + half * cos(deg * .pi / 180), y: y + 20 * sin(deg * .pi / 180))
                if k == 0 { arc.move(to: pt) } else { arc.addLine(to: pt) }
            }
            ctx.stroke(arc, with: .color(Pal.gold), lineWidth: 5)
        }
        if lit {
            let t = game.now
            for i in 0..<26 {
                let y = 70 + CGFloat((i * 37) % 260), half = (y - 40) * 0.5
                let x = 200 + (CGFloat((i * 53) % 100) / 100 * 2 - 1) * half
                let on = (Int(t * 3.3) + i) % 3 != 0
                let col = confetti[i % confetti.count]
                if on { ctx.fill(Path(ellipseIn: CGRect(x: x - 10, y: y - 10, width: 20, height: 20)), with: .color(col.opacity(0.3))) }
                ctx.fill(Path(ellipseIn: CGRect(x: x - 5, y: y - 5, width: 10, height: 10)), with: .color(on ? col : .black.opacity(0.3)))
            }
        }
        for o in orn { drawOrnament(&ctx, o.kind, ornamentColors[o.color % ornamentColors.count], CGPoint(x: o.x * treeW, y: o.y * treeH)) }
        if let d = dragging { drawOrnament(&ctx, d.kind, ornamentColors[d.color], CGPoint(x: d.x, y: d.y)) }
        if let s = star ?? (phase == .look && !game.s.townTree.isEmpty ? treeTop : nil) {
            ctx.fill(starPath(s, 26, 11), with: .color(Pal.gold)); ctx.stroke(starPath(s, 26, 11), with: .color(Pal.ink), lineWidth: 3)
        }
        if phase == .hang {
            ctx.fill(Path(CGRect(x: 0, y: treeH - 60, width: size.width, height: 60)), with: .color(Pal.brown))
            for s in 0...5 { drawOrnament(&ctx, s % 3, ornamentColors[s], CGPoint(x: 50 + CGFloat(s) * 60, y: treeH - 30)) }
        }
        if phase == .star && star == nil {
            ctx.fill(starPath(CGPoint(x: 355, y: 360), 26, 11), with: .color(Pal.gold)); ctx.stroke(starPath(CGPoint(x: 355, y: 360), 26, 11), with: .color(Pal.ink), lineWidth: 3)
        }
    }
}

// MARK: - Snowball fight

private let roundSeconds = 30.0
private let splatLines = ["SPLAT! 😂", "Right in the hat! 🎩", "Brrr, cold! 🥶", "No fair, I wasn't ready!", "You got me! ❄️", "Snow in my ears! 😆", "My nose is a snowcone!"]
private let fortX: [CGFloat] = [70, 203, 336]
private let fortY: CGFloat = 320

/// The whole snowball fight, stepped by a timer (so the view itself stays simple).
@MainActor @Observable final class SnowballSim {
    struct Pop { var upAt = 0.0; var downAt = 0.0; var hitAt = -9.0; var line = "" }
    struct Incoming { let x: CGFloat; let y: CGFloat; let born: Double }
    struct Throw { let to: CGPoint; let born: Double; let fort: Int? }
    var running = false, over = false
    var t = 0.0
    var hits = 0, blocked = 0
    var splatUntil = -1.0
    var pops = [Pop(), Pop(), Pop()]
    var incoming: [Incoming] = []
    var throws: [Throw] = []
    var nextIncoming = 3.0
    var friends = Array(npcs.shuffled().prefix(3))

    func start(newFriends: Bool) {
        hits = 0; blocked = 0; t = 0; nextIncoming = 3; splatUntil = -1; incoming = []; throws = []; pops = [Pop(), Pop(), Pop()]
        if newFriends { friends = Array(npcs.shuffled().prefix(3)) }
        over = false; running = true
    }

    /// Returns true when the round just ended.
    func step(_ dt: Double) -> Bool {
        guard running else { return false }
        t += dt
        for i in pops.indices where t > pops[i].downAt + 0.4 + Double(i) * 0.3 && Double.random(in: 0...1) < 0.02 {
            pops[i].upAt = t; pops[i].downAt = t + 1.1 + Double.random(in: 0...0.9) - (t / roundSeconds) * 0.4
        }
        if t > nextIncoming {
            incoming.append(Incoming(x: 60 + CGFloat.random(in: 0...280), y: 100 + CGFloat.random(in: 0...320), born: t))
            nextIncoming = t + 2.2 + Double.random(in: 0...1.5)
        }
        let before = incoming.count
        incoming.removeAll { t - $0.born > 1.5 }
        if incoming.count < before { splatUntil = t + 1; Audio.shared.play(.oops) }
        throws.removeAll { th in
            guard t - th.born > 0.28 else { return false }
            if let f = th.fort, t < pops[f].downAt, t > pops[f].upAt {
                hits += 1; pops[f].hitAt = t; pops[f].line = splatLines.randomElement()!; pops[f].downAt = t + 0.6; Audio.shared.play(.pop)
            }
            return true
        }
        if t >= roundSeconds { running = false; over = true; return true }
        return false
    }

    func tap(_ p: CGPoint) {
        guard running else { return }
        if let i = incoming.firstIndex(where: { hypot($0.x - p.x, $0.y - p.y) < 30 + CGFloat(t - $0.born) * 30 }) {
            incoming.remove(at: i); blocked += 1; Audio.shared.play(.tap); return
        }
        let fort = fortX.indices.first { abs(fortX[$0] - p.x) < 55 && (fortY - 110...fortY + 10).contains(p.y) }
        throws.append(Throw(to: p, born: t, fort: fort)); Audio.shared.play(.tap)
    }
}

private struct SnowballView: View {
    let game: GameState
    @Binding var playing: Bool
    @State private var sim = SnowballSim()
    private let timer = Timer.publish(every: 1.0 / 60, on: .main, in: .common).autoconnect()

    var body: some View {
        let t = sim.t
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Tag("❄️ Hits: \(sim.hits)", Pal.blue, size: 16)
                Tag("🛡️ Blocked: \(sim.blocked)", Pal.green, size: 16)
                if sim.running { Tag("⏱ \(max(0, Int(roundSeconds - t)))", Pal.red, size: 16) }
            }
            ZStack(alignment: .topLeading) {
                Canvas { ctx, size in
                    ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(Gradient(colors: [Color(hex: 0xBFE3F7), Color(hex: 0xEAF6FF)]), startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))
                    for i in 0..<6 {
                        let r = CGFloat(50 + i * 7), c = CGPoint(x: CGFloat(i * 83), y: 275)
                        ctx.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)), with: .color(Color(hex: 0xDDEBF5)))
                    }
                    ctx.fill(Path(CGRect(x: 0, y: 270, width: size.width, height: size.height - 270)), with: .color(.white))
                }
                // friends popping up behind forts
                ForEach(Array(sim.friends.enumerated()), id: \.offset) { i, f in
                    let p = sim.pops[i]
                    let up = sim.running && t > p.upAt && t < p.downAt
                    let rise = up ? min(1, (t - p.upAt) / 0.2) : 0
                    ElfPx(look: f.look, height: 90).position(x: fortX[i], y: fortY - 40 - 70 * rise + 45)
                    if t - p.hitAt < 0.9 {
                        Txt(p.line, 13, align: .center).padding(3).frame(width: 120).panel(.white).position(x: fortX[i], y: fortY - 135)
                    }
                    if t - p.hitAt < 0.6 { Txt("💥", 34).position(x: fortX[i], y: fortY - 78) }
                }
                Canvas { ctx, _ in
                    for x in fortX {
                        ctx.fill(Path(roundedRect: CGRect(x: x - 62, y: fortY + 10, width: 124, height: 64), cornerRadius: 26), with: .color(Pal.ink))
                        ctx.fill(Path(roundedRect: CGRect(x: x - 59, y: fortY + 13, width: 118, height: 58), cornerRadius: 24), with: .color(Color(hex: 0xEAF4FB)))
                        ctx.fill(Path(roundedRect: CGRect(x: x - 59, y: fortY + 46, width: 118, height: 25), cornerRadius: 10), with: .color(Color(hex: 0xC6DDF0)))
                    }
                    for th in sim.throws {
                        let k = CGFloat(min(1, max(0, (t - th.born) / 0.28)))
                        let from = CGPoint(x: 203, y: 470)
                        let p = CGPoint(x: from.x + (th.to.x - from.x) * k, y: from.y + (th.to.y - from.y) * k - sin(k * .pi) * 60)
                        let r = 14 - 6 * k
                        ctx.fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)), with: .color(Pal.ink))
                        ctx.fill(Path(ellipseIn: CGRect(x: p.x - r + 2, y: p.y - r + 2, width: r * 2 - 4, height: r * 2 - 4)), with: .color(.white))
                    }
                    for s in sim.incoming {
                        let k = CGFloat(min(1, max(0, (t - s.born) / 1.5)))
                        let r = 10 + 40 * k
                        ctx.fill(Path(ellipseIn: CGRect(x: s.x - r - 6, y: s.y - r - 6, width: (r + 6) * 2, height: (r + 6) * 2)), with: .color(Pal.red.opacity(0.35)))
                        ctx.fill(Path(ellipseIn: CGRect(x: s.x - r, y: s.y - r, width: r * 2, height: r * 2)), with: .color(Pal.ink))
                        ctx.fill(Path(ellipseIn: CGRect(x: s.x - r + 3, y: s.y - r + 3, width: r * 2 - 6, height: r * 2 - 6)), with: .color(.white))
                    }
                    if t < sim.splatUntil {
                        let a = min(1, max(0, sim.splatUntil - t))
                        for i in 0..<9 {
                            let r = CGFloat(50 + (i * 23) % 50), c = CGPoint(x: CGFloat(120 + (i * 61) % 180), y: CGFloat(180 + (i * 47) % 160))
                            ctx.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)), with: .color(.white.opacity(0.92 * a)))
                        }
                    }
                }
                .allowsHitTesting(false)
                if t < sim.splatUntil { Txt("SPLAT! Got you! 😆", 24, Pal.blue).frame(width: 406, height: 470) }
                if !sim.running { startCard.frame(width: 406, height: 470) }
            }
            .frame(width: 406, height: 470)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Pal.ink, lineWidth: 3))
            .contentShape(Rectangle())
            .gesture(SpatialTapGesture().onEnded { sim.tap($0.location) })
        }
        .onReceive(timer) { _ in
            if sim.step(1.0 / 60) { game.snowballDone(hits: sim.hits, friends: sim.friends); playing = false }
        }
    }

    private var startCard: some View {
        VStack(spacing: 8) {
            if sim.over {
                Txt(sim.hits >= 10 ? "SNOWBALL CHAMPION! 🏆" : sim.hits >= 3 ? "Great throwing! ❄️" : "Snow way! Try again! 😄", 21, Pal.red, align: .center)
                Txt("You hit friends \(sim.hits) times and blocked \(sim.blocked) snowballs.", 15, align: .center)
            } else {
                HStack(spacing: 0) { ForEach(sim.friends) { ElfPx(look: $0.look, height: 60) } }
                Txt("\(sim.friends.map(\.name).joined(separator: ", ")) want a snowball fight!", 16, align: .center)
                Txt("Tap elves to throw. Tap snowballs flying at you to block them!", 14, Pal.brown, align: .center)
            }
            Btn(sim.over ? "Play again! (⚡3)" : "Let's go! (⚡3)", Pal.blue, size: 18, width: 220) {
                if game.spend(3) { sim.start(newFriends: sim.over); playing = true }
            }
        }
        .padding(14).frame(width: 320).panel()
    }
}

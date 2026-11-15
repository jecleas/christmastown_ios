import SwiftUI

// Port of the Android MoreGames.kt (wrapping + gingerbread house). Keep the two in sync.

let confetti: [Color] = [0xE5394B, 0x3FAF5A, 0x3D6FD6, 0xFFCC4D, 0xFF8FB0, 0x9B6BE0].map { Color(hex: $0) }

func starPath(_ c: CGPoint, _ outer: CGFloat, _ inner: CGFloat) -> Path {
    var p = Path()
    for i in 0..<10 {
        let r = i % 2 == 0 ? outer : inner
        let a = -Double.pi / 2 + Double(i) * Double.pi / 5
        let pt = CGPoint(x: c.x + r * cos(a), y: c.y + r * sin(a))
        if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
    }
    p.closeSubpath()
    return p
}

func heartPath(_ c: CGPoint, _ s: CGFloat) -> Path {
    var p = Path()
    p.move(to: CGPoint(x: c.x, y: c.y + s))
    p.addCurve(to: CGPoint(x: c.x, y: c.y - 0.5 * s), control1: CGPoint(x: c.x - 1.6 * s, y: c.y - 0.2 * s), control2: CGPoint(x: c.x - 0.8 * s, y: c.y - 1.4 * s))
    p.addCurve(to: CGPoint(x: c.x, y: c.y + s), control1: CGPoint(x: c.x + 0.8 * s, y: c.y - 1.4 * s), control2: CGPoint(x: c.x + 1.6 * s, y: c.y - 0.2 * s))
    p.closeSubpath()
    return p
}

/// Tracks a drag as small steps (SwiftUI only gives the total translation).
struct DragSteps {
    var last: CGPoint?
    mutating func step(_ v: DragGesture.Value) -> CGPoint {
        defer { last = v.location }
        guard let l = last else { return .zero }
        return CGPoint(x: v.location.x - l.x, y: v.location.y - l.y)
    }
}

// ======================================================================
// MARK: - Wrapping presents: pick a toy and paper, fold, tape, bow
// ======================================================================

private enum WrapPhase { case pick, paper, fold, tape, bow, done }
enum Paper: String, CaseIterable {
    case stripes = "Candy stripes", dots = "Green dots", stars = "Blue stars", hearts = "Pink hearts"
    var base: Color { [Color(hex: 0xE5394B), Color(hex: 0x3FAF5A), Color(hex: 0x3D6FD6), Color(hex: 0xFF8FB0)][Paper.allCases.firstIndex(of: self)!] }
    var ink: Color { [Color.white, Color(hex: 0xFFCC4D), Color.white, Color(hex: 0xE5394B)][Paper.allCases.firstIndex(of: self)!] }
}
private let bowColors: [Color] = [Color(hex: 0xFFCC4D), Color(hex: 0xE5394B), Color(hex: 0xF4F8FF), Color(hex: 0x9B6BE0)]
private let foldDirs: [CGPoint] = [CGPoint(x: 1, y: 0), CGPoint(x: -1, y: 0), CGPoint(x: 0, y: 1)]   // left flap →, right flap ←, top flap ↓
private let tapeSpots: [(CGFloat, CGFloat)] = [(0.3, 0.5), (0.7, 0.5), (0.5, 0.22)]
private let wrapW: CGFloat = 314, wrapH: CGFloat = 274

func drawPaper(_ ctx: inout GraphicsContext, _ p: Paper, _ r: CGRect) {
    ctx.fill(Path(r), with: .color(p.base))
    var c = ctx
    c.clip(to: Path(r))
    switch p {
    case .stripes:
        var x = r.minX - r.height
        while x < r.maxX {
            var path = Path(); path.move(to: CGPoint(x: x, y: r.maxY)); path.addLine(to: CGPoint(x: x + 10, y: r.maxY))
            path.addLine(to: CGPoint(x: x + 10 + r.height, y: r.minY)); path.addLine(to: CGPoint(x: x + r.height, y: r.minY)); path.closeSubpath()
            c.fill(path, with: .color(p.ink)); x += 22
        }
    case .dots, .stars, .hearts:
        var y = r.minY + 8, row = 0
        while y < r.maxY {
            var x = r.minX + (row % 2 == 0 ? 8 : 20)
            while x < r.maxX {
                let pt = CGPoint(x: x, y: y)
                switch p {
                case .dots: c.fill(Path(ellipseIn: CGRect(x: x - 3.5, y: y - 3.5, width: 7, height: 7)), with: .color(p.ink))
                case .stars: c.fill(starPath(pt, 6, 2.5), with: .color(p.ink))
                default: c.fill(heartPath(pt, 5), with: .color(p.ink))
                }
                x += p == .dots ? 20 : 24
            }
            y += p == .dots ? 14 : 18; row += 1
        }
    }
}

struct WrapView: View {
    let game: GameState
    @State private var phase = WrapPhase.pick
    @State private var toy = Toy.teddy
    @State private var paper = Paper.stripes
    @State private var folds = 0
    @State private var pull = CGPoint.zero
    @State private var tapes: [Int] = []
    @State private var bow: Color?
    @State private var steps = DragSteps()

    var body: some View {
        VStack(spacing: 8) {
            JobChip(game: game, kind: .wrap)
            if phase == .pick { pick } else { wrapping }
        }
    }

    private var pick: some View {
        VStack(spacing: 8) {
            Txt("Wrapped presents: \(game.s.wrapped) 🎁", 17)
            let owned = Toy.allCases.filter { game.s.toys[$0, default: 0] > 0 }
            if owned.isEmpty {
                Bubble(text: "You need a toy to wrap! Make one in the 🔨 Make tab first.", width: 300)
            } else {
                Txt("Pick a toy to wrap!", 19)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(owned, id: \.self) { t in
                            Tap(action: {
                                if game.startWrap(t) { toy = t; folds = 0; pull = .zero; tapes = []; bow = nil; phase = .paper }
                            }) {
                                VStack(spacing: 0) { Px(t.sprite, 40); Txt("×\(game.s.toys[t, default: 0])", 12) }.padding(4).frame(width: 78).panel(.white)
                            }
                        }
                    }
                }
                Txt("Wrapping uses ⚡3. Wrapped presents go on the sleigh first!", 14, Pal.brown, align: .center)
            }
        }
    }

    private var wrapping: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topLeading) {
                Canvas { ctx, size in draw(&ctx, size) }
                if folds < 3 { Px(toy.sprite, 70).position(x: wrapW / 2, y: wrapH / 2 + 8) }
                if phase == .fold && folds < 3 {
                    let arrow = ["👉", "👈", "👇"][folds]
                    let at = [CGPoint(x: 30, y: wrapH / 2), CGPoint(x: wrapW - 30, y: wrapH / 2), CGPoint(x: wrapW / 2, y: 26)][folds]
                    Txt(arrow, 34).bob(6, 0.4).position(at)
                }
                if phase == .tape {
                    ForEach(0..<3, id: \.self) { i in
                        if !tapes.contains(i) {
                            Tap(action: {
                                tapes.append(i); Audio.shared.play(.tap)
                                if tapes.count == 3 { phase = .bow; game.say("Now pick a bow! 🎀") }
                            }) {
                                Txt("📎", 18).frame(width: 44, height: 44).background(Circle().fill(Pal.gold)).overlay(Circle().stroke(Pal.ink, lineWidth: 3))
                            }
                            .position(x: tapeSpots[i].0 * wrapW, y: tapeSpots[i].1 * wrapH)
                        }
                    }
                }
                if phase == .done { Txt("✨🎁✨", 34).bob(10, 0.3).frame(width: wrapW).padding(.top, 4) }
            }
            .frame(width: wrapW, height: wrapH)
            .padding(3).panel(Color(hex: 0xC98B5E))
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 2).onChanged { v in onDrag(steps.step(v)) }.onEnded { _ in steps.last = nil })

            switch phase {
            case .paper:
                Txt("Pick your wrapping paper!", 18)
                HStack(spacing: 6) {
                    ForEach(Paper.allCases, id: \.self) { p in
                        Tap(action: { paper = p; phase = .fold; Audio.shared.play(.pop) }) {
                            VStack(spacing: 2) {
                                Canvas { ctx, size in drawPaper(&ctx, p, CGRect(origin: .zero, size: size)) }.frame(width: 56, height: 56)
                                Txt(p.rawValue, 11, align: .center)
                            }
                            .padding(4).frame(maxWidth: .infinity).panel(.white, border: paper == p ? Pal.red : Pal.ink)
                        }
                    }
                }
            case .fold:
                Txt("Fold \(folds + 1) of 3: swipe the paper \(["to the right ➡️", "to the left ⬅️", "down ⬇️"][min(folds, 2)])", 17, align: .center)
            case .tape:
                Txt("Tap the 📎 spots to tape it shut! (\(tapes.count)/3)", 17, align: .center)
            case .bow:
                Txt("Pick a bow color! 🎀", 18)
                HStack(spacing: 10) {
                    ForEach(0..<bowColors.count, id: \.self) { i in
                        Tap(action: {
                            bow = bowColors[i]; phase = .done
                            game.finishWrap(toy)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) { phase = .pick }
                        }) { Circle().fill(bowColors[i]).overlay(Circle().stroke(Pal.ink, lineWidth: 3)).frame(width: 46, height: 46) }
                    }
                }
            case .done:
                Txt("Ta-da! A \(paper.rawValue.lowercased()) present! 🎁", 19, Pal.red, align: .center)
            case .pick: EmptyView()
            }
            if phase != .done { Btn("✖ Stop", Pal.grey, size: 14, width: 110) { phase = .pick } }
        }
    }

    private func onDrag(_ d: CGPoint) {
        guard phase == .fold, folds < 3 else { return }
        pull = CGPoint(x: pull.x + d.x, y: pull.y + d.y)
        let dir = foldDirs[folds]
        if pull.x * dir.x + pull.y * dir.y > 80 {
            folds += 1; pull = .zero; Audio.shared.play(.pop)
            if folds == 3 { phase = .tape; game.say("Neat folding! Now tape it down 📎") }
        }
    }

    private func draw(_ ctx: inout GraphicsContext, _ size: CGSize) {
        let c = CGPoint(x: size.width / 2, y: size.height / 2 + 10)
        let box = CGRect(x: c.x - 80, y: c.y - 55, width: 160, height: 110)
        let sheet = CGRect(x: box.minX - 55, y: box.minY - 50, width: box.width + 110, height: box.height + 70)
        let edge = StrokeStyle(lineWidth: 3)
        if folds < 3 {
            ctx.fill(Path(sheet.insetBy(dx: -3, dy: -3)), with: .color(Pal.ink))
            drawPaper(&ctx, paper, sheet)
            ctx.fill(Path(box), with: .color(Color(hex: 0xE8D2A8)))
            ctx.stroke(Path(box), with: .color(Pal.ink), style: edge)
        }
        let wiggle = min(40, hypot(pull.x, pull.y) * 0.4)
        if folds >= 1 {
            let r = CGRect(x: box.minX, y: box.minY, width: box.width / 2 + 4, height: box.height)
            drawPaper(&ctx, paper, r); ctx.stroke(Path(r), with: .color(Pal.ink), style: edge)
        } else if phase == .fold { drawPaper(&ctx, paper, CGRect(x: box.minX - 55 + wiggle, y: box.minY, width: 55, height: box.height)) }
        if folds >= 2 {
            let r = CGRect(x: c.x - 4, y: box.minY, width: box.width / 2 + 4, height: box.height)
            drawPaper(&ctx, paper, r); ctx.stroke(Path(r), with: .color(Pal.ink), style: edge)
        } else if folds == 1 { drawPaper(&ctx, paper, CGRect(x: box.maxX - wiggle, y: box.minY, width: 55, height: box.height)) }
        if folds >= 3 {
            drawPaper(&ctx, paper, box)
            ctx.stroke(Path(box), with: .color(Pal.ink), style: edge)
            ctx.fill(Path(CGRect(x: box.minX, y: box.maxY - 12, width: box.width, height: 12)), with: .color(.black.opacity(0.12)))
        } else if folds == 2 { drawPaper(&ctx, paper, CGRect(x: box.minX, y: box.minY - 50 + wiggle, width: box.width, height: 50)) }
        for i in tapes {
            ctx.fill(Path(CGRect(x: tapeSpots[i].0 * size.width - 16, y: tapeSpots[i].1 * size.height - 6 + 20, width: 32, height: 12)), with: .color(.white.opacity(0.75)))
        }
        if let bow {
            ctx.fill(Path(CGRect(x: c.x - 8, y: box.minY, width: 16, height: box.height)), with: .color(bow))
            ctx.fill(Path(CGRect(x: box.minX, y: c.y - 8, width: box.width, height: 16)), with: .color(bow))
            let top = CGPoint(x: c.x, y: box.minY - 4)
            for sx: CGFloat in [-1, 1] {
                ctx.fill(Path(ellipseIn: CGRect(x: top.x + sx * 26 - 18, y: top.y - 24, width: 36, height: 26)), with: .color(Pal.ink))
                ctx.fill(Path(ellipseIn: CGRect(x: top.x + sx * 26 - 15, y: top.y - 21, width: 30, height: 20)), with: .color(bow))
            }
            ctx.fill(Path(ellipseIn: CGRect(x: top.x - 11, y: top.y - 11, width: 22, height: 22)), with: .color(Pal.ink))
            ctx.fill(Path(ellipseIn: CGRect(x: top.x - 8, y: top.y - 8, width: 16, height: 16)), with: .color(bow))
            for i in 0..<18 {
                ctx.fill(Path(CGRect(x: CGFloat((i * 97) % 300), y: CGFloat((i * 53) % 110), width: 6, height: 6)), with: .color(confetti[i % confetti.count]))
            }
        }
    }
}

// ======================================================================
// MARK: - Gingerbread house: drag the pieces together, pipe icing, add candy
// ======================================================================

private enum GingerPhase: Int, Comparable {
    case build, ice, candy, done
    static func < (a: GingerPhase, b: GingerPhase) -> Bool { a.rawValue < b.rawValue }
}
private enum Piece: CaseIterable {
    case base, walls, roof, door
    var target: CGRect {
        switch self {
        case .base: CGRect(x: 40, y: 200, width: 320, height: 26)
        case .walls: CGRect(x: 90, y: 110, width: 220, height: 90)
        case .roof: CGRect(x: 70, y: 30, width: 260, height: 86)
        case .door: CGRect(x: 176, y: 140, width: 48, height: 60)
        }
    }
    var trayStart: CGPoint {
        switch self {
        case .base: CGPoint(x: 10, y: 300)
        case .walls: CGPoint(x: 10, y: 250)
        case .roof: CGPoint(x: 150, y: 250)
        case .door: CGPoint(x: 330, y: 280)
        }
    }
}
private let iceRub: CGFloat = 700
private let trayScale: CGFloat = 0.5

private func drawPiece(_ ctx: inout GraphicsContext, _ p: Piece, at: CGPoint, ghost: Bool = false, k: CGFloat = 1) {
    let w = p.target.width * k, h = p.target.height * k
    let dough = ghost ? Color.black.opacity(0.12) : Color(hex: 0xB8763A)
    let edge = ghost ? Color.black.opacity(0.2) : Pal.ink
    let r = CGRect(x: at.x, y: at.y, width: w, height: h)
    switch p {
    case .base:
        ctx.fill(Path(roundedRect: r, cornerRadius: 8 * k), with: .color(edge))
        ctx.fill(Path(roundedRect: r.insetBy(dx: 3 * k, dy: 3 * k), cornerRadius: 6 * k), with: .color(ghost ? dough : .white))
    case .walls:
        ctx.fill(Path(r), with: .color(edge)); ctx.fill(Path(r.insetBy(dx: 3 * k, dy: 3 * k)), with: .color(dough))
        if !ghost {
            for wx: CGFloat in [0.15, 0.7] {
                let win = CGRect(x: at.x + w * wx, y: at.y + h * 0.25, width: w * 0.15, height: h * 0.3)
                ctx.fill(Path(win), with: .color(Pal.ink)); ctx.fill(Path(win.insetBy(dx: 3 * k, dy: 3 * k)), with: .color(Pal.gold))
            }
        }
    case .roof:
        var path = Path(); path.move(to: CGPoint(x: r.minX, y: r.maxY)); path.addLine(to: CGPoint(x: r.midX, y: r.minY)); path.addLine(to: CGPoint(x: r.maxX, y: r.maxY)); path.closeSubpath()
        ctx.fill(path, with: .color(dough)); ctx.stroke(path, with: .color(edge), lineWidth: 3 * k)
    case .door:
        ctx.fill(Path(roundedRect: r, cornerRadius: w / 2), with: .color(edge))
        ctx.fill(Path(roundedRect: CGRect(x: r.minX + 3 * k, y: r.minY + 3 * k, width: w - 6 * k, height: h - 3 * k), cornerRadius: w / 2), with: .color(ghost ? dough : Color(hex: 0x8A5A3A)))
    }
}

struct GingerbreadView: View {
    let game: GameState
    let onExit: () -> Void
    @State private var phase = GingerPhase.build
    @State private var pos: [Piece: CGPoint] = Dictionary(uniqueKeysWithValues: Piece.allCases.map { ($0, $0.trayStart) })
    @State private var placed: [Piece] = []
    @State private var iced: CGFloat = 0
    @State private var candies: [(CGFloat, CGFloat, Int)] = []
    @State private var steps = DragSteps()

    var body: some View {
        VStack(spacing: 8) {
            Txt(title, 18, align: .center)
            ZStack(alignment: .topLeading) {
                Canvas { ctx, size in
                    ctx.fill(Path(CGRect(x: 0, y: 240, width: size.width, height: 4)), with: .color(Color(hex: 0xE7C49A)))
                    for p in Piece.allCases where !placed.contains(p) { drawPiece(&ctx, p, at: p.target.origin, ghost: true) }
                    for p in Piece.allCases where placed.contains(p) { drawPiece(&ctx, p, at: p.target.origin) }
                    if phase >= .ice { drawIcing(&ctx, min(1, iced / iceRub)) }
                    for (x, y, k) in candies {
                        let r = CGRect(x: x - 9, y: y - 9, width: 18, height: 18)
                        switch k {
                        case 0, 1:
                            ctx.fill(Path(ellipseIn: r), with: .color(Pal.ink))
                            ctx.fill(Path(ellipseIn: r.insetBy(dx: 2, dy: 2)), with: .color(k == 0 ? Pal.red : Pal.green))
                            ctx.fill(Path(ellipseIn: CGRect(x: x - 4.5, y: y - 4.5, width: 5, height: 5)), with: .color(.white))
                        case 2:
                            ctx.fill(Path(roundedRect: CGRect(x: x - 10, y: y - 5, width: 20, height: 10), cornerRadius: 4), with: .color(Pal.ink))
                            ctx.fill(Path(roundedRect: CGRect(x: x - 8, y: y - 3, width: 16, height: 6), cornerRadius: 3), with: .color(Pal.gold))
                        default:
                            ctx.fill(starPath(CGPoint(x: x, y: y), 9, 4), with: .color(Pal.pink))
                        }
                    }
                }
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 2).onChanged { v in pipe(steps.step(v)) }.onEnded { _ in steps.last = nil })
                .simultaneousGesture(SpatialTapGesture().onEnded { addCandy($0.location) })

                if phase == .build {
                    ForEach(Piece.allCases, id: \.self) { p in
                        if !placed.contains(p) {
                            let at = pos[p] ?? p.trayStart
                            Canvas { ctx, _ in drawPiece(&ctx, p, at: .zero, k: trayScale) }
                                .frame(width: p.target.width * trayScale, height: p.target.height * trayScale)
                                .offset(x: at.x, y: at.y)
                                .gesture(DragGesture()
                                    .onChanged { v in pos[p] = CGPoint(x: p.trayStart.x + v.translation.width, y: p.trayStart.y + v.translation.height) }
                                    .onEnded { _ in drop(p) })
                        }
                    }
                }
                if phase == .done { Txt("✨🏠✨", 30).bob(8, 0.3).frame(width: 400).padding(.top, 4) }
            }
            .frame(width: 400, height: 370)
            .padding(3).panel(Color(hex: 0xFFE3C2))
            HStack(spacing: 10) {
                Txt("Uses 3 wheat & ⚡5. It goes in your house!", 13, Pal.brown)
                if phase != .done { Btn("✖ Stop", Pal.grey, size: 14, width: 100, action: onExit) }
            }
        }
    }

    private var title: String {
        switch phase {
        case .build: "Drag each piece onto its shadow! (\(placed.count)/4)"
        case .ice: "Rub along the roof to pipe the icing! ❄️"
        case .candy: "Tap the house to stick on candy! (\(candies.count)/6)"
        case .done: "Ta-da! A gingerbread house! 🏠"
        }
    }

    private func drop(_ p: Piece) {
        let cur = pos[p] ?? p.trayStart
        if hypot(cur.x - p.target.minX, cur.y - p.target.minY) < 70 {
            placed.append(p); Audio.shared.play(.ding)
            if placed.count == 4 { phase = .ice; game.say("It's standing! Now the icing ❄️") }
        } else { pos[p] = p.trayStart; Audio.shared.play(.oops) }
    }

    private func pipe(_ d: CGPoint) {
        guard phase == .ice else { return }
        let before = iced
        iced += hypot(d.x, d.y)
        if Int(iced / 120) > Int(before / 120) { Audio.shared.play(.pop) }
        if iced >= iceRub { phase = .candy; game.say("Snowy icing! Now tap to stick on candy 🍬") }
    }

    private func addCandy(_ p: CGPoint) {
        guard phase == .candy, (60...340).contains(p.x), (30...215).contains(p.y) else { return }
        candies.append((p.x, p.y, Int.random(in: 0..<4))); Audio.shared.play(.pop)
        if candies.count >= 6 {
            phase = .done
            game.finishGingerHouse()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) { onExit() }
        }
    }

    private func drawIcing(_ ctx: inout GraphicsContext, _ frac: CGFloat) {
        let roof = Piece.roof.target
        let l = CGPoint(x: roof.minX, y: roof.maxY), top = CGPoint(x: roof.midX, y: roof.minY), r = CGPoint(x: roof.maxX, y: roof.maxY)
        let n = 24
        for i in 0..<Int(CGFloat(n) * frac) {
            let t = CGFloat(i) / CGFloat(n - 1)
            let p = t < 0.5 ? CGPoint(x: l.x + (top.x - l.x) * t * 2, y: l.y + (top.y - l.y) * t * 2)
                            : CGPoint(x: top.x + (r.x - top.x) * (t - 0.5) * 2, y: top.y + (r.y - top.y) * (t - 0.5) * 2)
            ctx.fill(Path(ellipseIn: CGRect(x: p.x - 7, y: p.y - 7, width: 14, height: 14)), with: .color(.white))
            if i % 3 == 1 { ctx.fill(Path(roundedRect: CGRect(x: p.x - 2.5, y: p.y, width: 5, height: 12), cornerRadius: 2.5), with: .color(.white)) }
        }
    }
}

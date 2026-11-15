import SwiftUI

// Port of the Android MiniGames.kt. Keep the two in sync.

/// Mixes two colors (works on iOS 17).
private func blend(_ a: UInt32, _ b: UInt32, _ t: CGFloat) -> Color {
    func ch(_ c: UInt32, _ shift: UInt32) -> CGFloat { CGFloat((c >> shift) & 0xFF) / 255 }
    let f = min(1, max(0, t))
    return Color(.sRGB, red: ch(a, 16) + (ch(b, 16) - ch(a, 16)) * f, green: ch(a, 8) + (ch(b, 8) - ch(a, 8)) * f, blue: ch(a, 0) + (ch(b, 0) - ch(a, 0)) * f)
}

/// Small repeatable random numbers, so sprinkles stay where you put them.
private struct Seeded: RandomNumberGenerator {
    var state: UInt64
    init(_ seed: UInt64) { state = seed &+ 0x9E3779B97F4A7C15 }
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
    mutating func unit() -> CGFloat { CGFloat(next() >> 11) / CGFloat(1 << 53) }
}

// ======================================================================
// MARK: - Bakery: mix the dough, bake it just right, then decorate it
// ======================================================================

private enum BakePhase { case pick, mix, bake, decorate, done }
private enum Topping: String, CaseIterable { case sprinkles = "✨ Sprinkles", candy = "🍬 Candy", star = "⭐ Stars", heart = "💖 Hearts" }
private struct Top { let kind: Topping; let x: CGFloat; let y: CGFloat; let seed: UInt64 }

private let stirsNeeded = 12
private let icings: [UInt32] = [0xFFFFFF, 0xFF9DB8, 0xA6E06A, 0x9BD3FF, 0x8A5A3A]

struct BakeryView: View {
    let game: GameState
    @State private var phase = BakePhase.pick
    @State private var cookie = Cookie.sugar
    @State private var stirs = 0
    @State private var perfect = false
    @State private var icing: UInt32?
    @State private var tool = Topping.sprinkles
    @State private var tops: [Top] = []
    @State private var bakeStart = Date()
    @State private var house = false

    var body: some View {
        if house { GingerbreadView(game: game) { house = false } } else { bakery }
    }

    private var bakery: some View {
        VStack(spacing: 10) {
            JobChip(game: game, kind: .bake)
            switch phase {
            case .pick: recipes
            case .mix: mix
            case .bake: bake
            case .decorate: decorate
            case .done:
                Txt("Ta-da! 🎉", 30, Pal.red)
                CookieCanvas(icing: icing, tops: tops, perfect: perfect).frame(width: 220, height: 220).bob(6, 0.3)
                Txt(perfect ? "⭐ A perfect \(cookie.title)!" : "A yummy \(cookie.title)!", 20)
            }
        }
    }

    private var recipes: some View {
        VStack(spacing: 10) {
            HStack(alignment: .bottom, spacing: 10) {
                ElfPx(look: game.s.look, height: 120).bob()
                Bubble(text: "Pick a cookie to make! You'll mix it, bake it and decorate it. 🍪", width: 230)
            }
            ForEach(Cookie.allCases, id: \.self) { c in
                let locked = c.unlockLevel > game.level
                HStack(spacing: 8) {
                    Px(c.sprite, 48)
                    VStack(alignment: .leading, spacing: 2) {
                        Txt("\(c.title)  ×\(game.s.cookies[c, default: 0])", 16)
                        HStack(spacing: 3) {
                            ForEach(c.recipe, id: \.0) { crop, n in Txt("\(n)×", 13); Px(crop.sprite, 20) }
                            Txt(" ⚡5", 13)
                        }
                    }
                    Spacer()
                    if locked { Tag("🔒 Lv \(c.unlockLevel)", Pal.grey) }
                    else {
                        Btn("Make!", Pal.red, size: 16, width: 90) {
                            if !game.canBake(c) { game.say("Not enough ingredients! Grow some in the Greenhouse 🌱"); Audio.shared.play(.oops) }
                            else if game.hasEnergy(5) { cookie = c; stirs = 0; tops = []; icing = nil; perfect = false; phase = .mix }
                        }
                    }
                }
                .padding(8).panel(locked ? Color(hex: 0xD5DBE6) : .white)
            }
            Btn("🏠 Build a Gingerbread House (3 wheat, ⚡5)", Color(hex: 0x8A5A3A), size: 15) {
                if !game.canBuildHouse() { game.say("A gingerbread house needs 3 wheat! Grow some in the Greenhouse 🌾"); Audio.shared.play(.oops) }
                else if game.hasEnergy(5) { house = true }
            }
        }
    }

    // Tap the bowl to stir
    private var mix: some View {
        let frac = CGFloat(stirs) / CGFloat(stirsNeeded)
        return VStack(spacing: 10) {
            Txt("Tap the bowl to stir! 🥄", 22)
            Button {
                stirs += 1
                Audio.shared.play(.pop)
                if stirs >= stirsNeeded { bakeStart = Date(); phase = .bake }
            } label: {
                ZStack {
                    Capsule().fill(Color(hex: 0xC98B5E)).frame(width: 14, height: 130).offset(y: -70).rotationEffect(.degrees(-20 + Double(stirs) * 17), anchor: .bottom)
                    Ellipse().fill(LinearGradient(colors: [Color(hex: 0xD5DBE6), Color(hex: 0x8D96A8)], startPoint: .top, endPoint: .bottom))
                        .overlay(Ellipse().stroke(Pal.ink, lineWidth: 4)).frame(width: 264, height: 146).offset(y: 30)
                    Ellipse().fill(blend(0xF6EEDC, 0xE3A35A, frac)).frame(width: 224, height: 70).offset(y: -5)
                    Circle().trim(from: 0, to: 0.72).stroke(Color(hex: 0x8A5A3A).opacity(0.4), lineWidth: 4).frame(width: 110, height: 34)
                        .rotationEffect(.degrees(Double(stirs) * 50)).offset(y: -5)
                }
                .frame(width: 300, height: 240)
                .animation(.spring(response: 0.3), value: stirs)
            }
            .buttonStyle(Squish())
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4).fill(.white).frame(width: 260, height: 16).overlay(RoundedRectangle(cornerRadius: 4).stroke(Pal.ink, lineWidth: 2))
                RoundedRectangle(cornerRadius: 4).fill(Color(hex: 0xE3A35A)).frame(width: 260 * frac, height: 16)
            }
            Txt("\(stirs) / \(stirsNeeded) stirs", 16)
        }
    }

    private func heat(at date: Date) -> CGFloat {
        let f = (date.timeIntervalSince(bakeStart) / 1.3).truncatingRemainder(dividingBy: 2)
        return CGFloat(f < 1 ? f : 2 - f)
    }

    // Take it out in the golden zone
    private var bake: some View {
        VStack(spacing: 10) {
            Txt("Take it out when the bar is in the ⭐ golden zone!", 18, align: .center)
            TimelineView(.animation) { tl in
                let h = heat(at: tl.date)
                VStack(spacing: 10) {
                    ZStack {
                        Rectangle().fill(Pal.ink).frame(width: 200, height: 190)
                        Rectangle().fill(Color(hex: 0xC9CED8)).frame(width: 192, height: 182)
                        Rectangle().fill(Pal.ink).frame(width: 156, height: 110).offset(y: 12)
                        Rectangle().fill(blend(0xFF9A3C, 0xFF5A2A, h)).frame(width: 148, height: 102).offset(y: 12)
                        HStack(spacing: 22) { ForEach(0..<4, id: \.self) { _ in Rectangle().fill(Pal.red).frame(width: 18, height: 18) } }.offset(y: -70)
                        Px(cookie.sprite, 64).offset(y: 12).bob(3, 0.3)
                    }
                    ZStack(alignment: .leading) {
                        LinearGradient(colors: [Color(hex: 0xF6EEDC), Color(hex: 0xE3A35A), Color(hex: 0x6B3A1E)], startPoint: .leading, endPoint: .trailing)
                        Rectangle().fill(Pal.gold.opacity(0.75)).frame(width: 320 * 0.25).offset(x: 320 * 0.55)
                        Txt("⭐", 16).offset(x: 320 * 0.64)
                        Rectangle().fill(Pal.ink).frame(width: 6).offset(x: 320 * h - 3)
                    }
                    .frame(width: 320, height: 30)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Pal.ink, lineWidth: 3))
                }
            }
            Btn("🧤 Take it out!", Pal.red, size: 22, width: 240) {
                let h = heat(at: Date())
                perfect = (0.55...0.8).contains(h)
                Audio.shared.play(perfect ? .ding : .pop)
                game.say(perfect ? "⭐ PERFECT bake! Golden and yummy!" : "A little \(Bool.random() ? "pale" : "toasty"), but still yummy! 😋")
                phase = .decorate
            }
        }
    }

    // Tap the cookie to add toppings
    private var decorate: some View {
        VStack(spacing: 10) {
            Txt("Decorate your \(cookie.title)!", 22)
            CookieCanvas(icing: icing, tops: tops, perfect: perfect)
                .frame(width: 250, height: 250)
                .contentShape(Rectangle())
                .gesture(SpatialTapGesture().onEnded { v in
                    let x = v.location.x / 250, y = v.location.y / 250
                    if (x - 0.5) * (x - 0.5) + (y - 0.5) * (y - 0.5) < 0.42 * 0.42 {
                        tops.append(Top(kind: tool, x: x, y: y, seed: UInt64.random(in: 0...UInt64.max)))
                        Audio.shared.play(.pop)
                    }
                })
            HStack(spacing: 8) {
                Txt("Icing:", 16)
                ForEach(icings, id: \.self) { c in
                    Tap(action: { icing = c; Audio.shared.play(.tap) }) {
                        Circle().fill(Color(hex: c)).overlay(Circle().stroke(Pal.ink, lineWidth: 2)).frame(width: 28, height: 28)
                            .padding(4).overlay(Circle().stroke(icing == c ? Pal.red : .clear, lineWidth: 3))
                    }
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Topping.allCases, id: \.self) { t in
                        Tap(action: { tool = t }) { Txt(t.rawValue, 15, tool == t ? .white : Pal.ink).padding(.horizontal, 10).padding(.vertical, 5).panel(tool == t ? Pal.red : .white) }
                    }
                }
            }
            Txt(tops.count < 3 ? "Tap the cookie to add toppings! (\(tops.count)/3)" : "Looks delicious! Add more or tap Done.", 15, align: .center)
            HStack(spacing: 10) {
                Btn("↺ Clear", Pal.grey, size: 16, width: 110) { tops = []; icing = nil }
                Btn("✅ Done!", Pal.green, size: 18, width: 160, enabled: tops.count >= 3) {
                    if game.bake(cookie) {
                        phase = .done
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { phase = .pick }
                    } else { phase = .pick }
                }
            }
        }
    }
}

private let sprinkleColors: [UInt32] = [0xE5394B, 0x3FAF5A, 0x3D6FD6, 0xFFCC4D, 0xFF8FB0, 0x9B6BE0]

/// A plain cookie with your icing and toppings drawn on top.
private struct CookieCanvas: View {
    let icing: UInt32?
    let tops: [Top]
    let perfect: Bool

    var body: some View {
        Canvas { ctx, size in
            let r = min(size.width, size.height) * 0.46
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            func circle(_ center: CGPoint, _ radius: CGFloat) -> Path { Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)) }
            ctx.fill(circle(c, r + 4), with: .color(Pal.ink))
            ctx.fill(circle(c, r), with: .radialGradient(Gradient(colors: perfect ? [Color(hex: 0xEBB86A), Color(hex: 0xC98B4A)] : [Color(hex: 0xDDA45E), Color(hex: 0xB8763A)]), center: c, startRadius: 0, endRadius: r))
            var rnd = Seeded(7)
            for _ in 0..<14 { ctx.fill(circle(CGPoint(x: c.x + (rnd.unit() - 0.5) * r * 1.5, y: c.y + (rnd.unit() - 0.5) * r * 1.5), 3), with: .color(Color(hex: 0xA9693A).opacity(0.5))) }
            if let icing {
                ctx.fill(circle(c, r * 0.84), with: .color(Color(hex: icing)))
                ctx.fill(circle(CGPoint(x: c.x - r * 0.35, y: c.y - r * 0.35), r * 0.2), with: .color(.white.opacity(0.35)))
            }
            for t in tops {
                let p = CGPoint(x: t.x * size.width, y: t.y * size.height)
                var rnd = Seeded(t.seed)
                switch t.kind {
                case .sprinkles:
                    for _ in 0..<7 {
                        let o = CGPoint(x: p.x + (rnd.unit() - 0.5) * 30, y: p.y + (rnd.unit() - 0.5) * 30)
                        let angle = rnd.unit() * .pi
                        let rect = Path(roundedRect: CGRect(x: -5, y: -1.5, width: 10, height: 3), cornerRadius: 1.5)
                            .applying(CGAffineTransform(rotationAngle: angle).concatenating(CGAffineTransform(translationX: o.x, y: o.y)))
                        ctx.fill(rect, with: .color(Color(hex: sprinkleColors[Int(rnd.next() % UInt64(sprinkleColors.count))])))
                    }
                case .candy:
                    ctx.fill(circle(p, 11), with: .color(Pal.ink))
                    ctx.fill(circle(p, 9), with: .color(rnd.next() % 2 == 0 ? Pal.red : Pal.green))
                    ctx.fill(circle(CGPoint(x: p.x - 3, y: p.y - 3), 3), with: .color(.white.opacity(0.7)))
                case .star:
                    let s = starPath(p, 14, 6)
                    ctx.fill(s, with: .color(Pal.gold)); ctx.stroke(s, with: .color(Pal.ink), lineWidth: 1.5)
                case .heart:
                    var h = Path()
                    h.move(to: CGPoint(x: p.x, y: p.y + 10))
                    h.addCurve(to: CGPoint(x: p.x, y: p.y - 5), control1: CGPoint(x: p.x - 16, y: p.y - 2), control2: CGPoint(x: p.x - 8, y: p.y - 14))
                    h.addCurve(to: CGPoint(x: p.x, y: p.y + 10), control1: CGPoint(x: p.x + 8, y: p.y - 14), control2: CGPoint(x: p.x + 16, y: p.y - 2))
                    h.closeSubpath()
                    ctx.fill(h, with: .color(Color(hex: 0xFF5C8A))); ctx.stroke(h, with: .color(Pal.ink), lineWidth: 1.5)
                }
            }
        }
    }
}


// ======================================================================
// MARK: - Workshop: every toy step is a little game
// ======================================================================

private enum StepKind { case fill, dots, paint }

private func kinds(_ t: Toy) -> [StepKind] {
    switch t {
    case .teddy: [.fill, .dots, .paint]
    case .candyCane: [.fill, .paint, .dots]
    case .train, .doll, .robot: [.dots, .fill, .paint]
    case .drum: [.fill, .paint, .dots]
    case .rockingHorse: [.dots, .fill, .paint]
    case .yoYo, .snowGlobe: [.fill, .dots, .paint]
    }
}

/// Which pixel letter in the toy's sprite gets your chosen color.
private func paintChar(_ t: Toy) -> Character {
    switch t { case .teddy: "b"; case .doll: "p"; case .robot: "y"; case .snowGlobe: "d"; default: "r" }
}

private func fillHint(_ t: Toy) -> String {
    switch t {
    case .teddy: "Tap the teddy to stuff it with fluffy cotton! ☁️"
    case .candyCane: "Tap to pull and stretch the sugar! 🍬"
    case .train: "Tap to screw on the wheels! 🔩"
    case .doll: "Tap to brush her hair! 💇"
    case .drum: "Tap to stretch the drum skin tight! 🥁"
    case .robot: "Tap to charge the battery! ⚡"
    case .rockingHorse: "Tap to brush the mane! 🐴"
    case .yoYo: "Tap to wind the string round and round! 🌀"
    case .snowGlobe: "Tap to shake in the snow! ❄️"
    }
}

private func fillPuff(_ t: Toy) -> String {
    switch t { case .teddy: "☁️"; case .candyCane: "✨"; case .train: "🔩"; case .doll: "💫"; case .drum: "💥"; case .robot: "⚡"; case .rockingHorse: "✨"; case .yoYo: "🌀"; case .snowGlobe: "❄️" }
}

private let fillTaps = 10
private let toyPaints: [UInt32] = [0x9A5B34, 0xE5394B, 0x3D6FD6, 0x3FAF5A, 0x9B6BE0, 0xFF8FB0, 0xFFCC4D]
private let dotSpots: [(CGFloat, CGFloat)] = [(0.2, 0.3), (0.5, 0.12), (0.8, 0.3), (0.76, 0.78), (0.24, 0.78)]
private let benchW: CGFloat = 294, benchH: CGFloat = 254

private enum ShopMode: String, CaseIterable { case make = "🔨 Make toys", wrap = "🎁 Wrap presents" }

struct WorkshopView: View {
    let game: GameState
    @State private var mode: ShopMode = .make

    var body: some View {
        VStack(spacing: 8) {
            Tabs(options: ShopMode.allCases, selected: mode, label: { $0.rawValue }) { mode = $0 }
            switch mode {
            case .make: ToyMakerView(game: game)
            case .wrap: WrapView(game: game)
            }
        }
        .onAppear {
            let s = game.s
            if s.jobs.contains(where: { $0.kind == .wrap && !$0.finished }) && s.toys.values.reduce(0, +) > 0 && s.jobs.first(where: { $0.kind == .toys })?.finished == true { mode = .wrap }
        }
    }
}

private struct ToyMakerView: View {
    let game: GameState
    @State private var toy = Toy.teddy
    @State private var step = 0          // 0 = not started, 1…3 = which step
    @State private var taps = 0
    @State private var dots = 0
    @State private var paint: UInt32?
    @State private var done = false
    @State private var puffs: [CGPoint] = []

    private var kind: StepKind? { step >= 1 && step <= kinds(toy).count ? kinds(toy)[step - 1] : nil }
    private var stepFrac: CGFloat { kind == .fill ? CGFloat(taps) / CGFloat(fillTaps) : kind == .dots ? CGFloat(dots) / 5 : 0 }

    private func nextStep() {
        taps = 0; dots = 0; puffs = []
        if step == kinds(toy).count {
            done = true
            game.finishToy(toy)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { done = false; step = 0; paint = nil }
        } else { step += 1 }
    }

    var body: some View {
        let reveal = done ? 1 : (CGFloat(max(0, step - 1)) + stepFrac) / CGFloat(kinds(toy).count)
        let image = paint.map { Sprites.image(key: "toy|\(toy)|\($0)", rows: Sprites.rows(toy.sprite), recolor: [paintChar(toy): $0]) } ?? Sprites.named(toy.sprite)
        VStack(spacing: 8) {
            JobChip(game: game, kind: .toys)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Toy.allCases, id: \.self) { t in
                        let locked = t.unlockLevel > game.level
                        Tap(enabled: step == 0, action: { if locked { game.say("\(t.title)s unlock at Level \(t.unlockLevel) 🔒") } else { toy = t; done = false; paint = nil } }) {
                            VStack(spacing: 2) { Px(t.sprite, 40, alpha: locked ? 0.3 : 1); Txt(locked ? "🔒 Lv\(t.unlockLevel)" : "×\(game.s.toys[t, default: 0])", 12) }
                                .frame(width: 70).padding(4)
                                .panel(toy == t ? Pal.paleGold : .white, border: toy == t ? Pal.red : Pal.ink)
                        }
                    }
                }
            }

            // The workbench
            ZStack(alignment: .topLeading) {
                ZStack {
                    Px(toy.sprite, 200, alpha: 0.15)
                    Px(image, 200, reveal: reveal).bob(done ? 8 : 0, 0.3)
                }
                .frame(width: benchW, height: benchH)
                ForEach(Array(puffs.enumerated()), id: \.offset) { _, p in Txt(fillPuff(toy), 22).position(p) }
                if kind == .dots { dotsLayer }
            }
            .frame(width: benchW, height: benchH)
            .contentShape(Rectangle())
            .gesture(SpatialTapGesture().onEnded { v in
                guard kind == .fill, taps < fillTaps else { return }
                taps += 1; puffs.append(v.location); Audio.shared.play(.pop)
                if taps >= fillTaps { nextStep() }
            })
            .panel(Color(hex: 0xC98B5E))

            Txt(done ? "Ta-da! A \(toy.title)! 🎁" : step == 0 ? "Make a \(toy.title)!" : "Step \(step) of \(kinds(toy).count): \(toy.steps[step - 1])", 19, align: .center)
            if !done {
                if step == 0 {
                    Btn("🔨 Start (⚡5)", Pal.red, size: 20, width: 220) { if game.startToy() { step = 1; paint = nil } }
                } else if kind == .fill {
                    Txt(fillHint(toy), 16, align: .center)
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4).fill(.white).frame(width: 260, height: 14).overlay(RoundedRectangle(cornerRadius: 4).stroke(Pal.ink, lineWidth: 2))
                        RoundedRectangle(cornerRadius: 4).fill(Pal.green).frame(width: 260 * stepFrac, height: 14)
                    }
                } else if kind == .dots {
                    Txt("Tap the dots in order: 1, 2, 3, 4, 5! 🧵", 16, align: .center)
                } else if kind == .paint {
                    Txt("Pick a color! 🎨", 16)
                    HStack(spacing: 8) {
                        ForEach(toyPaints, id: \.self) { c in
                            Tap(action: { paint = c; Audio.shared.play(.ding); nextStep() }) {
                                Circle().fill(Color(hex: c)).overlay(Circle().stroke(Pal.ink, lineWidth: 3)).frame(width: 36, height: 36)
                            }
                        }
                    }
                }
            }
        }
    }

    /// Five numbered dots to tap in order, with stitches between the ones you've done.
    private var dotsLayer: some View {
        ZStack(alignment: .topLeading) {
            Path { p in
                let pts = dotSpots.map { CGPoint(x: $0.0 * benchW, y: $0.1 * benchH) }
                guard dots >= 2 else { return }
                p.move(to: pts[0])
                for i in 1..<dots { p.addLine(to: pts[i]) }
                if dots == 5 { p.addLine(to: pts[0]) }
            }
            .stroke(Pal.ink, style: StrokeStyle(lineWidth: 4, dash: [7, 5]))
            ForEach(0..<5, id: \.self) { i in
                Tap(action: {
                    if i == dots {
                        dots += 1; Audio.shared.play(.pop)
                        if dots >= 5 { nextStep() }
                    } else { game.say("Tap number \(dots + 1) next!"); Audio.shared.play(.oops) }
                }) {
                    Txt(i < dots ? "✓" : "\(i + 1)", 18)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(i < dots ? Pal.green : i == dots ? Pal.gold : .white))
                        .overlay(Circle().stroke(Pal.ink, lineWidth: 3))
                }
                .position(x: dotSpots[i].0 * benchW, y: dotSpots[i].1 * benchH)
            }
        }
        .frame(width: benchW, height: benchH)
    }
}


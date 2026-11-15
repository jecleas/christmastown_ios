import SwiftUI

// Port of the Android Pets.kt. Keep the two in sync.

// ======================================================================
// MARK: - Pets: a little pet shop and hands-on pet care
// ======================================================================

private enum PetTab: String, CaseIterable { case care = "🐾 My Pets", shop = "🏪 Pet Shop" }
private enum PetTool: String, CaseIterable { case feed = "🍽️ Feed", wash = "🛁 Wash", cuddle = "🤗 Cuddle" }

struct PetsView: View {
    let game: GameState
    @State private var tab: PetTab?

    var body: some View {
        let current = tab ?? (game.s.pets.isEmpty ? .shop : .care)
        VStack(spacing: 8) {
            Tabs(options: PetTab.allCases, selected: current, label: { $0.rawValue }, color: Pal.orange) { tab = $0 }
            switch current {
            case .shop: PetShopView(game: game) { tab = .care }
            case .care:
                if game.s.pets.isEmpty {
                    Bubble(text: "You don't have a pet yet! Visit the 🏪 Pet Shop. Pets live in your house and LOVE you.", width: 320)
                } else { PetCareView(game: game) }
            }
        }
    }
}

private struct PetShopView: View {
    let game: GameState
    let onBought: () -> Void
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Txt("Every pet costs in-game money from working for Santa. 💰", 14, Pal.brown, align: .center)
                LazyVGrid(columns: [GridItem(.fixed(198), spacing: 10), GridItem(.fixed(198), spacing: 10)], spacing: 10) {
                    ForEach(PetKind.allCases, id: \.self) { k in
                        VStack(spacing: 4) {
                            Px(k.sprite, 80).bob(4, 0.5 + Double(k.hashValue % 5) * 0.09)
                            Txt(k.title, 17)
                            Txt("“\(k.noise)”", 13, Pal.brown)
                            let owned = game.s.pets.filter { $0.kind == k }.count
                            if owned > 0 { Txt("You have \(owned) 💖", 12, Pal.darkGreen) }
                            Btn("Adopt \(money(k.price))", Pal.orange, size: 15, width: 170) {
                                let before = game.s.pets.count
                                game.buyPet(k)
                                if game.s.pets.count > before { onBought() }
                            }
                        }
                        .padding(8).frame(width: 198).panel()
                    }
                }
            }
        }
    }
}

private let petRub: CGFloat = 380
private let petBubbles = 12
private let petCenter = CGPoint(x: 203, y: 170)
private let foodHome = CGPoint(x: 330, y: 240)

private struct PetCareView: View {
    let game: GameState
    @State private var selected: Int?
    @State private var tool: PetTool = .feed
    @State private var food: CGPoint?       // the snack you're dragging
    @State private var bites = 0
    @State private var rub: CGFloat = 0
    @State private var rinsing = false
    @State private var bubbles: [CGPoint] = []
    @State private var hearts: [CGPoint] = []
    @State private var bubble: String?
    @State private var jump = false
    @State private var last: CGPoint?

    var body: some View {
        let pets = game.s.pets
        let pet = pets.first { $0.id == selected } ?? pets[0]
        let now = game.now
        VStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(pets) { p in
                        Tap(action: { selected = p.id; reset() }) {
                            VStack(spacing: 0) { Px(p.kind.sprite, 36); Txt(p.name, 12, lines: 1) }
                                .padding(4).frame(width: 76).panel(p.id == pet.id ? Pal.paleGold : .white, border: p.id == pet.id ? Pal.red : Pal.ink)
                        }
                    }
                }
            }

            ZStack(alignment: .topLeading) {
                Canvas { ctx, size in
                    ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(hex: 0xFBE7C6)))
                    var x: CGFloat = 0
                    while x < size.width { ctx.fill(Path(CGRect(x: x, y: 0, width: 14, height: size.height * 0.7)), with: .color(Color(hex: 0xF4D9AE))); x += 40 }
                    ctx.fill(Path(CGRect(x: 0, y: size.height * 0.7, width: size.width, height: size.height * 0.3)), with: .color(Color(hex: 0xC98B5E)))
                    if tool == .wash {
                        ctx.fill(Path(roundedRect: CGRect(x: 90, y: 190, width: 226, height: 80), cornerRadius: 30), with: .color(Pal.ink))
                        ctx.fill(Path(roundedRect: CGRect(x: 94, y: 194, width: 218, height: 72), cornerRadius: 28), with: .color(Color(hex: 0xEAF6FF)))
                        ctx.fill(Path(CGRect(x: 100, y: 200, width: 206, height: 18)), with: .color(Color(hex: 0x9BD3FF)))
                    }
                }
                Px(pet.kind.sprite, 160)
                    .modifier(Breathe())
                    .offset(y: jump ? -40 : 0)
                    .position(petCenter)
                ForEach(Array(bubbles.enumerated()), id: \.offset) { _, b in
                    Circle().fill(.white.opacity(0.6)).overlay(Circle().stroke(Color(hex: 0x9BD3FF), lineWidth: 2)).frame(width: 30, height: 30).position(b)
                }
                ForEach(Array(hearts.enumerated()), id: \.offset) { i, h in Txt("💖", CGFloat(18 + i)).position(x: h.x, y: h.y - 30 - CGFloat(i * 3)) }
                if tool == .feed {
                    Txt(pet.kind.food, 30).frame(width: 60, height: 60).background(Circle().fill(.white)).overlay(Circle().stroke(Pal.ink, lineWidth: 3))
                        .position(food ?? foodHome)
                }
                if let bubble {
                    Txt(bubble, 15, align: .center).padding(.horizontal, 10).padding(.vertical, 6).panel(.white).frame(width: 406).padding(.top, 8)
                }
            }
            .frame(width: 406, height: 300)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Pal.ink, lineWidth: 3))
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 2)
                .onChanged { v in
                    if last == nil, tool == .feed, hypot(v.startLocation.x - foodHome.x, v.startLocation.y - foodHome.y) < 50 { food = foodHome }
                    let d = last.map { CGPoint(x: v.location.x - $0.x, y: v.location.y - $0.y) } ?? .zero
                    last = v.location
                    drag(pet, at: v.location, d: d)
                }
                .onEnded { _ in last = nil; dropFood(pet) })
            .simultaneousGesture(TapGesture().onEnded { show(pet.kind.jokes.randomElement()!); Audio.shared.play(.pop); hop() })

            HStack(spacing: 8) {
                Meter(label: "🍽️ Full", frac: pet.fullness(now), color: Pal.orange)
                Meter(label: "🛁 Clean", frac: pet.cleanness(now), color: Pal.blue)
                Meter(label: "😊 Happy", frac: pet.happiness(now), color: Pal.pink)
            }
            .padding(8).panel()

            HStack(spacing: 6) {
                ForEach(PetTool.allCases, id: \.self) { t in
                    Tap(action: { tool = t; bubbles = []; rinsing = false; Audio.shared.play(.tap) }) {
                        Txt(t.rawValue, 15, tool == t ? .white : Pal.ink, align: .center).padding(.vertical, 8).frame(maxWidth: .infinity)
                            .panel(tool == t ? Pal.orange : .white)
                    }
                }
            }
            Txt(hint(pet), 15, align: .center)
            if game.mainPet?.id == pet.id { Txt("⭐ \(pet.name) is your main pet and stays by your side!", 14, Pal.darkGreen, align: .center) }
            else { Btn("⭐ Make \(pet.name) my main pet", Pal.orange, size: 15) { game.setMainPet(pet.id) } }
            Txt("Keep every meter high and \(pet.name) finds you a little gift each day! 🎁", 13, Pal.brown, align: .center)
        }
    }

    private func hint(_ pet: Pet) -> String {
        switch tool {
        case .feed: "Drag the \(pet.kind.food) to \(pet.name)! (\(bites)/3 bites)"
        case .wash: rinsing ? "Drag over the bubbles to rinse them off! 🚿" : "Rub \(pet.name) to make bubbles! (\(bubbles.count)/\(petBubbles))"
        case .cuddle: "Rub \(pet.name) for cuddles! Tap for a silly surprise."
        }
    }

    private func reset() { tool = .feed; food = nil; bites = 0; rub = 0; rinsing = false; bubbles = []; hearts = [] }

    private func show(_ text: String) {
        bubble = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) { if bubble == text { bubble = nil } }
    }

    private func hop() {
        withAnimation(.easeOut(duration: 0.15)) { jump = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { withAnimation(.easeIn(duration: 0.3)) { jump = false } }
    }

    private func drag(_ pet: Pet, at p: CGPoint, d: CGPoint) {
        let dist = hypot(d.x, d.y)
        switch tool {
        case .feed:
            if let f = food { food = CGPoint(x: f.x + d.x, y: f.y + d.y) }
        case .wash:
            if !rinsing {
                if bubbles.last.map({ hypot($0.x - p.x, $0.y - p.y) > 24 }) ?? true {
                    bubbles.append(p); if bubbles.count % 3 == 0 { Audio.shared.play(.pop) }
                    if bubbles.count >= petBubbles { rinsing = true; show("Bubbly! Now rinse 🚿") }
                }
            } else {
                let before = bubbles.count
                bubbles.removeAll { hypot($0.x - p.x, $0.y - p.y) < 44 }
                if bubbles.count < before { Audio.shared.play(.tap) }
                if bubbles.isEmpty { rinsing = false; game.washPet(pet.id); show("*shakes off* Fresh and fluffy! ✨"); hop() }
            }
        case .cuddle:
            let before = rub
            rub += dist
            if Int(rub / 70) > Int(before / 70) { hearts.append(p); if hearts.count > 8 { hearts.removeFirst() }; Audio.shared.play(.tap) }
            if rub >= petRub { rub = 0; game.cuddlePet(pet.id); show(pet.kind.jokes.randomElement()!); hop() }
        }
    }

    private func dropFood(_ pet: Pet) {
        guard tool == .feed, let f = food else { return }
        if hypot(f.x - petCenter.x, f.y - petCenter.y) < 80 {
            bites += 1; Audio.shared.play(.munch); hop()
            if bites >= 3 { bites = 0; game.feedPet(pet.id); show("\(pet.kind.noise) Yum yum! \(pet.kind.food)") }
        }
        food = nil
    }
}

private struct Breathe: ViewModifier {
    @State private var on = false
    func body(content: Content) -> some View {
        content.scaleEffect(x: on ? 0.98 : 1, y: on ? 1.04 : 1, anchor: .bottom)
            .onAppear { withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { on = true } }
    }
}

private struct Meter: View {
    let label: String
    let frac: Double
    let color: Color
    var body: some View {
        VStack(spacing: 2) {
            Txt(label, 13)
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Color(hex: 0xD5DBE6))
                    Rectangle().fill(frac < 0.3 ? Pal.red : color).frame(width: g.size.width * min(1, max(0.02, frac)))
                }
            }
            .frame(height: 12).clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Pets wandering around your living room

private let reactions = ["*boing!*", "Hehe!", "*sneeze*", "Hi hi!", "*spins*", "Snack?", "*happy wiggle*"]

/// One pet strolling back and forth across the floor. Tap it for a funny reaction.
struct WanderingPet: View {
    let pet: Pet
    let roomW: CGFloat
    let floorY: CGFloat
    let index: Int
    let now: Double
    @State private var said: String?
    @State private var spin = 0.0

    var body: some View {
        // walk, pause, walk back, pause
        let period = 9.0 + Double(index) * 2.3
        let p = (now / period + Double(index) * 0.37).truncatingRemainder(dividingBy: 1)
        let walkFrac: Double = p < 0.4 ? p / 0.4 : p < 0.5 ? 1 : p < 0.9 ? 1 - (p - 0.5) / 0.4 : 0
        let walking = p < 0.4 || (p >= 0.5 && p < 0.9)
        let left = 30 + CGFloat(index) * 40
        let x = left + CGFloat(walkFrac) * (roomW - 150 - left)
        let hop = abs(sin(now * 12))
        let line = said ?? (pet.fullness(now) < 0.3 ? "\(pet.kind.food)?" : pet.cleanness(now) < 0.3 ? "🦨" : nil)
        VStack(spacing: 0) {
            if let line { Txt(line, 11).padding(.horizontal, 4).padding(.vertical, 1).panel(.white, radius: 6) }
            Tap(action: {
                said = (reactions.randomElement() ?? "") + " " + pet.kind.noise
                withAnimation(.easeInOut(duration: 0.5)) { spin += 360 }
                Audio.shared.play(.pop)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { said = nil }
            }) {
                Px(pet.kind.sprite, 46)
                    .scaleEffect(x: p >= 0.5 && p < 0.9 ? -1 : 1, y: 1)
                    .rotationEffect(.degrees(walking ? (hop - 0.5) * 10 : 0))
                    .rotation3DEffect(.degrees(spin), axis: (x: 0, y: 1, z: 0))
                    .offset(y: walking ? -hop * 5 : 0)
            }
        }
        .position(x: x + 23, y: floorY - 48 + CGFloat(index * 6) + 23)
    }
}

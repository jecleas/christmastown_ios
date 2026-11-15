import SwiftUI
import Combine
import Observation

// Port of the Android MoreGames.kt sleigh flight. Keep the two in sync.

// ======================================================================
// MARK: - Sleigh flight: steer around clouds, drop presents down chimneys
// ======================================================================

private let houseGap: CGFloat = 230
private let sleighX: CGFloat = 40
private let gravity: CGFloat = 520

@MainActor @Observable final class FlightSim {
    struct Falling { var x: CGFloat; var y: CGFloat; var vy: CGFloat }   // x in world units
    struct Cloud { let x: CGFloat; let y: CGFloat; let w: CGFloat; var bonked = false }
    let flight: Flight
    let power: Int
    let seed = Int.random(in: 0..<1000)
    var elapsed = 0.0
    var world: CGFloat = 0
    var sleighY: CGFloat = 200
    var aimY: CGFloat = 200
    var bonkUntil = -1.0
    var delivered = 0
    var message = "Drag up & down to steer. Tap to drop a present!"
    var visited: Set<Int> = []
    var falling: [Falling] = []
    var clouds: [Cloud] = []
    var nextCloud: CGFloat = 500

    init(flight: Flight, power: Int) { self.flight = flight; self.power = power }

    func nice(_ i: Int) -> Bool {
        if i < 1 { return true }
        var g = SeededGen(UInt64(bitPattern: Int64(i * 7919 + seed)))
        return Double(g.next() >> 11) / Double(1 << 53) >= flight.naughtyChance
    }

    /// `deliver` hands a present to the game; returns false if there are none.
    func step(_ dt: Double, w: CGFloat, h: CGFloat, deliver: () -> Bool) {
        elapsed += dt
        let roofY = h - 230, minY: CGFloat = 150, maxY = roofY - 120
        let bonked = elapsed < bonkUntil
        world += CGFloat(dt) * flight.speed * (bonked ? 0.4 : 1)
        let follow = 3 + CGFloat(power) * 1.2
        sleighY += (aimY - sleighY) * min(1, CGFloat(dt) * follow)
        if world + w > nextCloud {
            clouds.append(Cloud(x: nextCloud + 40, y: minY - 20 + CGFloat.random(in: 0...1) * (maxY - minY + 40), w: 90 + CGFloat.random(in: 0...60)))
            nextCloud += flight.cloudEvery * (0.7 + CGFloat.random(in: 0...0.6))
        }
        clouds.removeAll { $0.x - world < -300 }
        for i in clouds.indices where !clouds[i].bonked {
            let cx = clouds[i].x - world
            if cx < sleighX + 170 && cx + clouds[i].w > sleighX + 10 && abs((clouds[i].y + 20) - (sleighY + 30)) < 42 {
                clouds[i].bonked = true
                bonkUntil = elapsed + (0.9 - Double(power) * 0.15)
                message = power >= teamSize ? "Whoosh! Your happy team zooms through the cloud! 🦌✨"
                    : ["Bonk! ☁️ Brrr, cloudy!", "Ack! A cloud in Santa's beard! ☁️", "Pfft! Cloud up the reindeer's nose! 🤧"].randomElement()!
                Audio.shared.play(.oops)
            }
        }
        var keep: [Falling] = []
        for var f in falling {
            f.vy += gravity * CGFloat(dt); f.y += f.vy * CGFloat(dt); f.x += flight.speed * 0.45 * CGFloat(dt)
            let i = Int(floor((f.x - 300) / houseGap))
            let chimney = 300 + CGFloat(i) * houseGap + 103
            if f.y >= roofY + 4 && f.y < roofY + 30 && abs(f.x - chimney) < 26 && !visited.contains(i) {
                visited.insert(i)
                if nice(i) {
                    if deliver() { delivered += 1; message = ["Down the chimney! 🎁", "Bullseye! Ho ho ho! 🎅", "A happy kid tomorrow! 😊", "Perfect drop! ✨"].randomElement()! }
                } else { message = "Oops, a naughty house! They get coal instead 🪨"; Audio.shared.play(.oops) }
            } else if f.y > h {
                message = ["Plop! A snowman got a present 😂", "Missed! A very lucky squirrel 🐿️", "Into the snow! Aim for the chimney 🎯"].randomElement()!
            } else { keep.append(f) }
        }
        falling = keep
    }
}

/// Small repeatable random numbers so a house stays nice or naughty for the whole ride.
struct SeededGen: RandomNumberGenerator {
    var state: UInt64
    init(_ seed: UInt64) { state = seed &+ 0x9E3779B97F4A7C15 }
    mutating func next() -> UInt64 { state = state &* 6364136223846793005 &+ 1442695040888963407; return state }
}

struct DeliveryView: View {
    let game: GameState
    @State private var sim: FlightSim
    @State private var team: [String]
    @State private var finishing = false
    /// Fixed when the ride starts (job.done goes up as you deliver, so don't recompute it).
    private let target: Int
    private let timer = Timer.publish(every: 1.0 / 60, on: .main, in: .common).autoconnect()
    @State private var steer: CGFloat?

    @MainActor init(game: GameState) {
        self.game = game
        let christmas = game.christmasEveRide
        _sim = State(initialValue: FlightSim(flight: flightFor(game.level, christmasEve: christmas), power: game.teamPower))
        _team = State(initialValue: Array(game.sleighTeam.sorted { ($0 == "Rudolph" ? 0 : 1) < ($1 == "Rudolph" ? 0 : 1) }.reversed()))
        let job = game.s.jobs.first { $0.kind == .deliver }
        target = christmas ? 8 : (job.map { $0.goal - $0.done } ?? 0)
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let roofY = h - 230
            ZStack(alignment: .topLeading) {
                Canvas { ctx, size in draw(&ctx, size, roofY) }
                VStack(spacing: 6) {
                    Txt(game.christmasEveRide ? "🌟 Christmas Eve 🌟" : "🛷 Present Delivery", 26, .white)
                    Txt("Delivered \(sim.delivered) / \(target)", 22, Pal.gold)
                    Txt(sim.message, 17, .white, align: .center).padding(.horizontal, 12)
                    if sim.flight.foggy {
                        Txt(team.contains("Rudolph") ? "🔴 Rudolph's nose lights the way!" : "🌫️ Foggy night! Hitch Rudolph to light the way", 14, Pal.pink)
                    }
                }
                .frame(width: w).padding(.top, 14)
                .allowsHitTesting(false)
                if !game.christmasEveRide {
                    Btn("🏠 Fly home", Pal.blue, size: 18, width: 180) { game.endDelivery(finishedChristmas: false) }
                        .position(x: w / 2, y: h - 40)
                }
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 4)
                .onChanged { v in
                    let start = steer ?? sim.aimY
                    if steer == nil { steer = sim.aimY }
                    sim.aimY = min(roofY - 120, max(150, start + v.translation.height))
                }
                .onEnded { _ in steer = nil })
            .simultaneousGesture(TapGesture().onEnded { drop() })
            .onReceive(timer) { _ in
                sim.step(1.0 / 60, w: w, h: h) { game.deliver() }
                if sim.delivered >= target && !finishing {
                    finishing = true
                    sim.message = "All presents delivered! 🎉"
                    Audio.shared.play(.levelUp)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { game.endDelivery(finishedChristmas: true) }
                }
            }
        }
        .background(LinearGradient(colors: [Color(hex: 0x0E1633), Color(hex: 0x2B3A75)], startPoint: .top, endPoint: .bottom))
    }

    private func drop() {
        guard !finishing, sim.falling.isEmpty else { return }
        if !game.christmasEveRide && game.presents == 0 { game.say("No presents left! Make toys in the Workshop 🧸"); Audio.shared.play(.oops); return }
        sim.falling.append(.init(x: sim.world + sleighX + 40, y: sim.sleighY + 40, vy: 0))
        Audio.shared.play(.tap)
    }

    private func sprite(_ ctx: inout GraphicsContext, _ img: UIImage, _ at: CGPoint, _ h: CGFloat, flip: Bool = false) {
        let w = h * img.size.width / max(1, img.size.height)
        var c = ctx
        if flip { c.translateBy(x: at.x * 2 + w, y: 0); c.scaleBy(x: -1, y: 1) }
        c.draw(Image(uiImage: img).interpolation(.none).resizable(), in: CGRect(x: at.x, y: at.y, width: w, height: h))
    }

    private func draw(_ ctx: inout GraphicsContext, _ size: CGSize, _ roofY: CGFloat) {
        let s = sim
        ctx.fill(Path(ellipseIn: CGRect(x: size.width * 0.82 - 36, y: 114, width: 72, height: 72)), with: .color(Color(hex: 0xFFF3B0)))
        for i in 0..<40 {
            ctx.fill(Path(CGRect(x: CGFloat((i * 131) % 1000) / 1000 * size.width, y: CGFloat((i * 71) % 500) / 1000 * size.height, width: 3, height: 3)), with: .color(.white))
        }
        let first = Int(floor((s.world - 300) / houseGap)) - 1
        for i in first...(first + 4) {
            drawHouse(&ctx, CGPoint(x: 300 + CGFloat(i) * houseGap - s.world, y: roofY), nice: s.nice(i), done: s.visited.contains(i), seed: i)
        }
        ctx.fill(Path(CGRect(x: 0, y: roofY + 160, width: size.width, height: size.height)), with: .color(.white))
        for c in s.clouds {
            let cx = c.x - s.world, col = (c.bonked ? Color(hex: 0xC9CED8) : .white).opacity(0.9)
            for (fx, dy, r) in [(0.25, 26.0, 26.0), (0.5, 16.0, 34.0), (0.78, 28.0, 24.0)] as [(CGFloat, CGFloat, CGFloat)] {
                ctx.fill(Path(ellipseIn: CGRect(x: cx + c.w * fx - r, y: c.y + dy - r, width: r * 2, height: r * 2)), with: .color(col))
            }
            ctx.fill(Path(roundedRect: CGRect(x: cx, y: c.y + 26, width: c.w, height: 26), cornerRadius: 13), with: .color(col))
        }
        for f in s.falling {
            let p = CGPoint(x: f.x - s.world, y: f.y)
            ctx.fill(Path(CGRect(x: p.x - 11, y: p.y - 11, width: 22, height: 22)), with: .color(Pal.ink))
            ctx.fill(Path(CGRect(x: p.x - 9, y: p.y - 9, width: 18, height: 18)), with: .color(Pal.red))
            ctx.fill(Path(CGRect(x: p.x - 2, y: p.y - 9, width: 4, height: 18)), with: .color(Pal.gold))
        }
        let shake = s.elapsed < s.bonkUntil ? sin(s.elapsed * 60) * 4 : 0
        let sy = s.sleighY + shake
        sprite(&ctx, Sprites.named("santa"), CGPoint(x: sleighX + 14, y: sy - 26), 52)
        sprite(&ctx, Sprites.named("sleigh"), CGPoint(x: sleighX, y: sy + 6), 46)
        for (k, name) in team.enumerated() {
            let rx = sleighX + 104 + CGFloat(k) * 40, ry = sy - 6 + sin(s.elapsed * 6 + Double(k)) * 3
            var line = Path(); line.move(to: CGPoint(x: sleighX + 96, y: sy + 20)); line.addLine(to: CGPoint(x: rx + 20, y: ry + 28))
            ctx.stroke(line, with: .color(Color(hex: 0x8A5A3A)), lineWidth: 2)
            sprite(&ctx, Sprites.reindeer(name, decos: game.decosOn(name)), CGPoint(x: rx, y: ry), 36, flip: true)
        }
        if s.flight.foggy {
            let nose = CGPoint(x: sleighX + 104 + CGFloat(max(0, team.count - 1)) * 40 + 38, y: sy + 9)
            let glow: CGFloat = game.reindeer.contains("Rudolph") ? 1 : 0.6
            // a soft beam from the nose down to the rooftops, so you can still aim at chimneys
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .radialGradient(
                Gradient(stops: [.init(color: .clear, location: 0), .init(color: .clear, location: 0.5), .init(color: Color(hex: 0x0E1633, opacity: 0.6), location: 1)]),
                center: CGPoint(x: nose.x + 60, y: nose.y + 140), startRadius: 0, endRadius: 420 * glow))
            if team.contains("Rudolph") {
                ctx.fill(Path(ellipseIn: CGRect(x: nose.x - 40, y: nose.y - 40, width: 80, height: 80)),
                         with: .radialGradient(Gradient(colors: [Color(hex: 0xFF4050, opacity: 0.55), .clear]), center: nose, startRadius: 0, endRadius: 40))
            }
        }
    }

    /// A rooftop with a chimney at (x + 103, y + 4). 140 × 160.
    private func drawHouse(_ ctx: inout GraphicsContext, _ at: CGPoint, nice: Bool, done: Bool, seed: Int) {
        let wall = [0xE8C7A0, 0xC9E0F2, 0xF2C9D6, 0xD8EBC6][((seed % 4) + 4) % 4]
        func r(_ c: Color, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) { ctx.fill(Path(CGRect(x: at.x + x, y: at.y + y, width: w, height: h)), with: .color(c)) }
        r(Pal.ink, 89, 5, 28, 40); r(Color(hex: 0x6B4A3A), 92, 8, 22, 34); r(.white, 88, 4, 30, 7)
        if !done { r(Pal.ink, 95, 10, 16, 4) }
        var roof = Path(); roof.move(to: CGPoint(x: at.x, y: at.y + 60)); roof.addLine(to: CGPoint(x: at.x + 70, y: at.y + 14)); roof.addLine(to: CGPoint(x: at.x + 140, y: at.y + 60)); roof.closeSubpath()
        ctx.fill(roof, with: .color(nice ? Color(hex: 0xA02338) : Color(hex: 0x4A4458)))
        r(.white, 8, 54, 124, 7); r(Pal.ink, 12, 60, 116, 100); r(Color(hex: UInt32(wall)), 15, 63, 110, 97)
        let lit = done && nice ? Color(hex: 0xFFE27A) : nice ? Pal.gold : Color(hex: 0x3A3550)
        r(Pal.ink, 26, 80, 30, 30); r(lit, 29, 83, 24, 24); r(Pal.ink, 84, 80, 30, 30); r(lit, 87, 83, 24, 24)
        r(Color(hex: 0x6B4A3A), 57, 118, 26, 42)
        if done {
            let c = CGPoint(x: at.x + 103, y: at.y - 14)
            if nice {
                ctx.fill(Path(CGRect(x: c.x - 9, y: c.y - 9, width: 18, height: 18)), with: .color(Pal.red))
                ctx.fill(Path(CGRect(x: c.x - 2, y: c.y - 9, width: 4, height: 18)), with: .color(Pal.gold))
            } else { ctx.fill(Path(ellipseIn: CGRect(x: c.x - 9, y: c.y - 9, width: 18, height: 18)), with: .color(Pal.ink)) }
        }
    }
}

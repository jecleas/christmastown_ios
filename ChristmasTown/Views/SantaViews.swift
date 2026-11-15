import SwiftUI

// MARK: - Santa's naughty / nice list

struct SantaListView: View {
    let game: GameState
    @State private var feedback: String?

    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .bottom, spacing: 8) {
                Px("santa", 150).bob(3, 0.9)
                Bubble(text: game.level < 2 ? "Ho ho ho! You can help with my list at Level 2. Keep working hard!" : "Ho ho ho! Read what each kid did. Naughty or nice?", width: 210)
            }
            JobChip(game: game, kind: .sortList)
            VStack(spacing: 10) {
                Txt("📜 Santa's List", 24)
                let job = game.s.jobs.first { $0.kind == .sortList }
                if job == nil {
                    Txt("Unlocks at Level 2! 🔒", 18)
                } else if let kid = game.currentKid, job?.finished == false {
                    Txt(kid.name, 32, Pal.red)
                    Txt("“\(kid.deed)”", 20, align: .center)
                    HStack(spacing: 12) {
                        Btn("😈 Naughty", Pal.ink, size: 19) { feedback = game.sortKid(nice: false) ? "Correct! \(kid.name) gets coal 🪨" : "Hmm, \(kid.name) was actually nice! 😇" }
                        Btn("😇 Nice", Pal.green, size: 19) { feedback = game.sortKid(nice: true) ? "Correct! \(kid.name) gets a present 🎁" : "Hmm, \(kid.name) was actually naughty! 😈" }
                    }
                } else {
                    Txt("Checked it twice! ✅", 20, Pal.darkGreen)
                }
                if let f = feedback { Txt(f, 16, Pal.darkGreen, align: .center) }
            }
            .padding(16).frame(maxWidth: .infinity).panel(Color(hex: 0xFFF6DD))
        }
    }
}

// MARK: - Sleigh (before take-off)

struct SleighView: View {
    let game: GameState
    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .bottom, spacing: -12) { Px("sleigh", 80); Px("santa", 80).offset(y: -30) }.bob(5, 0.9).frame(height: 170, alignment: .bottom)
            JobChip(game: game, kind: .deliver)
            VStack(spacing: 10) {
                if let job = game.s.jobs.first(where: { $0.kind == .deliver }) {
                    if job.finished {
                        Txt("All of today's presents are delivered! ✅", 19, Pal.darkGreen, align: .center)
                    } else {
                        Txt("Fly over town and tap the 😇 nice houses to drop presents!", 17, align: .center)
                        HStack(spacing: 6) { Px("gift", 30); Txt("You have \(game.presents) toys to give", 17) }
                        if game.presents == 0 { Txt("Make toys in the Workshop first! 🧸", 15, Pal.red) }
                        Btn("🛷 Fly! (⚡10)", Pal.red, size: 22, width: 220) { game.startDelivery() }
                    }
                } else {
                    Txt("The sleigh unlocks at Level 3! 🔒", 19, align: .center)
                }
            }
            .padding(16).frame(maxWidth: .infinity).panel(Color(hex: 0xDDE7FF))
        }
    }
}

// MARK: - Sleigh ride

struct DeliveryView: View {
    let game: GameState
    @State private var start = Date()
    @State private var delivered = 0
    @State private var visited: Set<Int> = []
    @State private var message = "Tap the 😇 nice houses to drop presents!"
    private let gap: Double = 175, speed: Double = 80

    var target: Int {
        if game.christmasEveRide { return 8 }
        guard let job = game.s.jobs.first(where: { $0.kind == .deliver }) else { return 0 }
        return job.goal - job.done + delivered
    }

    var body: some View {
        TimelineView(.animation) { tl in
            let elapsed = tl.date.timeIntervalSince(start)
            GeometryReader { geo in
                let h = geo.size.height
                ZStack(alignment: .topLeading) {
                    LinearGradient(colors: [Color(hex: 0x0E1633), Color(hex: 0x2B3A75)], startPoint: .top, endPoint: .bottom)
                    Canvas { ctx, size in
                        ctx.fill(Path(ellipseIn: CGRect(x: size.width * 0.82 - 36, y: 150 - 36, width: 72, height: 72)), with: .color(Color(hex: 0xFFF3B0)))
                        for i in 0..<40 {
                            ctx.fill(Path(CGRect(x: Double((i * 131) % 1000) / 1000 * size.width, y: Double((i * 71) % 500) / 1000 * size.height, width: 3, height: 3)), with: .color(.white))
                        }
                    }
                    Snow(now: game.now)

                    // Sleigh flying along
                    HStack(alignment: .bottom, spacing: -8) {
                        Px("sleigh", 60)
                        Px("santa", 60).offset(y: -22)
                        Px(Sprites.reindeer(rudolph: true), 52).offset(x: 22, y: -16)
                    }
                    .offset(x: 60, y: h * 0.28 + 12 * sin(elapsed * 2))

                    // Rooftops scrolling past
                    let scroll = elapsed * speed
                    let first = Int(floor(scroll / gap))
                    ForEach(first...(first + 4), id: \.self) { i in
                        let x = 450 + Double(i) * gap - scroll - gap * 3
                        let nice = (i * 7 + 3) % 5 != 0
                        let done = visited.contains(i)
                        Tap(enabled: !done && delivered < target, action: { tapHouse(i, nice: nice) }) {
                            VStack(spacing: 0) {
                                Txt(done ? (nice ? "🎁" : "🪨") : nice ? "😇" : "😈", 30)
                                RoofHouse(nice: nice, done: done, seed: i)
                            }
                        }
                        .frame(width: 140)
                        .offset(x: x, y: h - 270)
                    }

                    VStack(spacing: 6) {
                        Txt(game.christmasEveRide ? "🌟 Christmas Eve 🌟" : "🛷 Present Delivery", 26, .white)
                        Txt("Delivered \(delivered) / \(target)", 22, Pal.gold)
                        Txt(message, 17, .white, align: .center)
                    }
                    .frame(width: geo.size.width).padding(.top, 14)

                    if !game.christmasEveRide {
                        Btn("🏠 Fly home", Pal.blue, size: 18, width: 180) { game.endDelivery(finishedChristmas: false) }
                            .position(x: geo.size.width / 2, y: h - 40)
                    }
                }
            }
        }
    }

    private func tapHouse(_ i: Int, nice: Bool) {
        if nice {
            guard game.deliver() else { return }
            visited.insert(i)
            delivered += 1
            message = ["Ho ho ho! 🎁", "Present delivered! ✨", "A happy kid tomorrow! 😊"].randomElement()!
            if delivered >= target {
                message = "All presents delivered! 🎉"
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { game.endDelivery(finishedChristmas: true) }
            }
        } else {
            visited.insert(i)
            message = "That's a naughty house! Coal for them 🪨"
        }
    }
}

struct RoofHouse: View {
    let nice: Bool
    let done: Bool
    let seed: Int
    var body: some View {
        let wall = [0xE8C7A0, 0xC9E0F2, 0xF2C9D6, 0xD8EBC6][((seed % 4) + 4) % 4]
        Canvas { ctx, _ in
            func r(_ c: Color, _ x: Double, _ y: Double, _ w: Double, _ h: Double) { ctx.fill(Path(CGRect(x: x, y: y, width: w, height: h)), with: .color(c)) }
            r(Color(hex: 0x6B4A3A), 92, 8, 22, 34); r(.white, 88, 4, 30, 7)
            var roof = Path(); roof.move(to: CGPoint(x: 0, y: 60)); roof.addLine(to: CGPoint(x: 70, y: 14)); roof.addLine(to: CGPoint(x: 140, y: 60)); roof.closeSubpath()
            ctx.fill(roof, with: .color(nice ? Color(hex: 0xA02338) : Color(hex: 0x4A4458)))
            r(.white, 8, 54, 124, 7); r(Pal.ink, 12, 60, 116, 100); r(Color(hex: UInt32(wall)), 15, 63, 110, 97)
            let lit = done && nice ? Color(hex: 0xFFE27A) : nice ? Pal.gold : Color(hex: 0x3A3550)
            r(Pal.ink, 26, 80, 30, 30); r(lit, 29, 83, 24, 24); r(Pal.ink, 84, 80, 30, 30); r(lit, 87, 83, 24, 24)
            r(Color(hex: 0x6B4A3A), 57, 118, 26, 42)
        }
        .frame(width: 140, height: 160)
    }
}

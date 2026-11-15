import SwiftUI

// MARK: - Greenhouse

struct GreenhouseView: View {
    let game: GameState

    var body: some View {
        let s = game.s
        VStack(spacing: 10) {
            Txt("Pick a seed, tap a pot to plant, water it, then pick your crops! 🌱", 15, align: .center)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(game.unlockedCrops, id: \.self) { c in
                        Tap(action: { game.selectedSeed = c }) {
                            VStack(spacing: 2) { Px(c.sprite, 30); Txt("\(c.title): \(s.seeds[c, default: 0])", 13) }
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .panel(game.selectedSeed == c ? Pal.paleGold : .white, border: game.selectedSeed == c ? Pal.red : Pal.ink)
                        }
                    }
                }
            }
            HStack(spacing: 8) {
                Btn("🌱 Plant all", Pal.green, size: 14) { game.plantAll() }
                Btn("💧 Water all", Pal.blue, size: 14) { game.waterAll() }
                Btn("🧺 Pick all", Pal.brown, size: 14) { game.pickAll() }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(128), spacing: 8), count: 3), spacing: 8) {
                ForEach(s.plots, id: \.id) { p in PlotBox(plot: p, now: game.now) { game.tapPlot(p.id) } }
            }
            HStack(spacing: 10) {
                Txt("Basket:", 15)
                ForEach(game.unlockedCrops, id: \.self) { c in HStack(spacing: 0) { Px(c.sprite, 24); Txt("×\(s.crops[c, default: 0])", 14) } }
            }
            .padding(8).frame(maxWidth: .infinity).panel()
        }
    }
}

struct PlotBox: View {
    let plot: Plot
    let now: Double
    let action: () -> Void

    var body: some View {
        Tap(action: action) {
            ZStack {
                VStack(spacing: 21) { ForEach(0..<3, id: \.self) { _ in Rectangle().fill(Color(hex: 0x6E4429)).frame(height: 5) } }.padding(.horizontal, 10)
                switch plot.stage(now) {
                case 0: Txt("+ Plant", 17, .white.opacity(0.85))
                case 1: VStack(spacing: 2) { Px("sprout", 38); Txt("💧 Water me!", 13, .white).bob() }
                case 2:
                    VStack(spacing: 4) {
                        Px("sprout", 38 + 18 * plot.progress(now))
                        ZStack(alignment: .leading) {
                            Rectangle().fill(.white.opacity(0.3)).frame(width: 90, height: 8)
                            Rectangle().fill(Pal.green).frame(width: 90 * plot.progress(now), height: 8)
                        }
                    }
                default: VStack(spacing: 0) { Px(plot.crop!.sprite, 56).bob(); Txt("Pick me! ✨", 13, .white) }
                }
            }
            .frame(width: 122, height: 98)
            .panel(Color(hex: 0x8A5A3A))
        }
    }
}

// MARK: - Bakery

struct BakeryView: View {
    let game: GameState
    @State private var baking: Cookie?

    var body: some View {
        let s = game.s
        VStack(spacing: 10) {
            JobChip(game: game, kind: .bake)
            HStack(alignment: .bottom, spacing: 14) {
                ElfPx(look: s.look, height: 140).bob()
                Oven(baking: baking)
            }
            ForEach(Cookie.allCases, id: \.self) { c in
                let locked = c.unlockLevel > game.level
                HStack(spacing: 8) {
                    Px(c.sprite, 48)
                    VStack(alignment: .leading, spacing: 2) {
                        Txt("\(c.title)  ×\(s.cookies[c, default: 0])", 16)
                        HStack(spacing: 3) {
                            ForEach(c.recipe, id: \.0) { crop, n in Txt("\(n)×", 13); Px(crop.sprite, 20) }
                            Txt(" ⚡5", 13)
                        }
                    }
                    Spacer()
                    if locked { Tag("🔒 Lv \(c.unlockLevel)", Pal.grey) }
                    else {
                        Btn("Bake!", Pal.red, size: 16, width: 90, enabled: baking == nil) {
                            if game.canBake(c) {
                                baking = c
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { game.bake(c); baking = nil }
                            } else { game.bake(c) }   // shows the "not enough" message
                        }
                    }
                }
                .padding(8).panel(locked ? Color(hex: 0xD5DBE6) : .white)
            }
        }
    }
}

struct Oven: View {
    let baking: Cookie?
    var body: some View {
        ZStack {
            Canvas { ctx, _ in
                ctx.fill(Path(CGRect(x: 0, y: 0, width: 170, height: 180)), with: .color(Pal.ink))
                ctx.fill(Path(CGRect(x: 4, y: 4, width: 162, height: 172)), with: .color(Color(hex: 0xC9CED8)))
                ctx.fill(Path(CGRect(x: 20, y: 48, width: 130, height: 100)), with: .color(Pal.ink))
                ctx.fill(Path(CGRect(x: 24, y: 52, width: 122, height: 92)), with: .color(baking != nil ? Color(hex: 0xFF9A3C) : Color(hex: 0x3A2A3E)))
                for i in 0..<4 { ctx.fill(Path(CGRect(x: 26 + i * 34, y: 16, width: 16, height: 16)), with: .color(Pal.red)) }
            }
            if let b = baking { Px(b.sprite, 60).bob(3, 0.3) }
        }
        .frame(width: 170, height: 180)
    }
}

// MARK: - Stable

struct StableView: View {
    let game: GameState
    var body: some View {
        VStack(spacing: 10) {
            JobChip(game: game, kind: .reindeer)
            HStack(spacing: 4) { Px("carrot", 24); Txt("Carrots ×\(game.s.crops[.carrot, default: 0])  (grow more in the Greenhouse)", 14) }
                .padding(.horizontal, 10).padding(.vertical, 4).panel()
            ScrollView {
                LazyVGrid(columns: [GridItem(.fixed(198), spacing: 8), GridItem(.fixed(198), spacing: 8)], spacing: 8) {
                    ForEach(game.reindeer, id: \.self) { ReindeerCard(game: game, name: $0) }
                }
            }
        }
    }
}

struct ReindeerCard: View {
    let game: GameState
    let name: String
    var body: some View {
        let fed = game.s.fed.contains(name), brushed = game.s.brushed.contains(name), rudolph = name == "Rudolph"
        VStack(spacing: 4) {
            Px(Sprites.reindeer(rudolph: rudolph), 80).bob(fed && brushed ? 6 : 2, fed && brushed ? 0.4 : 0.9).frame(height: 86, alignment: .bottom)
            Txt(rudolph ? "\(name) 🔴" : name, 17)
            Txt((fed ? "🥕✅ " : "🥕❌ ") + (brushed ? "🪮✅" : "🪮❌"), 13)
            HStack(spacing: 6) {
                Btn("Feed", Pal.orange, size: 13, enabled: !fed) { game.feed(name) }
                Btn("Brush", Pal.blue, size: 13, enabled: !brushed) { game.brush(name) }
            }
        }
        .padding(8).panel(fed && brushed ? Pal.paleGreen : Pal.cream)
    }
}

// MARK: - Workshop

struct WorkshopView: View {
    let game: GameState
    @State private var toy: Toy = .teddy
    @State private var step = 0       // 0 = not started
    @State private var done = false

    var body: some View {
        VStack(spacing: 10) {
            JobChip(game: game, kind: .toys)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Toy.allCases, id: \.self) { t in
                        let locked = t.unlockLevel > game.level
                        Tap(enabled: step == 0, action: { if locked { game.say("\(t.title)s unlock at Level \(t.unlockLevel) 🔒") } else { toy = t; done = false } }) {
                            VStack(spacing: 2) { Px(t.sprite, 40, alpha: locked ? 0.3 : 1); Txt(locked ? "🔒 Lv\(t.unlockLevel)" : "×\(game.s.toys[t, default: 0])", 12) }
                                .frame(width: 70).padding(4)
                                .panel(toy == t ? Pal.paleGold : .white, border: toy == t ? Pal.red : Pal.ink)
                        }
                    }
                }
            }
            ZStack {
                Px(toy.sprite, 200, alpha: 0.15)
                Px(toy.sprite, 200, reveal: done ? 1 : CGFloat(step) / CGFloat(toy.steps.count)).bob(done ? 8 : 0, 0.3)
            }
            .frame(width: 294, height: 244).panel(Color(hex: 0xC98B5E))
            Txt(done ? "Ta-da! A \(toy.title)! 🎁" : step == 0 ? "Make a \(toy.title)!" : "Step \(step) of \(toy.steps.count)", 20, align: .center)
            if !done {
                if step == 0 {
                    Btn("🔨 Start (⚡5)", Pal.red, size: 20, width: 220) { if game.startToy() { step = 1 } }
                } else {
                    Btn(toy.steps[step - 1] + "!", Pal.green, size: 20, width: 260) {
                        if step == toy.steps.count {
                            done = true
                            game.finishToy(toy)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) { done = false; step = 0 }
                        } else { step += 1; Audio.shared.play(.pop) }
                    }
                }
            }
            ElfPx(look: game.s.look, height: 110).bob()
        }
    }
}

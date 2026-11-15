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


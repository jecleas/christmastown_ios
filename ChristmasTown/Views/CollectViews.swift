import SwiftUI

// Port of the Android Collect.kt (advent calendar + sticker book). Keep the two in sync.

/// A small square button for the bottom row of the main screen, with an optional badge.
struct CornerButton: View {
    let icon: String
    let color: Color
    let badge: String?
    let action: () -> Void
    var body: some View {
        Btn(icon, color, size: 20, width: 58, action: action)
            .overlay(alignment: .topTrailing) {
                if let badge { Txt(badge, 12, .white).padding(.horizontal, 5).padding(.vertical, 1).background(RoundedRectangle(cornerRadius: 8).fill(Pal.red)).offset(x: 4, y: -6) }
            }
    }
}

// ======================================================================
// MARK: - Advent calendar: one surprise door a day, 1–24 December
// ======================================================================

struct AdventView: View {
    let game: GameState
    @State private var opened: (Int, Surprise)?

    var body: some View {
        let day = game.adventDay
        let done = game.adventOpenedThisYear
        VStack(spacing: 8) {
            Txt(day == 0 ? "The calendar opens on December 1st! 🎄 \(game.daysToAdvent) sleeps to go!"
                : Set(1...day).isSubset(of: done) ? "All caught up! Come back tomorrow for another door 🌙"
                : "Tap today's door for a surprise! Missed a day? Those doors still open. ✨", 16, .white, align: .center)
            VStack(spacing: 6) {
                ForEach(0..<6, id: \.self) { r in
                    HStack(spacing: 6) {
                        ForEach(adventOrder[(r * 4)..<(r * 4 + 4)], id: \.self) { d in
                            door(d, open: done.contains(d), ready: d <= day && !done.contains(d), today: d == day)
                        }
                    }
                }
            }
            .padding(8).panel(Color(hex: 0x7A1E2E))
            if let o = opened {
                VStack(spacing: 4) {
                    Txt("Door \(o.0): \(o.1.title)! 🎁", 18, Pal.red, align: .center)
                    Px(o.1.sprite, 60).bob(6, 0.3)
                    Txt(o.1.sprite == "gift" ? "It's in your Closet! 👗" : "It's yours! Check your house or snacks.", 14, Pal.brown)
                }
                .padding(10).frame(maxWidth: .infinity).panel(.white)
            }
        }
    }

    private func door(_ d: Int, open: Bool, ready: Bool, today: Bool) -> some View {
        Tap(enabled: ready, action: { if let g = game.openAdvent(d) { opened = (d, g) } }) {
            ZStack {
                if open { Px(adventSurprises[d - 1].sprite, 40) }
                else if ready { Txt("\(d)", 26, .white).bob(3, 0.5) }
                else { VStack(spacing: 0) { Txt("\(d)", 22, .white.opacity(0.6)); Txt("🔒", 11) } }
            }
            .frame(width: 86, height: 64)
            .panel(open ? Pal.cream : ready ? Pal.green : Pal.darkGreen, border: today && !open ? Pal.gold : Pal.ink)
        }
    }
}

// ======================================================================
// MARK: - Sticker book: collect a sticker for everything you do
// ======================================================================

struct StickerView: View {
    let game: GameState
    @State private var picked: Sticker?

    var body: some View {
        let have = game.s.stickers
        VStack(spacing: 8) {
            Txt("\(have.count) / \(stickers.count) stickers", 20, .white)
            HStack(spacing: 6) {
                ForEach(stickerPrizes, id: \.0) { at, prize in
                    let claimed = game.s.prizesClaimed.contains(at)
                    let ready = have.count >= at && !claimed
                    Tap(enabled: ready, action: { game.claimPrize(at) }) {
                        VStack(spacing: 0) {
                            Px(prize.sprite, 28, alpha: claimed ? 0.35 : 1)
                            Txt(claimed ? "✅" : ready ? "Claim!" : "\(at) ⭐", 12, ready ? Pal.red : Pal.ink)
                        }
                        .padding(4).frame(maxWidth: .infinity).panel(ready ? Pal.paleGold : .white, border: ready ? Pal.red : Pal.ink)
                    }
                }
            }
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Rectangle().fill(.white)
                    Rectangle().fill(Pal.gold).frame(width: g.size.width * CGFloat(have.count) / CGFloat(stickers.count))
                }
            }
            .frame(height: 14).clipShape(RoundedRectangle(cornerRadius: 4))
            if let st = picked {
                Txt((have.contains(st.id) ? "⭐ " : "🔒 ") + st.title, 15, align: .center).padding(8).frame(maxWidth: .infinity).panel(.white)
            }
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(58), spacing: 6), count: 6), spacing: 6) {
                    ForEach(stickers, id: \.id) { st in
                        let got = have.contains(st.id)
                        Tap(action: { picked = st; Audio.shared.play(.tap) }) {
                            ZStack {
                                if st.id.hasPrefix("deer:") { ReindeerPx(name: String(st.id.dropFirst(5)), decos: [], height: 26).opacity(got ? 1 : 0.18) }
                                else { Px(st.sprite, 34, alpha: got ? 1 : 0.18) }
                                if !got { Txt("?", 18, Pal.brown.opacity(0.6)) }
                            }
                            .frame(width: 52, height: 52)
                            .panel(got ? .white : Color(hex: 0xE7DCC4), border: got ? Pal.gold : Color(hex: 0xC9B994), radius: 29)
                        }
                    }
                }
                .padding(8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity).panel(Color(hex: 0xFFF6DD))
        }
        .onAppear { game.sawStickers() }
        .onChange(of: have.count) { game.sawStickers() }
    }
}

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
                        Txt("Steer around the clouds and drop presents down the chimneys of the nice houses!", 17, align: .center)
                        HStack(alignment: .bottom, spacing: 2) {
                            ForEach(game.sleighTeam, id: \.self) { r in ReindeerPx(name: r, decos: game.decosOn(r), height: 34, flip: true) }
                        }
                        Txt("Sleigh team: \(game.teamPower)/\(game.sleighTeam.count) happy (fed & brushed). Change the team in the Stable 🦌", 13, Pal.brown, align: .center)
                        HStack(spacing: 6) { Px("gift", 30); Txt("You have \(game.presents) presents to give" + (game.s.wrapped > 0 ? " (\(game.s.wrapped) wrapped)" : ""), 16) }
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


import SwiftUI

@main
struct ChristmasTownApp: App {
    init() { Sprites.load() }
    var body: some Scene { WindowGroup { RootView() } }
}

/// Every screen is laid out on a stage 430 wide (and at least 860 tall), then scaled to fit the phone or iPad.
private let stageW: CGFloat = 430
private let minStageH: CGFloat = 860

struct RootView: View {
    @State private var game = GameState()
    @Environment(\.scenePhase) private var phase

    var creating: Bool { !game.s.hasElf || game.showCreator }

    var song: Music {
        if game.overlay == .won || game.overlay == .christmasEve { return .joyToTheWorld }
        if game.delivering { return game.christmasEveRide ? .joyToTheWorld : .sleighRide }
        if creating { return .weWish }
        switch game.place {
        case nil: return .jingleBells
        case .greenhouse, .bakery, .stable, .workshop, .santaList: return .deckTheHalls
        case .sleigh: return .sleighRide
        case .shop, .friends, .phone, .closet: return .weWish
        case .decorate, .snacks: return .silentNight
        case .park: return .jingleBells
        case .pets: return .weWish
        }
    }

    var body: some View {
        let bgPlace: Place? = creating ? .closet : game.place
        GeometryReader { geo in
            let scale = min(geo.size.width / stageW, geo.size.height / minStageH)
            let stage = CGSize(width: geo.size.width / scale, height: geo.size.height / scale)
            ZStack {
                stageView { screen }
                    .frame(width: stage.width, height: stage.height)
                    .scaleEffect(scale)
                    .frame(width: geo.size.width, height: geo.size.height)
                if game.overlay != .none || game.showJobs {
                    Color.black.opacity(0.5).ignoresSafeArea().onTapGesture { game.showJobs = false }
                    Group { if game.overlay != .none { OverlayCard(game: game) } else { JobsCard(game: game) } }
                        .frame(width: stage.width, height: stage.height)
                        .scaleEffect(scale)
                        .frame(width: geo.size.width, height: geo.size.height)
                }
            }
        }
        .background {
            ZStack { placeBackground(bgPlace); Snow(now: game.now, count: bgPlace == nil || bgPlace!.dark ? 50 : 20) }.ignoresSafeArea()
        }
        .statusBarHidden()
        .onChange(of: song, initial: true) { _, s in Audio.shared.music(s) }
        .onChange(of: phase) { _, p in Audio.shared.setActive(p == .active) }
    }

    @ViewBuilder private func stageView<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        ZStack(alignment: .top) {
            content()
            if let t = game.toast {
                Txt(t, 17, .white, align: .center)
                    .padding(.horizontal, 14).padding(.vertical, 9)
                    .panel(Pal.ink.opacity(0.92), border: .white)
                    .frame(maxWidth: 400)
                    .padding(.top, 90)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .allowsHitTesting(false)
            }
        }
        .animation(.spring, value: game.toast)
    }

    @ViewBuilder private var screen: some View {
        if creating {
            Activity(game: game, title: "👗 My Elf", place: .closet, onBack: game.s.hasElf ? { game.showCreator = false } : nil) { CreatorView(game: game) }
        } else if game.delivering {
            DeliveryView(game: game)
        } else if let p = game.place {
            Activity(game: game, title: p.title, place: p, onBack: { game.go(nil) }) { placeView(p) }
        } else {
            HubView(game: game)
        }
    }

    @ViewBuilder private func placeView(_ p: Place) -> some View {
        switch p {
        case .greenhouse: GreenhouseView(game: game)
        case .bakery: BakeryView(game: game)
        case .stable: StableView(game: game)
        case .workshop: WorkshopView(game: game)
        case .santaList: SantaListView(game: game)
        case .sleigh: SleighView(game: game)
        case .decorate: DecorateView(game: game)
        case .shop: ShopView(game: game)
        case .closet: EmptyView()
        case .friends: FriendsView(game: game)
        case .phone: PhoneView(game: game)
        case .snacks: SnacksView(game: game)
        case .park: ParkView(game: game)
        case .pets: PetsView(game: game)
        }
    }
}

/// A full-screen activity: big Back button, title, money and energy, then the content.
struct Activity<Content: View>: View {
    let game: GameState
    let title: String
    let place: Place
    let onBack: (() -> Void)?
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                if let onBack { Btn("← Back", Pal.red, size: 17, width: 100, action: onBack) }
                Txt(title, 22, textColor(on: place), lines: 1)
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: 3) { MoneyChip(game: game); EnergyChip(game: game) }
            }
            content().frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
    }
}

// MARK: - Pop-ups

struct JobsCard: View {
    let game: GameState
    var body: some View {
        VStack(spacing: 8) {
            Txt("📋 Santa's Jobs Today", 24)
            ForEach(game.s.jobs, id: \.kind) { j in
                HStack(spacing: 8) {
                    Txt(j.kind.emoji, 20)
                    Txt(j.text, 16)
                    Spacer()
                    Txt(j.finished ? "✅" : "\(j.done)/\(j.goal)", 16)
                }
                .padding(8).panel(j.finished ? Pal.paleGreen : .white)
            }
            Txt(game.s.paidToday ? "All done! Santa paid you \(money(dailyPay)). Tap 💤 Sleep to start a new day." : "Finish ALL the jobs and Santa pays you \(money(dailyPay))!", 15, align: .center)
            Btn("OK!", Pal.green, width: 140) { game.showJobs = false }
        }
        .padding(18).frame(width: 400).panel()
    }
}

struct OverlayCard: View {
    let game: GameState
    var body: some View {
        VStack(spacing: 10) {
            switch game.overlay {
            case .none: EmptyView()
            case .paid(let newLevel):
                Px("santa", 110)
                Txt("Ho ho ho! Great work!", 26, Pal.red, align: .center)
                Txt("Santa paid you \(money(dailyPay))! 💰", 20, align: .center)
                if let l = newLevel {
                    Txt("⭐ LEVEL UP! You're now a \(levelTitles[l - 1])! ⭐", 19, Pal.green, align: .center)
                    Txt(unlocks(l), 15, align: .center)
                }
                Btn("Yay! 🎉", Pal.green, width: 160) { game.afterPaid() }
            case .morning(let day, let worked):
                Txt("☀️ Good morning!", 28)
                Txt("It's Day \(day) in Christmas Town.", 18, align: .center)
                Txt(worked ? "You worked hard yesterday. Santa is proud! 🎅" : "You didn't finish your jobs yesterday, so no pay. 💸\nWork today to earn \(money(dailyPay))!", 16, worked ? Pal.ink : Pal.red, align: .center)
                ElfPx(look: game.s.look, height: 100)
                Btn("Let's go! ❄️", Pal.green, width: 180) { game.overlay = .none }
            case .christmasEve:
                Txt("🌟 CHRISTMAS EVE! 🌟", 28, Pal.red)
                HStack(alignment: .bottom) { Px("santa", 100); Px("sleigh", 60) }
                Txt("Santa needs his best elf on the sleigh tonight. Deliver 8 presents to the nice kids!", 17, align: .center)
                Btn("Hop on the sleigh! 🛷", Pal.red, width: 260) { game.startChristmasEve() }
            case .won:
                Txt("🎄 YOU SAVED CHRISTMAS! 🎄", 24, Pal.red, align: .center)
                HStack(alignment: .bottom, spacing: 8) { ElfPx(look: game.s.look, height: 100); Px("santa", 110) }
                Txt("Every nice kid got a present. Santa says you're the best elf EVER, \(game.s.name)!\nKeep playing as long as you like.", 16, align: .center)
                Btn("Merry Christmas! 🎁", Pal.green, width: 240) { game.overlay = .none }
            }
        }
        .padding(22).frame(width: 400).panel()
    }

    func unlocks(_ level: Int) -> String {
        switch level {
        case 2: "New: Toy trains 🚂, berry cookies, Santa's naughty/nice list, more reindeer!"
        case 3: "New: Dolls, choc chip cookies, sleigh deliveries 🛷, a bigger greenhouse, more reindeer!"
        case 4: "New: Drums 🥁, more reindeer and trickier sleigh rides!"
        case 5: "New: Robots 🤖, another reindeer and windier sleigh rides! ☁️"
        case 6: "New: Rocking horses 🐴, gingerbread people, ginger seeds, a reindeer, and Santa wants presents WRAPPED 🎁"
        case 7: "New: Yo-yos, candy cane cookies, peppermint seeds, a reindeer, and the Town Tree needs decorating 🎄"
        case 8: "New: Snow globes, reindeer cookies, foggy sleigh nights... and RUDOLPH joins the stable! His nose glows! 🔴"
        default: ""
        }
    }
}

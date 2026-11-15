import SwiftUI

private func hearts(_ n: Int) -> String { String(repeating: "💖", count: n) + String(repeating: "🤍", count: max(0, 5 - n)) }

// MARK: - Friends: talk to other elves

struct FriendsView: View {
    let game: GameState
    @State private var talking = npcs[0]
    @State private var line = 0
    @State private var party = false

    var body: some View {
        VStack(spacing: 10) {
            Txt("Tap an elf to talk to them!", 18, .white)
            ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 6) {
                ForEach(npcs) { n in
                    Tap(action: { talking = n; line = 0; party = false; game.chat(n) }) {
                        VStack(spacing: 0) {
                            ElfPx(look: n.look, height: 84).bob(2, 0.8 + Double(n.name.count) * 0.06)
                            Txt(n.name, 15)
                            Txt(hearts(game.hearts(n)), 9)
                        }
                        .frame(width: 92).padding(4)
                        .panel(n == talking ? Pal.paleGold : Pal.cream, border: n == talking ? Pal.red : Pal.ink)
                    }
                }
            } }
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    ElfPx(look: talking.look, height: 120)
                    VStack(alignment: .leading, spacing: 4) {
                        Txt(talking.name, 26, Pal.red)
                        Txt(talking.job, 15, Pal.brown)
                        Txt(hearts(game.hearts(talking)), 15)
                        if game.s.bestGifts.contains(talking.name) { Tag("Best friends! 💖", Pal.pink, size: 13) }
                    }
                    Spacer()
                }
                if party {
                    Txt("Yay! Help me pick a theme for my party:", 18, align: .center)
                    ForEach(partyThemes, id: \.0) { theme, reward in Btn(theme, Pal.purple, size: 17) { game.throwParty(reward); party = false } }
                } else {
                    Txt("“\(talking.lines[line % talking.lines.count])”", 19, align: .center).padding(12).frame(maxWidth: .infinity).panel(.white)
                }
                HStack(spacing: 8) {
                    Btn("💬 Chat", Pal.blue, size: 16) { line += 1; game.chat(talking) }
                    Btn("🍪 Give cookie", Pal.orange, size: 16) { game.giveCookie(talking) }
                }
                if talking.name == "Twinkle" && !game.s.partyDone {
                    Btn("🎉 Plan a party", Pal.pink, size: 17, enabled: game.hearts(talking) >= 3) { party = true }
                    if game.hearts(talking) < 3 { Txt("Become better friends (3 💖) to plan a party!", 13, Pal.brown) }
                }
                Txt("Chat every day and give cookies to make friends. Best friends (5 💖) give you a gift!", 13, Pal.brown, align: .center)
            }
            .padding(14).panel()
        }
    }
}

// MARK: - Shop

private enum ShopTab: String, CaseIterable { case clothes = "👗 Clothes", hair = "💇 Hair", furniture = "🛋️ Furniture", decor = "🎄 Decor", food = "🍎 Food & Seeds" }

struct ShopView: View {
    let game: GameState
    @State private var tab: ShopTab = .clothes

    var body: some View {
        let s = game.s
        VStack(spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(ShopTab.allCases, id: \.self) { t in
                        Tap(action: { tab = t }) { Txt(t.rawValue, 15, tab == t ? .white : Pal.ink).padding(.horizontal, 10).padding(.vertical, 6).panel(tab == t ? Pal.purple : .white) }
                    }
                }
            }
            ScrollView {
                LazyVGrid(columns: [GridItem(.fixed(198), spacing: 10), GridItem(.fixed(198), spacing: 10)], spacing: 10) {
                    switch tab {
                    case .clothes:
                        ForEach(Outfit.allCases.filter { $0.price > 0 }, id: \.self) { o in
                            WearCard(title: o.title, price: o.price, preview: Sprites.elf(with(s.look) { $0.outfit = o }), owned: s.outfits.contains(o), wearing: s.look.outfit == o,
                                     buy: { game.buyOutfit(o) }, wear: { game.setLook(with(s.look) { $0.outfit = o }) })
                        }
                        ForEach(Hat.allCases.filter { $0.price > 0 }, id: \.self) { h in
                            WearCard(title: h.title, price: h.price, preview: Sprites.elf(with(s.look) { $0.hat = h }), owned: s.hats.contains(h), wearing: s.look.hat == h,
                                     buy: { game.buyHat(h) }, wear: { game.setLook(with(s.look) { $0.hat = h }) })
                        }
                        ForEach(Accessory.allCases.filter { $0.price > 0 }, id: \.self) { a in
                            WearCard(title: a.title, price: a.price, preview: Sprites.elf(with(s.look) { $0.accessory = a }), owned: s.accessories.contains(a), wearing: s.look.accessory == a,
                                     buy: { game.buyAccessory(a) }, wear: { game.setLook(with(s.look) { $0.accessory = a }) })
                        }
                    case .hair:
                        ForEach(HairStyle.allCases.filter { $0.price > 0 }, id: \.self) { h in
                            WearCard(title: h.title, price: h.price, preview: Sprites.elf(with(s.look) { $0.hairStyle = h; $0.hat = .none }), owned: s.hair.contains(h), wearing: s.look.hairStyle == h,
                                     buy: { game.buyHair(h) }, wear: { game.setLook(with(s.look) { $0.hairStyle = h }) })
                        }
                    case .furniture, .decor:
                        ForEach(Item.allCases.filter { $0.kind == (tab == .furniture ? .furniture : .decoration) }, id: \.self) { i in
                            Card {
                                Px(i.sprite, min(100, CGFloat(Sprites.rows(i.sprite).count) * 5)).frame(height: 104)
                                Txt(i.title, 16, align: .center, lines: 1)
                                Txt("You own \(s.owned[i, default: 0])", 13, Pal.brown)
                                Btn("Buy \(money(i.price))", Pal.red, size: 15, width: 150) { game.buyItem(i) }
                            }
                        }
                    case .food:
                        ForEach(Food.allCases, id: \.self) { f in
                            Card {
                                Px(f.sprite, 76).frame(height: 104)
                                Txt(f.title, 16, align: .center, lines: 1)
                                Txt("+\(f.energy)⚡ · have \(s.food[f, default: 0])", 13, Pal.brown)
                                Btn("Buy \(money(f.price))", Pal.red, size: 15, width: 150) { game.buyFood(f) }
                            }
                        }
                        ForEach(Crop.allCases, id: \.self) { c in
                            Card {
                                Px(c.sprite, 76).frame(height: 104)
                                Txt("\(c.title) seeds", 16, align: .center, lines: 1)
                                Txt(c.unlockLevel > game.level ? "🔒 Level \(c.unlockLevel)" : "have \(s.seeds[c, default: 0])", 13, Pal.brown)
                                Btn("Buy \(money(c.seedPrice))", Pal.red, size: 15, width: 150) { game.buySeed(c) }
                            }
                        }
                    }
                }
            }
        }
    }
}

func with<T>(_ value: T, _ change: (inout T) -> Void) -> T { var v = value; change(&v); return v }

private struct Card<Content: View>: View {
    @ViewBuilder let content: () -> Content
    var body: some View {
        VStack(spacing: 5) { content() }.padding(8).frame(width: 192, height: 220).panel()
    }
}

private struct WearCard: View {
    let title: String, price: Int, preview: UIImage, owned: Bool, wearing: Bool
    let buy: () -> Void, wear: () -> Void
    var body: some View {
        Card {
            Px(preview, 104).frame(height: 110)
            Txt(title, 16, align: .center, lines: 1)
            if wearing { Tag("Wearing ✨", Pal.green) }
            else if owned { Btn("Wear", Pal.blue, size: 15, width: 120, action: wear) }
            else { Btn("Buy \(money(price))", Pal.red, size: 15, width: 150, action: buy) }
        }
    }
}

// MARK: - Closet: make / change your elf

struct CreatorView: View {
    let game: GameState
    @State private var name = ""
    @State private var look = ElfLook()

    var body: some View {
        let s = game.s
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                ElfPx(look: look, height: 170).bob(4, 0.8)
                VStack(spacing: 8) {
                    TextField("", text: $name, prompt: Text("Elf name").foregroundStyle(Pal.ink.opacity(0.35)))
                        .font(.custom("Pixelify Sans", fixedSize: 22).weight(.bold)).foregroundStyle(Pal.ink)
                        .textInputAutocapitalization(.words).autocorrectionDisabled()
                        .onChange(of: name) { _, n in if n.count > 12 { name = String(n.prefix(12)) } }
                        .padding(.horizontal, 10).padding(.vertical, 8).panel(.white)
                    HStack(spacing: 8) {
                        chip("Girl", look.girl) { setGirl(true) }
                        chip("Boy", !look.girl) { setGirl(false) }
                    }
                    Btn(s.hasElf ? "Done! ✨" : "Start! 🎅", Pal.green, size: 20) { game.saveElf(name: name, look: look) }
                }
                .frame(width: 220)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    option("Skin") { ForEach(ElfColors.skins.indices, id: \.self) { i in swatch(ElfColors.skins[i], look.skin == i) { look.skin = i } } }
                    option("Hair") { ForEach(HairStyle.allCases, id: \.self) { h in preview(with(look) { $0.hairStyle = h; $0.hat = .none }, look.hairStyle == h, !s.hair.contains(h)) { look.hairStyle = h } } }
                    option("Hair color") { ForEach(ElfColors.hairs.indices, id: \.self) { i in swatch(ElfColors.hairs[i], look.hairColor == i) { look.hairColor = i } } }
                    option("Eyes") { ForEach(ElfColors.eyes.indices, id: \.self) { i in swatch(ElfColors.eyes[i], look.eye == i) { look.eye = i } } }
                    option("Outfit") { ForEach(Outfit.allCases, id: \.self) { o in preview(with(look) { $0.outfit = o }, look.outfit == o, !s.outfits.contains(o)) { look.outfit = o } } }
                    option("Outfit color") { ForEach(ElfColors.clothes.indices, id: \.self) { i in swatch(ElfColors.clothes[i], look.outfitColor == i) { look.outfitColor = i } } }
                    option("Hat") { ForEach(Hat.allCases, id: \.self) { h in preview(with(look) { $0.hat = h }, look.hat == h, !s.hats.contains(h)) { look.hat = h } } }
                    option("Hat color") { ForEach(ElfColors.clothes.indices, id: \.self) { i in swatch(ElfColors.clothes[i], look.hatColor == i) { look.hatColor = i } } }
                    option("Extras") { ForEach(Accessory.allCases, id: \.self) { a in preview(with(look) { $0.accessory = a }, look.accessory == a, !s.accessories.contains(a)) { look.accessory = a } } }
                    Txt("🔒 Locked things can be bought in the Shop!", 14, Pal.brown)
                }
                .padding(12)
            }
            .panel()
        }
        .onAppear { name = s.hasElf ? s.name : ""; look = s.look }
    }

    private func setGirl(_ girl: Bool) {
        guard look.girl != girl else { return }
        look.girl = girl
        look.hairStyle = girl ? .long : .short
        look.outfit = girl && game.s.outfits.contains(.dress) ? .dress : .tunic
    }

    private func option<C: View>(_ title: String, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Txt(title, 16)
            ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 8) { content() }.padding(2) }
        }
    }

    private func swatch(_ c: UInt32, _ selected: Bool, _ action: @escaping () -> Void) -> some View {
        Tap(action: action) {
            Circle().fill(Color(hex: c)).overlay(Circle().stroke(Pal.ink, lineWidth: 2)).frame(width: 30, height: 30)
                .padding(4).overlay(Circle().stroke(selected ? Pal.red : .clear, lineWidth: 3))
        }
    }

    private func chip(_ text: String, _ selected: Bool, _ action: @escaping () -> Void) -> some View {
        Tap(action: action) { Txt(text, 17, selected ? .white : Pal.ink).padding(.horizontal, 12).padding(.vertical, 5).panel(selected ? Pal.red : .white) }
    }

    private func preview(_ sample: ElfLook, _ selected: Bool, _ locked: Bool, _ action: @escaping () -> Void) -> some View {
        Tap(action: { if locked { game.say("That's in the Shop! 🛍️ Work for Santa to earn money.") } else { action() } }) {
            ZStack {
                Px(Sprites.elf(sample), 60, alpha: locked ? 0.35 : 1)
                if locked { Txt("🔒", 18) }
            }
            .frame(width: 54, height: 66).panel(selected ? Pal.paleGold : .white, border: selected ? Pal.red : Pal.ink)
        }
    }
}

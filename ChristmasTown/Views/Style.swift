import SwiftUI

// MARK: - Text

/// Pixel font text. Pixelify Sans is a variable font, so .weight() picks the thickness.
struct Txt: View {
    let text: String
    let size: CGFloat
    var color: Color = Pal.ink
    var weight: Font.Weight = .bold
    var align: TextAlignment = .leading
    var lines: Int? = nil

    init(_ text: String, _ size: CGFloat, _ color: Color = Pal.ink, weight: Font.Weight = .bold, align: TextAlignment = .leading, lines: Int? = nil) {
        self.text = text; self.size = size; self.color = color; self.weight = weight; self.align = align; self.lines = lines
    }

    var body: some View {
        Text(text)
            .font(.custom("Pixelify Sans", fixedSize: size).weight(weight))
            .foregroundStyle(color)
            .multilineTextAlignment(align)
            .lineLimit(lines)
    }
}

// MARK: - Panels & buttons

extension View {
    /// Pixel-style panel: rounded-square corners and a thick dark border.
    func panel(_ color: Color = Pal.cream, border: Color = Pal.ink, radius: CGFloat = 10) -> some View {
        self.background(RoundedRectangle(cornerRadius: radius - 3).fill(color))
            .padding(3)
            .background(RoundedRectangle(cornerRadius: radius).fill(border))
    }

    func bob(_ amount: CGFloat = 4, _ seconds: Double = 0.7) -> some View { modifier(Bob(amount: amount, seconds: seconds)) }
}

struct Bob: ViewModifier {
    let amount: CGFloat
    let seconds: Double
    @State private var up = false
    func body(content: Content) -> some View {
        content.offset(y: up ? -amount : 0)
            .onAppear { withAnimation(.easeInOut(duration: seconds).repeatForever(autoreverses: true)) { up = true } }
    }
}

/// Squishes a little when pressed.
struct Squish: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// A tappable thing that squishes (no tap sound).
struct Tap<Label: View>: View {
    var enabled = true
    let action: () -> Void
    @ViewBuilder let label: () -> Label
    var body: some View {
        Button(action: action, label: label).buttonStyle(Squish()).disabled(!enabled).opacity(enabled ? 1 : 0.5)
    }
}

/// Big chunky pixel button with a shadow and a tap sound.
struct Btn: View {
    let text: String
    let color: Color
    var size: CGFloat = 18
    var width: CGFloat? = nil
    var enabled = true
    let action: () -> Void

    init(_ text: String, _ color: Color, size: CGFloat = 18, width: CGFloat? = nil, enabled: Bool = true, action: @escaping () -> Void) {
        self.text = text; self.color = color; self.size = size; self.width = width; self.enabled = enabled; self.action = action
    }

    var body: some View {
        Button { Audio.shared.play(.tap); action() } label: {
            Txt(text, size, .white, align: .center)
                .padding(.horizontal, 14).padding(.vertical, 9)
                .frame(maxWidth: width == nil ? .infinity : width)
                .frame(width: width)
                .panel(color)
                .background(RoundedRectangle(cornerRadius: 10).fill(Pal.ink).offset(y: 4))
        }
        .buttonStyle(Squish())
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.5)
    }
}

struct Tag: View {
    let text: String
    var color: Color = Pal.red
    var size: CGFloat = 14
    init(_ text: String, _ color: Color = Pal.red, size: CGFloat = 14) { self.text = text; self.color = color; self.size = size }
    var body: some View {
        Txt(text, size, .white).padding(.horizontal, 8).padding(.vertical, 2).background(RoundedRectangle(cornerRadius: 6).fill(color))
    }
}

struct Bubble: View {
    let text: String
    var width: CGFloat = 220
    var body: some View {
        Txt(text, 15, align: .center).padding(10).frame(width: width).panel(.white)
    }
}

// MARK: - Snow & backgrounds

struct Snow: View {
    let now: Double
    var count = 50
    var body: some View {
        Canvas { ctx, size in
            for i in 0..<count {
                let speed = 18.0 + Double((i * 7) % 23)
                let x = Double((i * 97) % 1000) / 1000 * size.width + sin(now * 0.8 + Double(i)) * 12
                let y = (Double((i * 53) % 1000) / 1000 * size.height + now * speed).truncatingRemainder(dividingBy: size.height)
                let r = Double(2 + i % 3)
                ctx.fill(Path(CGRect(x: x, y: y, width: r, height: r)), with: .color(.white.opacity(0.85)))
            }
        }
        .allowsHitTesting(false)
    }
}

func placeBackground(_ p: Place?) -> LinearGradient {
    let colors: [UInt32]
    switch p {
    case nil, .decorate, .snacks, .phone: colors = [0x1D2B53, 0x3B4A8A]
    case .greenhouse: colors = [0xBFE9F5, 0xE7F7EC]
    case .bakery: colors = [0xFFE3C2, 0xF6C08E]
    case .stable: colors = [0x2F3F73, 0x6C5B8E]
    case .workshop: colors = [0xFFD9D2, 0xF2A8A0]
    case .santaList, .sleigh: colors = [0x7A1E2E, 0xB8364A]
    case .friends, .closet: colors = [0x2C4F8C, 0x8FB9E8]
    case .shop: colors = [0xE6DAFF, 0xC6B1F2]
    case .park: colors = [0x2C4F8C, 0x9BC8EE]
    case .pets: colors = [0xFFE3B0, 0xF7C27A]
    }
    return LinearGradient(colors: colors.map { Color(hex: $0) }, startPoint: .top, endPoint: .bottom)
}

func textColor(on p: Place?) -> Color { p == nil || p!.dark ? .white : Pal.ink }

// MARK: - Small shared pieces

struct MoneyChip: View {
    let game: GameState
    var body: some View { Txt("💰 \(money(game.s.money))", 16).padding(.horizontal, 8).padding(.vertical, 3).panel(Pal.paleGold) }
}

struct EnergyChip: View {
    let game: GameState
    var body: some View {
        HStack(spacing: 4) {
            Txt("⚡", 12)
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3).fill(Color(hex: 0xD5DBE6)).frame(width: 54, height: 9)
                RoundedRectangle(cornerRadius: 3).fill(game.s.energy > 25 ? Pal.gold : Pal.red).frame(width: 54 * CGFloat(game.s.energy) / 100, height: 9)
            }
            Txt("\(game.s.energy)", 12)
        }
        .padding(.horizontal, 8).padding(.vertical, 3).panel()
    }
}

struct JobChip: View {
    let game: GameState
    let kind: JobKind
    var body: some View {
        if let job = game.s.jobs.first(where: { $0.kind == kind }) {
            Txt("\(kind.emoji) \(job.text): \(job.finished ? "✅" : "\(job.done)/\(job.goal)")", 16, job.finished ? .white : Pal.ink, align: .center)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .panel(job.finished ? Pal.green : .white)
        }
    }
}

/// An elf's face in a little circle (the top of their sprite).
struct Face: View {
    let look: ElfLook
    let size: CGFloat
    var body: some View {
        ElfPx(look: look, height: size * 1.45)
            .offset(y: size * 0.18)
            .frame(width: size, height: size, alignment: .top)
            .background(Color(hex: 0xBFE9F5))
            .clipShape(Circle())
            .overlay(Circle().stroke(Pal.ink, lineWidth: 2))
    }
}

import SwiftUI
import UIKit

/// Loads the pixel art from sprites.txt (shared with the Android version) and turns it into crisp little images.
/// Each sprite is "@name" then rows of letters; each letter is a palette color, "." is see-through.
/// Capital letters are recolored per elf: S skin, Z skin shadow, H hair, J hair shadow, O outfit, Q outfit shadow, T hat, E eyes.
enum Sprites {
    private static var palette: [Character: UInt32] = [:]
    private static var sprites: [String: [String]] = [:]
    private static var cache: [String: UIImage] = [:]

    static func load() {
        guard sprites.isEmpty, let url = Bundle.main.url(forResource: "sprites", withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8) else { return }
        var current: String?
        for line in text.components(separatedBy: .newlines) {
            if line.hasPrefix("#") { continue }
            if line.hasPrefix("=") {
                let chars = Array(line)
                if chars.count >= 9, let v = UInt32(String(chars[3..<9]), radix: 16) { palette[chars[1]] = v }
            } else if line.hasPrefix("@") {
                current = String(line.dropFirst()).trimmingCharacters(in: .whitespaces)
                sprites[current!] = []
            } else if line.trimmingCharacters(in: .whitespaces).isEmpty {
                current = nil
            } else if let c = current {
                sprites[c, default: []].append(line)
            }
        }
    }

    static func rows(_ name: String) -> [String] { sprites[name] ?? [] }

    /// Lays `top` over `base`: any non-"." pixel in `top` wins.
    static func overlay(_ base: [String], _ top: [String]) -> [String] {
        let width = max(base.map(\.count).max() ?? 0, top.map(\.count).max() ?? 0)
        var grid = (0..<max(base.count, top.count)).map { y -> [Character] in
            let row = y < base.count ? Array(base[y]) : []
            return row + Array(repeating: ".", count: width - row.count)
        }
        for (y, row) in top.enumerated() {
            for (x, ch) in row.enumerated() where ch != "." { grid[y][x] = ch }
        }
        return grid.map { String($0) }
    }

    static func image(key: String, rows: [String], recolor: [Character: UInt32] = [:]) -> UIImage {
        if let img = cache[key] { return img }
        let w = max(rows.map(\.count).max() ?? 1, 1), h = max(rows.count, 1)
        var data = [UInt8](repeating: 0, count: w * h * 4)
        for (y, row) in rows.enumerated() {
            for (x, ch) in row.enumerated() {
                guard let c = recolor[ch] ?? palette[ch] else { continue }
                let i = (y * w + x) * 4
                data[i] = UInt8((c >> 16) & 0xFF); data[i + 1] = UInt8((c >> 8) & 0xFF); data[i + 2] = UInt8(c & 0xFF); data[i + 3] = 255
            }
        }
        let provider = CGDataProvider(data: Data(data) as CFData)!
        let cg = CGImage(width: w, height: h, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: w * 4,
                         space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                         provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)!
        let img = UIImage(cgImage: cg)
        cache[key] = img
        return img
    }

    static func named(_ name: String) -> UIImage { image(key: name, rows: rows(name)) }

    static func reindeer(rudolph: Bool) -> UIImage {
        image(key: "reindeer|\(rudolph)", rows: rows("reindeer"), recolor: ["N": rudolph ? 0xE5394B : 0x2B1D2E])
    }

    /// A reindeer wearing its decorations (same order as Android: blanket, bells, scarf, lights).
    static func reindeer(_ name: String, decos: Set<Deco>) -> UIImage {
        var r = rows("reindeer")
        for d in Deco.allCases where decos.contains(d) { r = overlay(r, rows(d.sprite)) }
        let rudolph = name == "Rudolph"
        return image(key: "rd|\(rudolph)|\(decos.sorted().map(\.rawValue))", rows: r, recolor: ["N": rudolph ? 0xFF2E3E : 0x2B1D2E])
    }

    // MARK: Elves

    private static func shade(_ c: UInt32, _ f: Double) -> UInt32 {
        let r = UInt32(Double((c >> 16) & 0xFF) * f), g = UInt32(Double((c >> 8) & 0xFF) * f), b = UInt32(Double(c & 0xFF) * f)
        return (r << 16) | (g << 8) | b
    }

    static func elf(_ look: ElfLook) -> UIImage {
        var r = rows("elf_base")
        if let o = look.outfit.sprite { r = overlay(r, rows(o)) }
        if let a = look.accessory.sprite { r = overlay(r, rows(a)) }
        r = overlay(r, rows(look.hairStyle.sprite))
        if let h = look.hat.sprite { r = overlay(r, rows(h)) }
        let skin = ElfColors.skins[look.skin % ElfColors.skins.count]
        let hair = ElfColors.hairs[look.hairColor % ElfColors.hairs.count]
        let outfit = ElfColors.clothes[look.outfitColor % ElfColors.clothes.count]
        let colors: [Character: UInt32] = [
            "S": skin, "Z": shade(skin, 0.85), "H": hair, "J": shade(hair, 0.75), "O": outfit, "Q": shade(outfit, 0.72),
            "T": ElfColors.clothes[look.hatColor % ElfColors.clothes.count], "E": ElfColors.eyes[look.eye % ElfColors.eyes.count],
        ]
        return image(key: "elf|\(look.hashValue)|\(look)", rows: r, recolor: colors)
    }
}

/// A pixel sprite drawn `height` tall with sharp pixels. `reveal` (0…1) shows only the top part (used when building toys).
struct Px: View {
    let image: UIImage
    let height: CGFloat
    var reveal: CGFloat = 1
    var alpha: Double = 1

    init(_ image: UIImage, _ height: CGFloat, reveal: CGFloat = 1, alpha: Double = 1) {
        self.image = image; self.height = height; self.reveal = reveal; self.alpha = alpha
    }
    init(_ name: String, _ height: CGFloat, reveal: CGFloat = 1, alpha: Double = 1) {
        self.init(Sprites.named(name), height, reveal: reveal, alpha: alpha)
    }

    var body: some View {
        let w = height * image.size.width / max(image.size.height, 1)
        Image(uiImage: image)
            .interpolation(.none)
            .resizable()
            .frame(width: w, height: height)
            .mask(alignment: .top) { Rectangle().frame(height: height * reveal) }
            .opacity(alpha)
    }
}

struct ElfPx: View {
    let look: ElfLook
    let height: CGFloat
    var body: some View { Px(Sprites.elf(look), height) }
}

/// A reindeer with its decorations. Rudolph's nose glows (and pulses).
struct ReindeerPx: View {
    let name: String
    let decos: Set<Deco>
    let height: CGFloat
    var flip = false
    @State private var glow = false

    var body: some View {
        let img = Sprites.reindeer(name, decos: decos)
        let px = height / max(img.size.height, 1)
        ZStack(alignment: .topLeading) {
            if name == "Rudolph" {
                Circle()
                    .fill(RadialGradient(colors: [Color(hex: 0xFF4050, opacity: 0.7), .clear], center: .center, startRadius: 0, endRadius: px * 6))
                    .frame(width: px * 12, height: px * 12)
                    .scaleEffect(glow ? 1.15 : 0.8)
                    .opacity(glow ? 1 : 0.45)
                    .offset(x: 1.5 * px - px * 6, y: 7.5 * px - px * 6)
                    .onAppear { withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) { glow = true } }
            }
            Px(img, height)
        }
        .scaleEffect(x: flip ? -1 : 1, y: 1)
    }
}

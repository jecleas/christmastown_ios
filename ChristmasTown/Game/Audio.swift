import AVFoundation

/// Sound effects (same files as Android).
enum Sfx: String, CaseIterable {
    case tap = "sfx_tap", coins = "sfx_coins", levelUp = "sfx_level_up", ding = "sfx_cookie_ding", sleighBells = "sfx_sleigh_bells"
    case pop = "sfx_toy_pop", message = "sfx_chat_message", presentDrop = "sfx_present_drop", munch = "sfx_reindeer_munch", oops = "sfx_oops"

    var volume: Float {
        switch self {
        case .tap: 0.35
        case .message, .oops: 0.6
        case .pop: 0.7
        case .ding, .sleighBells, .presentDrop, .munch: 0.8
        case .coins, .levelUp: 0.9
        }
    }
}

/// Background music: one song loops and cross-fades into the next.
enum Music: String {
    case jingleBells = "music_jingle_bells", deckTheHalls = "music_deck_the_halls", weWish = "music_we_wish"
    case silentNight = "music_silent_night", sleighRide = "music_sleigh_ride", joyToTheWorld = "music_joy_to_the_world"
    case oChristmasTree = "music_o_christmas_tree"            // Snow Park (the Town Tree)
    case upOnTheHousetop = "music_up_on_the_housetop"         // sleigh flight
    case jollyOldStNicholas = "music_jolly_old_st_nicholas"   // Pets
    case goodKingWenceslas = "music_good_king_wenceslas"      // snowball fight
    case twelveDays = "music_twelve_days"                     // wrapping presents
}

@MainActor
final class Audio {
    static let shared = Audio()
    private let musicVolume: Float = 0.45

    private var effects: [Sfx: [AVAudioPlayer]] = [:]
    private var player: AVAudioPlayer?
    private var current: Music?
    private var wanted: Music?
    private var active = true

    var soundOn = true
    var musicOn = true {
        didSet {
            if musicOn, let w = wanted { current = nil; music(w) }
            if !musicOn { player?.stop(); player = nil; current = nil }
        }
    }

    private init() {
        // "Ambient" mixes politely with other audio and respects the silent switch.
        try? AVAudioSession.sharedInstance().setCategory(.ambient)
        try? AVAudioSession.sharedInstance().setActive(true)
        for s in Sfx.allCases {
            guard let url = Bundle.main.url(forResource: s.rawValue, withExtension: "wav") else { continue }
            // Two copies each so the same sound can overlap itself.
            effects[s] = (0..<2).compactMap { _ in
                let p = try? AVAudioPlayer(contentsOf: url)
                p?.volume = s.volume
                p?.prepareToPlay()
                return p
            }
        }
    }

    func play(_ s: Sfx) {
        guard soundOn, active, let copies = effects[s] else { return }
        let p = copies.first { !$0.isPlaying } ?? copies.first
        p?.currentTime = 0
        p?.play()
    }

    func music(_ m: Music) {
        wanted = m
        guard musicOn, active, m != current else { return }
        current = m
        if let old = player {
            old.setVolume(0, fadeDuration: 0.35)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { old.stop() }
        }
        guard let url = Bundle.main.url(forResource: m.rawValue, withExtension: "m4a"), let next = try? AVAudioPlayer(contentsOf: url) else { return }
        next.numberOfLoops = -1
        next.volume = 0
        next.play()
        next.setVolume(musicVolume, fadeDuration: 0.7)
        player = next
    }

    /// App went to the background: go quiet. Back again: carry on.
    func setActive(_ on: Bool) {
        active = on
        if on {
            guard musicOn else { return }
            if let p = player { p.play(); p.setVolume(musicVolume, fadeDuration: 0.3) } else if let w = wanted { current = nil; music(w) }
        } else {
            player?.pause()
        }
    }
}

import SwiftUI

private let screenColor = Color(hex: 0xEAF2FF)
private let myBubble = Color(hex: 0x3D6FD6)

/// The ElfPhone: chat list, group chat and private chats.
struct PhoneView: View {
    let game: GameState
    @State private var thread: String?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Txt(Date(timeIntervalSince1970: game.now).formatted(date: .omitted, time: .shortened), 13, .white)
                Spacer(); Txt("🎄 ElfPhone", 13, .white); Spacer(); Txt("📶 🔋", 11, .white)
            }
            .padding(.horizontal, 12).padding(.vertical, 4).background(Color(hex: 0x2A2833))
            if let t = thread { ChatThread(game: game, thread: t) { thread = nil } } else { ChatList(game: game) { thread = $0 } }
        }
        .background(screenColor)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .padding(8)
        .panel(Color(hex: 0x2A2833), border: Pal.ink, radius: 26)
    }
}

private struct ChatList: View {
    let game: GameState
    let open: (String) -> Void

    var body: some View {
        let met = game.met
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Txt("Messages", 26)
                if met.isEmpty {
                    VStack(spacing: 10) {
                        Txt("📭 No contacts yet!", 20)
                        Txt("Go say hi to elves in Friends and they'll give you their number!", 16, align: .center)
                        Btn("🧝 Go to Friends", Pal.green, size: 17, width: 220) { game.go(.friends) }
                    }
                    .padding(16).frame(maxWidth: .infinity).panel(.white)
                } else {
                    let last = game.messages(groupThread).last
                    row(avatar: AnyView(GroupAvatar(met: met)), name: "🎄 Christmas Town Elves",
                        preview: last.map { "\($0.from == me ? "You" : $0.from): \($0.text)" } ?? "Tap to say hi to everyone!",
                        unread: game.unread(groupThread) > 0 ? "\(game.unread(groupThread))" : game.groupHasNews ? "new" : nil) { open(groupThread) }
                    Txt("Private chats", 15, Pal.brown)
                    ForEach(met, id: \.self) { name in
                        let n = npc(name)!
                        row(avatar: AnyView(Face(look: n.look, size: 46)), name: name,
                            preview: game.messages(name).last.map { ($0.from == me ? "You: " : "") + $0.text } ?? n.job,
                            unread: game.unread(name) > 0 ? "\(game.unread(name))" : nil) { open(name) }
                    }
                }
            }
            .padding(10)
        }
    }

    private func row(avatar: AnyView, name: String, preview: String, unread: String?, action: @escaping () -> Void) -> some View {
        Tap(action: action) {
            HStack(spacing: 10) {
                avatar
                VStack(alignment: .leading, spacing: 2) { Txt(name, 17, lines: 1); Txt(preview, 13, Pal.ink.opacity(0.6), lines: 1) }
                Spacer()
                if let u = unread { Txt(u, 13, .white).padding(.horizontal, 7).padding(.vertical, 2).background(Capsule().fill(Pal.red)) }
            }
            .padding(8).panel(.white)
        }
    }
}

struct GroupAvatar: View {
    let met: [String]
    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(met.prefix(3).enumerated()), id: \.offset) { i, n in
                Face(look: npc(n)!.look, size: 30).offset(x: CGFloat(i * 10), y: i % 2 == 0 ? 0 : 14)
            }
        }
        .frame(width: 46, height: 46, alignment: .topLeading)
    }
}

private let dmQuick = ["👋 Hi!", "How are you?", "Tell me a joke!", "What should I do?", "How are the reindeer?", "What's your favorite thing?", "Bye! 👋"]
private let groupQuick = ["Hi everyone! 👋", "What's new?", "Tell me a joke!", "I finished my jobs! 🎉", "Good night! 🌙"]

private struct ChatThread: View {
    let game: GameState
    let thread: String
    let back: () -> Void
    @State private var typing: String?
    @State private var draft = ""
    @State private var liveTask: Task<Void, Never>?

    var isGroup: Bool { thread == groupThread }

    var body: some View {
        let msgs = game.messages(thread)
        let lastFromThem = msgs.last.flatMap { $0.from != me && $0.qid != nil ? $0 : nil }
        let pending = ElfBrain.question(lastFromThem?.qid)

        VStack(spacing: 0) {
            // Header
            HStack(spacing: 8) {
                Tap(action: back) { Txt("‹", 30, Pal.blue).padding(.horizontal, 6) }
                if isGroup { GroupAvatar(met: game.met) } else { Face(look: npc(thread)!.look, size: 40) }
                VStack(alignment: .leading) {
                    Txt(isGroup ? "Christmas Town Elves" : thread, 17, lines: 1)
                    Txt(isGroup ? game.met.joined(separator: ", ") + ", you" : npc(thread)!.job, 12, Pal.ink.opacity(0.6), lines: 1)
                }
                Spacer()
            }
            .padding(8).background(.white)

            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(Array(msgs.enumerated()), id: \.offset) { i, m in BubbleRow(m: m, isGroup: isGroup).id(i) }
                        if let t = typing { TypingRow(elf: t).id("typing") }
                    }
                    .padding(8)
                }
                .onChange(of: msgs.count, initial: true) { _, n in
                    game.markRead(thread)
                    withAnimation { proxy.scrollTo(n - 1, anchor: .bottom) }
                }
                .onChange(of: typing) { _, t in if t != nil { withAnimation { proxy.scrollTo("typing", anchor: .bottom) } } }
            }

            // Tap-to-answer buttons, or quick replies
            let chips = pending?.options ?? (isGroup ? groupQuick : dmQuick)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(chips, id: \.self) { c in
                        Tap(action: { send(c, pending: pending, askedBy: lastFromThem?.from) }) {
                            Txt(c, 14, pending != nil ? .white : Pal.blue)
                                .padding(.horizontal, 10).padding(.vertical, 5)
                                .background(Capsule().fill(pending != nil ? Pal.green : .white))
                                .overlay(Capsule().stroke(pending != nil ? Pal.darkGreen : Pal.blue, lineWidth: 2))
                        }
                    }
                }
                .padding(.horizontal, 6).padding(.vertical, 4)
            }

            // Type your own message
            HStack(spacing: 8) {
                TextField("", text: $draft, prompt: Text("Type a message…").foregroundStyle(Pal.ink.opacity(0.35)))
                    .font(.custom("Pixelify Sans", fixedSize: 17)).foregroundStyle(Pal.ink)
                    .submitLabel(.send)
                    .onSubmit { send(draft, pending: pending, askedBy: lastFromThem?.from) }
                    .onChange(of: draft) { _, d in if d.count > 200 { draft = String(d.prefix(200)) } }
                    .padding(.horizontal, 12).padding(.vertical, 9)
                    .background(Capsule().fill(screenColor))
                Tap(action: { send(draft, pending: pending, askedBy: lastFromThem?.from) }) {
                    Txt("➤", 22, .white).padding(.horizontal, 12).padding(.vertical, 6).background(Circle().fill(myBubble))
                }
            }
            .padding(8).background(.white)
        }
        .onAppear {
            if isGroup {
                game.openGroup()
                // The group keeps chatting while you watch.
                liveTask = Task { @MainActor in
                    while !Task.isCancelled {
                        try? await Task.sleep(for: .seconds(Double.random(in: 25...45)))
                        guard !Task.isCancelled, typing == nil, !game.met.isEmpty else { continue }
                        typing = game.met.randomElement()
                        try? await Task.sleep(for: .seconds(1.5))
                        game.liveGroupEvent()
                        typing = nil
                    }
                }
            }
        }
        .onDisappear { liveTask?.cancel() }
    }

    private func send(_ text: String, pending: Question?, askedBy: String?) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, typing == nil else { return }
        let (clean, flag) = ChatFilter.check(String(trimmed.prefix(200)))
        game.post(thread, [ChatMsg(from: me, text: clean, time: Date().timeIntervalSince1970)])
        draft = ""
        guard let responder = isGroup ? (askedBy ?? game.met.randomElement()) : thread else { return }
        Task { @MainActor in
            typing = responder
            try? await Task.sleep(for: .seconds(Double.random(in: 0.9...1.8)))
            let replies: [ChatMsg]
            if flag != .ok { replies = [ChatMsg(from: responder, text: ChatFilter.safetyReply(flag, elf: responder), time: Date().timeIntervalSince1970)] }
            else if isGroup { replies = ElfBrain.groupReply(game, met: game.met, text: clean, answering: pending, askedBy: askedBy) }
            else { replies = ElfBrain.reply(game, elf: thread, text: clean, answering: pending) }
            for (i, r) in replies.enumerated() {
                if i > 0 { typing = r.from; try? await Task.sleep(for: .seconds(Double.random(in: 0.9...1.6))) }
                typing = nil
                var m = r; m.time = Date().timeIntervalSince1970
                game.post(thread, [m])
            }
            typing = nil
            if !isGroup { game.chatFriendship(thread) }
        }
    }
}

private func ago(_ t: Double) -> String {
    let m = Int((Date().timeIntervalSince1970 - t) / 60)
    return m < 1 ? "now" : m < 60 ? "\(m)m" : m < 24 * 60 ? "\(m / 60)h" : "\(m / (24 * 60))d"
}

private struct BubbleRow: View {
    let m: ChatMsg
    let isGroup: Bool
    var body: some View {
        let mine = m.from == me
        HStack(alignment: .bottom, spacing: 6) {
            if mine { Spacer(minLength: 40) } else if let n = npc(m.from) { Face(look: n.look, size: 30) }
            VStack(alignment: mine ? .trailing : .leading, spacing: 1) {
                if !mine && isGroup { Txt(m.from, 12, Pal.brown) }
                Txt(m.text, 16, mine ? .white : Pal.ink)
                    .padding(.horizontal, 10).padding(.vertical, 7)
                    .background(RoundedRectangle(cornerRadius: 14).fill(mine ? myBubble : .white))
                    .overlay { if !mine { RoundedRectangle(cornerRadius: 14).stroke(Color(hex: 0xD5DBE6), lineWidth: 2) } }
                Txt(ago(m.time), 10, Pal.ink.opacity(0.45))
            }
            .frame(maxWidth: 300, alignment: mine ? .trailing : .leading)
            if !mine { Spacer(minLength: 40) }
        }
    }
}

private struct TypingRow: View {
    let elf: String
    var body: some View {
        HStack(spacing: 6) {
            if let n = npc(elf) { Face(look: n.look, size: 30) }
            Txt("\(elf) is typing… 💬", 14, Pal.ink.opacity(0.6))
                .padding(.horizontal, 10).padding(.vertical, 6).background(RoundedRectangle(cornerRadius: 14).fill(.white)).bob(3, 0.3)
            Spacer()
        }
    }
}

import SwiftUI
import SwiftData

struct PlayersView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @Query(sort: \Player.createdAt) private var roster: [Player]

    @State private var editing: Player?
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if roster.isEmpty {
                    EmptyStateView(symbol: "person.2",
                                   title: "No players yet",
                                   message: "Add the people you play with so logging a play is one tap.",
                                   actionTitle: "Add player",
                                   action: { showAdd = true })
                } else {
                    List {
                        ForEach(roster) { player in
                            Button { editing = player } label: { row(player) }
                                .buttonStyle(.plain)
                                .listRowBackground(Theme.surface)
                        }
                        .onDelete(perform: delete)
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Players")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add player")
                }
            }
            .sheet(isPresented: $showAdd) { PlayerEditView(player: nil) }
            .sheet(item: $editing) { p in PlayerEditView(player: p) }
        }
    }

    private func row(_ player: Player) -> some View {
        HStack(spacing: 12) {
            PlayerChip(name: player.name, initials: player.initials, colorHue: player.colorHue, size: 38)
            Text(player.name).font(Theme.rounded(16, .semibold)).foregroundStyle(Theme.textPrimary)
            if player.isMe {
                Text("ME").font(Theme.rounded(10, .bold)).foregroundStyle(.white)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Capsule().fill(Theme.accent))
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 12)).foregroundStyle(Theme.textSecondary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(player.isMe ? "\(player.name), this is me" : player.name)
        .accessibilityHint("Edit player")
    }

    private func delete(_ offsets: IndexSet) {
        for i in offsets where i < roster.count { context.delete(roster[i]) }
        Haptics.warning(settings.hapticsEnabled)
    }
}

struct PlayerEditView: View {
    let player: Player?
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @Query private var roster: [Player]

    @State private var name = ""
    @State private var isMe = false
    @State private var hue = 0
    @State private var error: String?

    private var isEditing: Bool { player != nil }
    private var trimmed: String { name.trimmingCharacters(in: .whitespaces) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Player") {
                    TextField("Name", text: $name)
                    Toggle("This is me", isOn: $isMe).tint(Theme.accent)
                }
                Section("Color") {
                    HStack {
                        PlayerChip(name: trimmed.isEmpty ? "?" : trimmed,
                                   initials: previewInitials, colorHue: hue, size: 44)
                        Slider(value: Binding(get: { Double(hue) }, set: { hue = Int($0) }), in: 0...359, step: 1)
                            .tint(Theme.playerColor(hue: hue))
                            .accessibilityLabel("Player color")
                    }
                }
                if let error { Text(error).font(Theme.rounded(13)).foregroundStyle(Theme.danger) }
            }
            .navigationTitle(isEditing ? "Edit Player" : "Add Player")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(trimmed.isEmpty)
                }
            }
            .onAppear(perform: load)
        }
    }

    private var previewInitials: String {
        let words = trimmed.split(separator: " ").prefix(2)
        let j = words.compactMap { $0.first }.map(String.init).joined().uppercased()
        return j.isEmpty ? "?" : j
    }

    private func load() {
        if let player {
            name = player.name; isMe = player.isMe; hue = player.colorHue
        } else {
            hue = Int.random(in: 0...359)
        }
    }

    private func save() {
        guard !trimmed.isEmpty else { error = "Please enter a name."; return }
        // If marking as me, clear other "me" flags.
        if isMe {
            for other in roster where other.id != player?.id { other.isMe = false }
        }
        if let player {
            player.name = trimmed; player.isMe = isMe; player.colorHue = hue
        } else {
            let p = Player(name: trimmed, colorHue: hue, isMe: isMe)
            context.insert(p)
        }
        Haptics.success(settings.hapticsEnabled)
        dismiss()
    }
}

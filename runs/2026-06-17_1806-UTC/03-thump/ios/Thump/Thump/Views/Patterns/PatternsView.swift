import SwiftUI
import SwiftData

struct PatternsView: View {
    @Environment(SequencerStore.self) private var store
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    @Query(sort: \Pattern.createdAt, order: .reverse) private var patterns: [Pattern]

    @State private var toast: ToastMessage?
    @State private var renaming: Pattern?
    @State private var renameText = ""
    @State private var showPaywall = false

    private var builtIns: [Pattern] { patterns.filter { $0.isBuiltIn } }
    private var mine: [Pattern] { patterns.filter { !$0.isBuiltIn } }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if patterns.isEmpty {
                    EmptyStateView(
                        symbol: "rectangle.stack.badge.plus",
                        title: "No patterns yet",
                        message: "Build a beat on the Beats tab, then tap Save to start your library.",
                        actionTitle: nil, action: nil
                    )
                } else {
                    list
                }
            }
            .navigationTitle("Patterns")
            .toast($toast)
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .alert("Rename Pattern", isPresented: Binding(get: { renaming != nil }, set: { if !$0 { renaming = nil } })) {
                TextField("Name", text: $renameText)
                Button("Cancel", role: .cancel) { renaming = nil }
                Button("Save") { commitRename() }
            }
        }
    }

    private var list: some View {
        List {
            if !mine.isEmpty {
                Section {
                    ForEach(mine) { row($0, deletable: true) }
                } header: {
                    HStack {
                        Text("My Patterns")
                        Spacer()
                        Text(isPro ? "\(mine.count)" : "\(mine.count) / \(Pro.freeSavedPatternLimit)")
                            .font(Theme.mono(12, .semibold))
                            .foregroundStyle(mine.count >= Pro.freeSavedPatternLimit && !isPro ? Theme.bad : Theme.inkSoft)
                    }
                }
            }
            Section("Starter Grooves") {
                ForEach(builtIns) { row($0, deletable: false) }
            }
        }
        .scrollContentBackground(.hidden)
    }

    private func row(_ pattern: Pattern, deletable: Bool) -> some View {
        Button {
            store.load(pattern: pattern)
            Haptics.success(settings.hapticsEnabled)
            toast = ToastMessage(text: "Loaded “\(pattern.name)” — go to Beats", symbol: "arrow.down.circle.fill")
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous)
                        .fill(Theme.heroGradient)
                        .frame(width: 44, height: 44)
                    Image(systemName: pattern.isBuiltIn ? "waveform" : "rectangle.stack.fill")
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(pattern.name)
                        .font(Theme.rounded(16, .bold))
                        .foregroundStyle(Theme.ink)
                    Text("\(Int(pattern.bpm)) BPM · \(KitLibrary.kit(id: pattern.kitID).name) · \(pattern.stepCount) steps")
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Theme.inkSoft).font(.system(size: 12, weight: .bold))
            }
        }
        .listRowBackground(Theme.surface)
        .accessibilityLabel(Text("\(pattern.name), \(Int(pattern.bpm)) BPM"))
        .accessibilityHint(Text("Loads this pattern into the sequencer"))
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if deletable {
                Button(role: .destructive) { delete(pattern) } label: { Label("Delete", systemImage: "trash") }
            }
            Button { beginRename(pattern) } label: { Label("Rename", systemImage: "pencil") }
                .tint(Theme.accent)
            Button { duplicate(pattern) } label: { Label("Duplicate", systemImage: "plus.square.on.square") }
                .tint(Theme.good)
        }
        .contextMenu {
            Button("Duplicate", systemImage: "plus.square.on.square") { duplicate(pattern) }
            Button("Rename", systemImage: "pencil") { beginRename(pattern) }
            if deletable {
                Button("Delete", systemImage: "trash", role: .destructive) { delete(pattern) }
            }
        }
    }

    // MARK: - Actions

    private func delete(_ pattern: Pattern) {
        context.delete(pattern)
        try? context.save()
        Haptics.medium(settings.hapticsEnabled)
        toast = ToastMessage(text: "Deleted “\(pattern.name)”", symbol: "trash.fill")
    }

    private func duplicate(_ pattern: Pattern) {
        if !isPro {
            let descriptor = FetchDescriptor<Pattern>(predicate: #Predicate { $0.isBuiltIn == false })
            let count = (try? context.fetchCount(descriptor)) ?? 0
            if count >= Pro.freeSavedPatternLimit {
                Haptics.warning(settings.hapticsEnabled)
                toast = ToastMessage(text: "Free limit reached. Unlock Pro for unlimited.", symbol: "lock.fill", isError: true)
                showPaywall = true
                return
            }
        }
        let copy = Pattern(name: "\(pattern.name) copy", bpm: pattern.bpm, swing: pattern.swing,
                           kitID: pattern.kitID, grid: pattern.grid, isBuiltIn: false)
        context.insert(copy)
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
        toast = ToastMessage(text: "Duplicated “\(pattern.name)”", symbol: "plus.square.on.square")
    }

    private func beginRename(_ pattern: Pattern) {
        renameText = pattern.name
        renaming = pattern
    }

    private func commitRename() {
        guard let pattern = renaming else { return }
        let trimmed = renameText.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            pattern.name = trimmed
            try? context.save()
            Haptics.success(settings.hapticsEnabled)
            toast = ToastMessage(text: "Renamed", symbol: "pencil")
        }
        renaming = nil
    }
}

import SwiftUI
import SwiftData

struct SignsView: View {
    @Query(sort: \DreamSign.name) private var signs: [DreamSign]
    @Environment(\.modelContext) private var context
    @State private var showAdd = false

    private var ranked: [DreamSign] { signs.sorted { $0.count > $1.count } }
    private var maxCount: Int { ranked.first?.count ?? 1 }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgPrimary.ignoresSafeArea()
                if signs.isEmpty {
                    EmptyStateView(symbol: "sparkle.magnifyingglass",
                                   title: "No dream signs yet",
                                   message: "Tag recurring people, places and themes in your dreams. The ones that show up most become your cues to go lucid.",
                                   actionTitle: "Add a sign") { showAdd = true }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            if let top = ranked.first, top.count > 0 { topCard(top) }
                            listCard
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Dream Signs")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Haptics.tap(); showAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add sign")
                }
            }
            .sheet(isPresented: $showAdd) { AddSignView() }
        }
    }

    private func topCard(_ sign: DreamSign) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Your top dream sign", systemImage: "sparkles")
                .font(.subheadline.weight(.semibold)).foregroundStyle(Theme.lucid)
            HStack {
                Image(systemName: sign.category.symbol).font(.title2).foregroundStyle(Theme.accent)
                Text(sign.name).font(.title3.weight(.bold)).foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("\(sign.count)×").font(.headline).foregroundStyle(Theme.accent)
            }
            Text("When you notice “\(sign.name)” in waking life, do a reality check — it's your most reliable cue that you might be dreaming.")
                .font(.callout).foregroundStyle(Theme.textSecondary)
        }
        .reverieCard()
    }

    private var listCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All signs").font(.headline).foregroundStyle(Theme.textPrimary)
            ForEach(ranked) { sign in
                VStack(spacing: 6) {
                    HStack {
                        Label(sign.name, systemImage: sign.category.symbol)
                            .font(.subheadline).foregroundStyle(Theme.textPrimary)
                        Spacer()
                        Text("\(sign.count)").font(.subheadline.weight(.semibold)).foregroundStyle(Theme.accent)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Theme.track).frame(height: 6)
                            Capsule().fill(Theme.moonGradient)
                                .frame(width: maxCount > 0 ? geo.size.width * CGFloat(sign.count) / CGFloat(maxCount) : 0, height: 6)
                        }
                    }
                    .frame(height: 6)
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
                .swipeActions {
                    Button(role: .destructive) { delete(sign) } label: { Label("Delete", systemImage: "trash") }
                }
            }
        }
        .reverieCard()
    }

    private func delete(_ sign: DreamSign) {
        context.delete(sign); try? context.save()
    }
}

struct AddSignView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var category: SignCategory = .theme

    var body: some View {
        NavigationStack {
            Form {
                Section("New dream sign") {
                    TextField("Name (e.g. Flying)", text: $name)
                    Picker("Category", selection: $category) {
                        ForEach(SignCategory.allCases) { Label($0.rawValue, systemImage: $0.symbol).tag($0) }
                    }
                }
            }
            .navigationTitle("Add Sign")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { add() }.disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func add() {
        let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !n.isEmpty else { return }
        context.insert(DreamSign(name: n, category: category))
        try? context.save()
        Haptics.success()
        dismiss()
    }
}

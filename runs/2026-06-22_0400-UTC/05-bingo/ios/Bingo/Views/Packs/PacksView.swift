import SwiftUI
import SwiftData

struct PacksView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var customPacks: [CustomPack]
    @State private var showCreatePack = false
    @State private var editingPack: CustomPack? = nil
    @State private var showDeleteAlert = false
    @State private var packToDelete: CustomPack? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                BingoTheme.navy.ignoresSafeArea()

                List {
                    Section(header: Text("BUILT-IN PACKS").foregroundColor(BingoTheme.gold)) {
                        ForEach(WordPackLibrary.builtInPacks) { pack in
                            BuiltInPackRow(pack: pack)
                                .listRowBackground(BingoTheme.lightNavy)
                        }
                    }

                    Section(header: Text("MY CUSTOM PACKS").foregroundColor(BingoTheme.gold)) {
                        if customPacks.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "plus.rectangle.on.folder")
                                    .font(.system(size: 36))
                                    .foregroundColor(BingoTheme.gold.opacity(0.5))
                                Text("No custom packs yet")
                                    .font(.headline)
                                    .foregroundColor(.white.opacity(0.7))
                                Text("Create a pack for family reunions,\npersonalized events, or any theme!")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.5))
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .listRowBackground(BingoTheme.lightNavy)
                        } else {
                            ForEach(customPacks) { pack in
                                Button(action: { editingPack = pack }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("📝 \(pack.name)")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                            Text("\(pack.words.count) words")
                                                .font(.caption)
                                                .foregroundColor(BingoTheme.gold)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.white.opacity(0.3))
                                    }
                                }
                                .listRowBackground(BingoTheme.lightNavy)
                                .swipeActions(edge: .trailing) {
                                    Button("Delete", role: .destructive) {
                                        packToDelete = pack
                                        showDeleteAlert = true
                                    }
                                }
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Word Packs")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(BingoTheme.navy, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showCreatePack = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(BingoTheme.gold)
                    }
                }
            }
            .sheet(isPresented: $showCreatePack) {
                CustomPackView(pack: nil)
            }
            .sheet(item: $editingPack) { pack in
                CustomPackView(pack: pack)
            }
            .alert("Delete Pack?", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    if let pack = packToDelete {
                        modelContext.delete(pack)
                        try? modelContext.save()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete \"\(packToDelete?.name ?? "")\" and its word list.")
            }
        }
    }
}

struct BuiltInPackRow: View {
    let pack: WordPack
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(pack.emoji) \(pack.name)")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(pack.description)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(BingoTheme.gold)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible()), count: 3),
                    spacing: 6
                ) {
                    ForEach(pack.words, id: \.self) { word in
                        Text(word)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(BingoTheme.navy.opacity(0.5))
                            .cornerRadius(4)
                            .lineLimit(1)
                    }
                }
                .padding(.top, 4)
            }
        }
    }
}

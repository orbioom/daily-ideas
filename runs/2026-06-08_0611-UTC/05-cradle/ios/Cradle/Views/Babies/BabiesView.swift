import SwiftUI
import SwiftData

struct BabiesView: View {
    @AppStorage("cradle.activeBaby") private var activeBabyID = ""

    @Environment(\.modelContext) private var context
    @Query(sort: \Baby.order) private var babies: [Baby]

    @State private var showAddSheet = false
    @State private var editingBaby: Baby? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground

                Group {
                    if babies.isEmpty {
                        EmptyStateView(
                            icon: "person.2",
                            title: "No babies yet",
                            message: "Add your first baby to start tracking."
                        )
                        .padding(.top, 80)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(babies) { baby in
                                BabyRow(
                                    baby: baby,
                                    isActive: baby.id.uuidString == activeBabyID
                                ) {
                                    Haptics.selection()
                                    activeBabyID = baby.id.uuidString
                                } onEdit: {
                                    Haptics.tap()
                                    editingBaby = baby
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                            }
                            .onDelete(perform: deleteBabies)
                        }
                        .listStyle(.plain)
                        .background(Color.clear)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Babies")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Haptics.tap()
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Brand.text)
                    }
                    .accessibilityLabel("Add baby")
                }
            }
            .sheet(isPresented: $showAddSheet) {
                BabyFormSheet(existingBaby: nil)
            }
            .sheet(item: $editingBaby) { baby in
                BabyFormSheet(existingBaby: baby)
            }
        }
    }

    private func deleteBabies(at offsets: IndexSet) {
        for idx in offsets {
            let baby = babies[idx]
            if activeBabyID == baby.id.uuidString {
                activeBabyID = babies.first(where: { $0.id != baby.id })?.id.uuidString ?? ""
            }
            context.delete(baby)
        }
        Haptics.warning()
    }
}

// MARK: - Baby Row

private struct BabyRow: View {
    let baby: Baby
    let isActive: Bool
    let onSelect: () -> Void
    let onEdit: () -> Void

    var body: some View {
        GlassCard(padding: 14) {
            HStack(spacing: 14) {
                BabyAvatar(baby: baby, size: 50)

                VStack(alignment: .leading, spacing: 3) {
                    Text(baby.name)
                        .font(.headline)
                        .foregroundStyle(Brand.text)
                    Text(baby.ageString)
                        .font(.subheadline)
                        .foregroundStyle(Brand.text2)
                    Text(baby.sex.label)
                        .font(.caption)
                        .foregroundStyle(Brand.text3)
                }

                Spacer()

                VStack(spacing: 10) {
                    if isActive {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Brand.live)
                            .font(.system(size: 20))
                            .accessibilityLabel("Active baby")
                    } else {
                        Button("Select") {
                            onSelect()
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Brand.text2)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Brand.hairline, in: Capsule())
                        .accessibilityLabel("Select \(baby.name) as active baby")
                    }

                    Button {
                        onEdit()
                    } label: {
                        Image(systemName: "pencil.circle")
                            .font(.system(size: 18))
                            .foregroundStyle(Brand.text3)
                    }
                    .accessibilityLabel("Edit \(baby.name)")
                }
            }
        }
        .accessibilityElement(children: .contain)
    }
}

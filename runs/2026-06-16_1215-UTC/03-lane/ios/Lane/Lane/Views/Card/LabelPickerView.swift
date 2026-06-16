import SwiftUI
import SwiftData

/// Multi-select labels for a card, plus create/delete custom labels (Pro).
struct LabelPickerView: View {
    @Bindable var card: Card
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var proStore: ProStore

    @Query(sort: \Label.name, order: .forward)
    private var allLabels: [Label]

    @State private var newName = ""
    @State private var newColor = Palette.labelColors.first ?? 0x2D7FF9
    @State private var showPaywall = false

    private let colorColumns = [GridItem(.adaptive(minimum: 40), spacing: 8)]

    private func isSelected(_ label: Label) -> Bool {
        card.labels.contains { $0.id == label.id }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Apply labels") {
                    if allLabels.isEmpty {
                        Text("No labels yet. Create one below.")
                            .foregroundStyle(Theme.inkSoft)
                    } else {
                        ForEach(allLabels) { label in
                            Button {
                                toggle(label)
                            } label: {
                                HStack(spacing: 10) {
                                    Circle()
                                        .fill(Color(hex: UInt(max(0, label.colorHex))))
                                        .frame(width: 16, height: 16)
                                    Text(label.name)
                                        .foregroundStyle(Theme.ink)
                                    Spacer()
                                    if isSelected(label) {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Theme.accent)
                                            .fontWeight(.semibold)
                                    }
                                }
                            }
                            .accessibilityAddTraits(isSelected(label) ? [.isSelected] : [])
                        }
                        .onDelete(perform: deleteLabels)
                    }
                }

                Section {
                    if proStore.isPro {
                        TextField("Label name", text: $newName)
                        LazyVGrid(columns: colorColumns, spacing: 8) {
                            ForEach(Palette.labelColors, id: \.self) { hex in
                                Circle()
                                    .fill(Color(hex: UInt(hex)))
                                    .frame(width: 30, height: 30)
                                    .overlay(Circle().stroke(Theme.ink, lineWidth: newColor == hex ? 3 : 0))
                                    .onTapGesture { newColor = hex }
                                    .accessibilityLabel("Label color")
                            }
                        }
                        .padding(.vertical, 4)
                        Button {
                            createLabel()
                        } label: {
                            SwiftUI.Label("Create label", systemImage: "plus.circle.fill")
                        }
                        .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            HStack {
                                SwiftUI.Label("Create custom label", systemImage: "tag")
                                Spacer()
                                ProLockBadge()
                            }
                        }
                    }
                } header: {
                    Text("Create label")
                } footer: {
                    Text(proStore.isPro
                         ? "Custom labels can be applied across all your boards."
                         : "Custom labels are part of Lane Pro.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Labels")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private func toggle(_ label: Label) {
        if let idx = card.labels.firstIndex(where: { $0.id == label.id }) {
            card.labels.remove(at: idx)
        } else {
            card.labels.append(label)
        }
        try? context.save()
        Haptics.selection(enabled: settings.hapticsEnabled)
    }

    private func createLabel() {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let label = Label(name: trimmed, colorHex: newColor)
        context.insert(label)
        card.labels.append(label)
        newName = ""
        try? context.save()
        Haptics.notify(.success, enabled: settings.hapticsEnabled)
    }

    private func deleteLabels(at offsets: IndexSet) {
        for index in offsets {
            if let label = allLabels[safe: index] {
                context.delete(label)
            }
        }
        try? context.save()
    }
}

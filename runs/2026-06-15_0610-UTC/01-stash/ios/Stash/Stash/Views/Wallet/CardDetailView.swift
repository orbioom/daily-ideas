import SwiftUI
import SwiftData

/// The full-screen card detail: a large rendered barcode, the raw value, a brightness
/// boost while shown, a "mark used" action, edit, favorite, and delete.
struct CardDetailView: View {
    @Bindable var card: LoyaltyCard
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showEdit = false
    @State private var showDeleteConfirm = false
    @State private var justMarked = false

    private var tint: Color { Color(hexString: card.colorHex, fallback: Theme.accent) }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header
                barcodePanel
                if card.codeValue.trimmingCharacters(in: .whitespaces).isEmpty {
                    addCodePrompt
                } else {
                    markUsedButton
                }
                metaPanel
                if !card.notes.trimmingCharacters(in: .whitespaces).isEmpty {
                    notesPanel
                }
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(card.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .brightnessBoost(settings.brightnessBoost)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        toggleFavorite()
                    } label: {
                        Label(card.isFavorite ? "Unfavorite" : "Favorite",
                              systemImage: card.isFavorite ? "star.slash" : "star")
                    }
                    Button {
                        showEdit = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Card options")
            }
        }
        .sheet(isPresented: $showEdit) {
            AddEditCardView(card: card)
        }
        .confirmationDialog("Delete this card?",
                            isPresented: $showDeleteConfirm,
                            titleVisibility: .visible) {
            Button("Delete", role: .destructive) { deleteCard() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes \(card.displayTitle) from your wallet.")
        }
    }

    // MARK: Sections

    private var header: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle().fill(tint.opacity(0.18)).frame(width: 64, height: 64)
                Image(systemName: card.category.symbol)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(tint)
            }
            .accessibilityHidden(true)
            Text(card.storeName.isEmpty ? card.displayTitle : card.storeName)
                .font(Theme.rounded(22, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(card.category.displayName + " · " + card.format.displayName)
                .font(Theme.rounded(13, .medium))
                .foregroundStyle(Theme.inkSoft)
        }
    }

    private var barcodePanel: some View {
        CardSurface(padding: 18) {
            VStack(spacing: 8) {
                BarcodeView(value: card.codeValue,
                            format: card.format,
                            height: card.format.isLinear ? 150 : 200)
                Text("Hold steady under the scanner")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkFaint)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var addCodePrompt: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 10) {
                Label("Add this card's code", systemImage: "number")
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                Text("This card was quick-added without a code yet. Edit it to scan-in or type the membership number.")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    showEdit = true
                } label: {
                    Text("Add code")
                        .font(Theme.rounded(15, .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18).padding(.vertical, 9)
                        .background(Capsule().fill(Theme.accent))
                }
                .padding(.top, 2)
            }
        }
    }

    private var markUsedButton: some View {
        PrimaryButton(title: justMarked ? "Marked as used" : "Mark as used",
                      systemImage: justMarked ? "checkmark.circle.fill" : "checkmark.circle") {
            markUsed()
        }
    }

    private var metaPanel: some View {
        CardSurface {
            VStack(spacing: 12) {
                metaRow(label: "Code value", value: card.codeValue.isEmpty ? "Not set" : card.codeValue, mono: true)
                Divider().background(Theme.hairline)
                metaRow(label: "Last used", value: lastUsedString)
                Divider().background(Theme.hairline)
                metaRow(label: "Added", value: card.createdAt.formatted(date: .abbreviated, time: .omitted))
            }
        }
    }

    private func metaRow(label: String, value: String, mono: Bool = false) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(Theme.rounded(14, .medium))
                .foregroundStyle(Theme.inkSoft)
            Spacer()
            Text(value)
                .font(mono ? Theme.mono(14) : Theme.rounded(14, .medium))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
    }

    private var notesPanel: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 6) {
                SectionHeader(title: "Notes", symbol: "note.text")
                Text(card.notes)
                    .font(Theme.rounded(15))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var lastUsedString: String {
        guard let last = card.lastUsedAt else { return "Never" }
        return last.formatted(.relative(presentation: .named))
    }

    // MARK: Actions

    private func markUsed() {
        card.lastUsedAt = Date()
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) { justMarked = true }
    }

    private func toggleFavorite() {
        card.isFavorite.toggle()
        try? context.save()
        Haptics.select(settings.hapticsEnabled)
    }

    private func deleteCard() {
        context.delete(card)
        try? context.save()
        Haptics.tap(settings.hapticsEnabled)
        dismiss()
    }
}

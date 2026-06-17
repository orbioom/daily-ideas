import SwiftUI
import SwiftData

/// Rub detail: ingredients, steps, scale-by-batch, edit, and copy-to-edit.
struct RubDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppSettings.self) private var settings
    @AppStorage("isPro") private var isPro = false
    @Bindable var rub: Rub

    @State private var batch: Double = 1
    @State private var showEditor = false
    @State private var paywallReason: PaywallReason?

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    batchCard
                    ingredientsCard
                    if let steps = rub.steps, !steps.isEmpty {
                        block(title: "Method", text: steps)
                    }
                    if !rub.notes.isEmpty {
                        block(title: "Notes", text: rub.notes)
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle(rub.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showEditor = true } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button { copyToEdit() } label: {
                        Label("Duplicate to edit", systemImage: "doc.on.doc")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showEditor) { RubEditorView(rub: rub) }
        .sheet(item: $paywallReason) { PaywallView(reason: $0) }
    }

    private var batchCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Batch size")
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text(String(format: "%.1f×", batch))
                    .font(Theme.numeral(18, .bold))
                    .foregroundStyle(Theme.accent)
                    .monospacedDigit()
            }
            Slider(value: $batch, in: 0.5...8, step: 0.5)
                .tint(Theme.accent)
                .accessibilityValue(String(format: "%.1f times", batch))
            Text("Scale the quantities below for a bigger or smaller batch.")
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkSoft)
        }
        .searCard()
    }

    private var ingredientsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Ingredients")
                .font(Theme.rounded(17, .bold))
                .foregroundStyle(Theme.ink)
            ForEach(Array(rub.ingredients.enumerated()), id: \.offset) { _, ingredient in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 5))
                        .foregroundStyle(Theme.accent)
                        .padding(.top, 7)
                        .accessibilityHidden(true)
                    Text(RubScaler.scaled(ingredient, by: batch))
                        .font(Theme.rounded(14))
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                }
            }
        }
        .searCard()
    }

    private func block(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(Theme.rounded(17, .bold))
                .foregroundStyle(Theme.ink)
            Text(text)
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .searCard()
    }

    private func copyToEdit() {
        // Duplicating a rub is a "custom rub" — gate on the free limit.
        let customCount = (try? context.fetchCount(
            FetchDescriptor<Rub>(predicate: #Predicate { $0.isBuiltInCopy == true })
        )) ?? 0
        if !isPro && customCount >= Pro.freeCustomRubLimit {
            paywallReason = .moreRubs
            return
        }
        let copy = Rub(name: rub.name + " (copy)",
                       ingredients: rub.ingredients,
                       steps: rub.steps,
                       notes: rub.notes,
                       isBuiltInCopy: true)
        context.insert(copy)
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
    }
}

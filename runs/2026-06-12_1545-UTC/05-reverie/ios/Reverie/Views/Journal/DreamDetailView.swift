import SwiftUI
import SwiftData

struct DreamDetailView: View {
    @Bindable var dream: Dream
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("serifNarrative") private var serifNarrative = true
    @State private var showEdit = false
    @State private var showDelete = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerCard
                narrativeCard
                if !dream.signs.isEmpty { signsCard }
                attributesCard
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .background(Theme.bgPrimary.ignoresSafeArea())
        .navigationTitle(dream.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showEdit = true } label: { Label("Edit", systemImage: "pencil") }
                    Button(role: .destructive) { showDelete = true } label: { Label("Delete", systemImage: "trash") }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .sheet(isPresented: $showEdit) { DreamEditView(dream: dream) }
        .confirmationDialog("Delete this dream?", isPresented: $showDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { context.delete(dream); try? context.save(); dismiss() }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var headerCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                LucidityBadge(lucidity: dream.lucidity)
                Label(dream.mood.rawValue, systemImage: dream.mood.symbol)
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(dream.mood.color.opacity(0.16), in: Capsule())
                    .foregroundStyle(dream.mood.color)
                Spacer()
                VividnessDots(level: dream.vividness)
            }
            Text(Fmt.relativeDay(dream.date))
                .font(.subheadline).foregroundStyle(Theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .reverieCard()
    }

    private var narrativeCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            if dream.narrative.isEmpty {
                Text("No description recorded.").font(.body).foregroundStyle(Theme.textSecondary).italic()
            } else {
                Text(dream.narrative)
                    .font(.system(.body, design: serifNarrative ? .serif : .default))
                    .foregroundStyle(Theme.textPrimary)
                    .lineSpacing(5)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .reverieCard()
    }

    private var signsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Dream signs").font(.subheadline.weight(.semibold)).foregroundStyle(Theme.textSecondary)
            FlowLayout(spacing: 8) {
                ForEach(dream.signs.sorted { $0.name < $1.name }) { SignChip(sign: $0) }
            }
        }
        .reverieCard()
    }

    private var attributesCard: some View {
        VStack(spacing: 0) {
            row("Lucidity", dream.lucidity.label)
            Divider().overlay(Theme.track)
            row("Technique used", dream.technique.rawValue)
            if dream.isRecurring { Divider().overlay(Theme.track); row("Recurring", "Yes") }
            if dream.isNightmare { Divider().overlay(Theme.track); row("Nightmare", "Yes") }
            Divider().overlay(Theme.track)
            row("Recorded", Fmt.date(dream.date))
        }
        .reverieCard()
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(Theme.textSecondary)
            Spacer()
            Text(value).font(.subheadline.weight(.medium)).foregroundStyle(Theme.textPrimary)
        }
        .padding(.vertical, 9)
        .accessibilityElement(children: .combine)
    }
}

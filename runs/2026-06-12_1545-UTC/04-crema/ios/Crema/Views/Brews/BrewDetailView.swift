import SwiftUI
import SwiftData

struct BrewDetailView: View {
    @Bindable var brew: Brew
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var showEdit = false
    @State private var showDelete = false

    private var tips: [DialInTip] {
        var t = DialInEngine.extractionTips(for: brew)
        if let taste = brew.taste { t.append(DialInEngine.nextStep(taste: taste, method: brew.method)) }
        return t
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                recipeCard
                if let taste = brew.taste { tasteCard(taste) }
                if !tips.isEmpty { tipsCard }
                if !brew.notes.isEmpty { notesCard }
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .background(Theme.bgPrimary.ignoresSafeArea())
        .navigationTitle(brew.bean?.name ?? brew.method.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showEdit = true } label: { Label("Edit", systemImage: "pencil") }
                    Button(role: .destructive) { showDelete = true } label: { Label("Delete", systemImage: "trash") }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .sheet(isPresented: $showEdit) { BrewEditView(brew: brew, preselectedBean: brew.bean) }
        .confirmationDialog("Delete this brew?", isPresented: $showDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { deleteBrew() }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var recipeCard: some View {
        VStack(spacing: 14) {
            HStack {
                MethodPill(method: brew.method)
                Spacer()
                Text(Fmt.date(brew.date)).font(.caption).foregroundStyle(Theme.textSecondary)
            }
            HStack {
                metric(Fmt.grams(brew.doseGrams), "Dose")
                Image(systemName: "arrow.right").font(.caption).foregroundStyle(Theme.textSecondary)
                metric(Fmt.grams(brew.outputGrams), brew.method.isEspresso ? "Yield" : "Water")
                metric(brew.ratioString, "Ratio")
            }
            Divider().overlay(Theme.track)
            HStack {
                metric("\(Int(brew.timeSeconds))s", "Time")
                metric(String(format: "%.0f°C", brew.waterTempC), "Temp")
                metric(brew.grindSetting.isEmpty ? "—" : brew.grindSetting, "Grind")
            }
            if brew.method.isEspresso && brew.flowRate > 0 {
                Text(String(format: "Flow ≈ %.2f g/s", brew.flowRate))
                    .font(.caption).foregroundStyle(Theme.textSecondary)
            }
            if brew.ratingHalf > 0 {
                StarRating(ratingHalf: .constant(brew.ratingHalf), interactive: false, size: 20)
            }
        }
        .cremaCard()
    }

    private func metric(_ value: String, _ label: String) -> some View {
        VStack(spacing: 3) {
            Text(value).font(.system(.title3, design: .rounded).weight(.semibold)).foregroundStyle(Theme.textPrimary)
                .minimumScaleFactor(0.6).lineLimit(1)
            Text(label).font(.caption2).foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func tasteCard(_ taste: Taste) -> some View {
        HStack(spacing: 12) {
            Image(systemName: taste.symbol).font(.title2).foregroundStyle(taste.color)
            VStack(alignment: .leading, spacing: 2) {
                Text("Tasted").font(.caption).foregroundStyle(Theme.textSecondary)
                Text(taste.rawValue).font(.headline).foregroundStyle(Theme.textPrimary)
            }
            Spacer()
        }
        .cremaCard()
    }

    private var tipsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Dial-in", systemImage: "slider.horizontal.3")
                .font(.subheadline.weight(.semibold)).foregroundStyle(Theme.accent)
            ForEach(tips) { TipRow(tip: $0) }
        }
        .cremaCard()
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Notes").font(.subheadline.weight(.semibold)).foregroundStyle(Theme.textSecondary)
            Text(brew.notes).font(.body).foregroundStyle(Theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .cremaCard()
    }

    private func deleteBrew() {
        if let bean = brew.bean {
            bean.gramsUsed = max(0, bean.gramsUsed - brew.doseGrams)
        }
        context.delete(brew)
        try? context.save()
        dismiss()
    }
}

import SwiftUI
import SwiftData

/// Detail for a logged session: all parameters and notes, with inline editing of
/// the rating and notes, and a guarded delete.
struct SessionDetailView: View {
    @Bindable var session: DevSession
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @AppStorage("latent.tempUnit") private var tempUnitRaw = TempUnit.celsius.rawValue
    private var tempUnit: TempUnit { TempUnit(rawValue: tempUnitRaw) ?? .celsius }

    @State private var showDelete = false

    var body: some View {
        ZStack {
            Brand.pageBackground
            ScrollView {
                VStack(spacing: 16) {
                    header
                    paramsCard
                    phasesCard
                    ratingCard
                    notesCard
                    deleteButton
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Session")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Delete this session?", isPresented: $showDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                Haptics.warning()
                context.delete(session)
                try? context.save()
                dismiss()
            }
            Button("Keep", role: .cancel) {}
        }
        .onDisappear { try? context.save() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Eyebrow(text: Format.relativeDate(session.date))
            Text(session.recipeName.isEmpty ? session.summary : session.recipeName)
                .font(.title2.weight(.bold))
                .foregroundStyle(Brand.text)
            Text(session.summary)
                .font(.subheadline)
                .foregroundStyle(Brand.text2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    private var paramsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Parameters")
            InfoRow(label: "Temperature", value: Format.tempString(session.tempC, unit: tempUnit, decimals: 1), mono: true)
            Divider().overlay(Brand.hairline)
            InfoRow(label: "Push / pull", value: session.pushPullLabel, mono: true)
            Divider().overlay(Brand.hairline)
            InfoRow(label: "Exposure index", value: "EI \(session.ei)", mono: true)
            Divider().overlay(Brand.hairline)
            InfoRow(label: "Rolls", value: "\(session.rolls)", mono: true)
            Divider().overlay(Brand.hairline)
            InfoRow(label: "Developed", value: fullDate, mono: false)
        }
        .glassCard()
    }

    private var phasesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Phase times")
            InfoRow(label: "Develop", value: DevEngine.clock(session.devSec), mono: true)
            Divider().overlay(Brand.hairline)
            InfoRow(label: "Stop", value: DevEngine.clock(session.stopSec), mono: true)
            Divider().overlay(Brand.hairline)
            InfoRow(label: "Fix", value: DevEngine.clock(session.fixSec), mono: true)
            Divider().overlay(Brand.hairline)
            InfoRow(label: "Wash", value: DevEngine.clock(session.washSec), mono: true)
        }
        .glassCard()
    }

    private var ratingCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Rating")
            StarRating(rating: $session.rating, interactive: true, size: 26)
        }
        .glassCard()
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Notes")
            TextField("Add notes…", text: $session.notes, axis: .vertical)
                .lineLimit(2...6)
                .textFieldStyle(.roundedBorder)
        }
        .glassCard()
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            Haptics.tap()
            showDelete = true
        } label: {
            Label("Delete session", systemImage: "trash")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(GlassButtonStyle())
        .tint(Brand.danger)
        .padding(.top, 4)
    }

    private var fullDate: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: session.date)
    }
}

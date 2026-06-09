import SwiftUI
import SwiftData

struct RoutineDetailView: View {
    @Bindable var routine: Routine
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var playing = false
    @State private var editing = false
    @State private var confirmDelete = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                summaryCard
                stepsCard
                Button(role: .destructive) {
                    confirmDelete = true
                } label: {
                    Label("Delete routine", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyle())
                .tint(Brand.danger)
            }
            .padding(20)
        }
        .scrollContentBackground(.hidden)
        .background(Brand.pageBackground)
        .navigationTitle(routine.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.selection()
                    routine.isFavorite.toggle()
                    try? context.save()
                } label: {
                    Image(systemName: routine.isFavorite ? "star.fill" : "star")
                }
                .accessibilityLabel(routine.isFavorite ? "Remove favorite" : "Mark favorite")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { editing = true }
            }
        }
        .fullScreenCover(isPresented: $playing) {
            SessionPlayerView(routine: routine)
        }
        .sheet(isPresented: $editing) {
            RoutineBuilderView(routine: routine)
        }
        .alert("Delete this routine?", isPresented: $confirmDelete) {
            Button("Delete", role: .destructive) {
                context.delete(routine)
                try? context.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the routine. Stretches in your library are kept.")
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            if !routine.summary.isEmpty {
                Text(routine.summary)
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
            }
            HStack(spacing: 16) {
                Label(MobilityEngine.secondsString(routine.totalSeconds), systemImage: "clock")
                Label("\(routine.stretchCount) stretches", systemImage: "figure.flexibility")
            }
            .font(.footnote)
            .foregroundStyle(Brand.text3)
            Button {
                Haptics.tap()
                playing = true
            } label: {
                Label("Start session", systemImage: "play.fill")
            }
            .buttonStyle(InkButtonStyle())
            .disabled(routine.stretchCount == 0)
        }
        .glassCard()
    }

    private var stepsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: "Sequence")
            if routine.orderedSteps.isEmpty {
                Text("No stretches yet. Tap Edit to add some.")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text3)
            } else {
                ForEach(Array(routine.orderedSteps.enumerated()), id: \.element.id) { idx, step in
                    HStack(spacing: 12) {
                        Text("\(idx + 1)")
                            .font(Brand.mono(14, weight: .semibold))
                            .foregroundStyle(Brand.text3)
                            .frame(width: 22)
                        Image(systemName: step.stretch?.area.icon ?? "figure.flexibility")
                            .foregroundStyle(step.stretch?.area.tint ?? Brand.text3)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(step.stretch?.name ?? "Removed stretch")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Brand.text)
                            Text(step.stretch?.area.title ?? "")
                                .font(.caption)
                                .foregroundStyle(Brand.text3)
                        }
                        Spacer()
                        Text(step.bothSides ? "\(step.seconds)s ×2" : "\(step.seconds)s")
                            .font(Brand.mono(13))
                            .foregroundStyle(Brand.text2)
                    }
                    .padding(.vertical, 4)
                    .accessibilityElement(children: .combine)
                    if idx < routine.orderedSteps.count - 1 { Divider().overlay(Brand.hairline) }
                }
            }
        }
        .glassCard()
    }
}

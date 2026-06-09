import SwiftUI
import SwiftData

struct SessionDetailView: View {
    @Bindable var session: WorkoutSession

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var showDelete = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                HStack(spacing: 12) {
                    StatTile(value: Format.duration(session.actualSeconds), label: "Duration", tint: session.workoutCategory.tint)
                    StatTile(value: "\(session.roundsCompleted)", label: "Rounds")
                    StatTile(value: session.completed ? "Yes" : "No", label: "Completed")
                }

                ratingCard

                if !session.note.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionTitle(text: "Note")
                        Text(session.note)
                            .font(.body)
                            .foregroundStyle(Brand.text2)
                    }
                    .glassCard()
                }
            }
            .padding(20)
        }
        .background(Brand.pageBackground)
        .navigationTitle(session.workoutName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    showDelete = true
                } label: {
                    Image(systemName: "trash")
                }
                .accessibilityLabel("Delete session")
            }
        }
        .confirmationDialog("Delete this session?", isPresented: $showDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                context.delete(session)
                try? context.save()
                Haptics.warning()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                TagChip(text: session.workoutCategory.label,
                        systemImage: session.workoutCategory.symbol,
                        tint: session.workoutCategory.tint)
                if !session.completed {
                    TagChip(text: "Ended early", tint: Brand.warn)
                }
            }
            Text(Format.relativeDay(session.date))
                .font(.title3.weight(.semibold))
                .foregroundStyle(Brand.text)
            Text(session.date, style: .time)
                .font(.subheadline)
                .foregroundStyle(Brand.text2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var ratingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "How it felt")
            HStack(spacing: 14) {
                ForEach(1...5, id: \.self) { i in
                    Button {
                        Haptics.selection()
                        session.feeling = (session.feeling == i) ? 0 : i
                        try? context.save()
                    } label: {
                        Image(systemName: session.feeling >= i ? "circle.fill" : "circle")
                            .font(.title2)
                            .foregroundStyle(session.feeling >= i ? Brand.live : Brand.text3)
                    }
                    .accessibilityLabel("Rate \(i) of 5")
                    .accessibilityAddTraits(session.feeling == i ? [.isSelected] : [])
                }
            }
            Text(session.feeling == 0 ? "Tap to rate this session." : "Saved.")
                .font(.caption)
                .foregroundStyle(Brand.text3)
        }
        .glassCard()
    }
}

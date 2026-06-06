import SwiftUI

/// Detail for a single logged run.
struct SessionDetailView: View {
    let session: Session

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                GlassCard {
                    HStack(spacing: 0) {
                        StatBlock(value: DurationFormat.compact(session.activeSeconds), label: "Active")
                        Divider().frame(height: 36)
                        StatBlock(value: DurationFormat.compact(session.workSeconds),
                                  label: "Work", tint: Brand.live)
                        Divider().frame(height: 36)
                        StatBlock(value: "\(session.completedSteps)/\(session.totalSteps)", label: "Steps")
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        detailRow(label: "Started",
                                  value: session.startedAt.formatted(date: .abbreviated, time: .shortened))
                        Divider()
                        detailRow(label: "Ended",
                                  value: session.endedAt.formatted(date: .abbreviated, time: .shortened))
                        Divider()
                        detailRow(label: "Outcome",
                                  value: session.finishedFully ? "Completed fully" : "Ended early",
                                  valueTint: session.finishedFully ? Brand.live : Brand.text2)
                        Divider()
                        detailRow(label: "Completion",
                                  value: "\(Int((session.completionFraction * 100).rounded()))%")
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .background(Brand.pageBackground)
        .navigationTitle("Run")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill((session.finishedFully ? Brand.live : Brand.text3).opacity(0.16))
                    .frame(width: 52, height: 52)
                Image(systemName: session.finishedFully ? "checkmark" : "flag.checkered")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(session.finishedFully ? Brand.live : Brand.text3)
            }
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(session.routineNameSnapshot)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Brand.text)
                Text(session.startedAt.formatted(.relative(presentation: .named)))
                    .font(.caption)
                    .foregroundStyle(Brand.text3)
            }
            Spacer(minLength: 0)
        }
    }

    private func detailRow(label: String, value: String, valueTint: Color = Brand.text) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Brand.text2)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(valueTint)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        SessionDetailView(session: Session(startedAt: .now.addingTimeInterval(-600),
                                           endedAt: .now, activeSeconds: 600, workSeconds: 320,
                                           completedSteps: 20, totalSteps: 20,
                                           finishedFully: true, routineNameSnapshot: "Classic HIIT"))
    }
    .background(Brand.pageBackground)
}

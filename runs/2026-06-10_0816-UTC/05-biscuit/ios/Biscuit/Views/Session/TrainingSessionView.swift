import SwiftUI
import SwiftData

/// A guided, timed training session for one skill: live timer, integrated
/// clicker with a running count, then a save card (rating + note).
struct TrainingSessionView: View {
    let dog: Dog
    let skill: Skill

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("clickerHaptics") private var clickerHaptics = true
    @AppStorage("clickerSound") private var clickerSound = true

    @State private var startedAt = Date()
    @State private var clicks = 0
    @State private var finishing = false
    @State private var rating = 3
    @State private var note = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if finishing {
                    saveCard
                } else {
                    sessionCard
                }
            }
            .navigationTitle(skill.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        if finishing { finishing = false } else { dismiss() }
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel(finishing ? "Back to session" : "Cancel session")
                }
            }
        }
        .interactiveDismissDisabled()
        .onDisappear { Clicker.shared.stop() }
    }

    private var sessionCard: some View {
        VStack(spacing: 20) {
            TimelineView(.periodic(from: .now, by: 1)) { ctx in
                Text(DurationFormat.mmss(Int(ctx.date.timeIntervalSince(startedAt))))
                    .font(Brand.mono(54, weight: .semibold))
                    .foregroundStyle(Brand.text)
                    .contentTransition(.numericText())
                    .accessibilityLabel("Session time")
            }
            .padding(.top, 24)

            VStack(spacing: 6) {
                Text(skill.goal)
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            // The clicker button
            Button {
                tapClicker()
            } label: {
                ZStack {
                    Circle()
                        .fill(Brand.inkGradient)
                        .frame(width: 200, height: 200)
                        .shadow(color: Brand.cardShadow, radius: 18, x: 0, y: 10)
                    VStack(spacing: 6) {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 46))
                            .foregroundStyle(.white)
                        Text("CLICK")
                            .font(Brand.mono(15, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
            }
            .buttonStyle(ClickerButtonStyle())
            .accessibilityLabel("Clicker")
            .accessibilityHint("Mark the moment your dog does the right thing")

            Text("\(clicks) clicks this session")
                .font(Brand.mono(14, weight: .medium))
                .foregroundStyle(Brand.text3)

            Spacer()

            Button {
                finishing = true
            } label: {
                Label("End & save", systemImage: "checkmark")
            }
            .buttonStyle(InkButtonStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
    }

    private var saveCard: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("How did it go?")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Brand.text)
                    .padding(.top, 12)

                HStack(spacing: 12) {
                    ratingButton(1, "😮‍💨", "Tough")
                    ratingButton(2, "🙂", "Okay")
                    ratingButton(3, "🎉", "Great")
                }

                VStack(spacing: 10) {
                    summaryRow("Duration", DurationFormat.mmss(elapsed))
                    summaryRow("Clicks", "\(clicks)")
                }
                .glassCard()

                TextField("Notes (optional)", text: $note, axis: .vertical)
                    .lineLimit(2...4)
                    .padding(14)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: 1))

                Button("Save session") { save() }
                    .buttonStyle(InkButtonStyle())

                Text("End on a win — a session that finishes happy is the one your dog remembers.")
                    .font(.caption)
                    .foregroundStyle(Brand.text3)
                    .multilineTextAlignment(.center)
            }
            .padding(16)
        }
    }

    private var elapsed: Int { Int(Date().timeIntervalSince(startedAt)) }

    private func ratingButton(_ value: Int, _ emoji: String, _ label: String) -> some View {
        Button {
            rating = value
            Haptics.selection()
        } label: {
            VStack(spacing: 6) {
                Text(emoji).font(.system(size: 34))
                Text(label)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Brand.text)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(rating == value ? Brand.live.opacity(0.7) : Brand.glassStroke.opacity(0.5), lineWidth: 1.5))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(label) session")
        .accessibilityAddTraits(rating == value ? .isSelected : [])
    }

    private func summaryRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Brand.text2)
            Spacer()
            Text(value)
                .font(Brand.mono(16, weight: .semibold))
                .foregroundStyle(Brand.text)
        }
        .accessibilityElement(children: .combine)
    }

    private func tapClicker() {
        clicks += 1
        if clickerSound { Clicker.shared.click() }
        if clickerHaptics { Haptics.tap() }
    }

    private func save() {
        let session = TrainingSession(date: startedAt, skillID: skill.id,
                                      durationSeconds: max(elapsed, 1),
                                      rating: rating, clicks: clicks,
                                      note: note.trimmingCharacters(in: .whitespacesAndNewlines))
        context.insert(session)
        session.dog = dog

        // Touch the skill's progress so it shows as practiced.
        if let p = TrainingEngine.progress(for: dog, skillID: skill.id) {
            p.lastPracticed = .now
        } else {
            let p = SkillProgress(skillID: skill.id)
            p.startedAt = startedAt
            p.lastPracticed = .now
            p.completedSteps = max(p.completedSteps, 1)
            context.insert(p)
            p.dog = dog
        }
        Haptics.success()
        dismiss()
    }
}

/// Snappy press feedback for the big clicker button.
struct ClickerButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.93 : 1)
            .animation(.spring(response: 0.18, dampingFraction: 0.5), value: configuration.isPressed)
    }
}

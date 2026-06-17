import SwiftUI
import SwiftData

/// Success screen shown when a session completes. Captures an optional feel
/// rating and a manual distance, then saves the CompletedSession and advances
/// the enrollment pointer.
struct CompletionView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Bindable var player: PlayerEngine
    @Binding var isPresented: Bool

    @State private var feltRating: Int = 0
    @State private var distanceText: String = ""
    @State private var saved = false
    @State private var celebrate = false

    private var plan: TrainingPlan? { PlanResolver.shared.plan(id: player.planId) }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                Spacer(minLength: 24)
                ZStack {
                    Circle().fill(.white.opacity(0.2)).frame(width: 132, height: 132)
                    Image(systemName: "checkmark")
                        .font(.system(size: 64, weight: .heavy))
                        .foregroundStyle(.white)
                        .scaleEffect(celebrate && !reduceMotion ? 1.0 : 0.85)
                }
                .accessibilityHidden(true)
                .onAppear {
                    if reduceMotion { celebrate = true }
                    else { withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { celebrate = true } }
                }

                VStack(spacing: 6) {
                    Text("Workout complete!")
                        .font(Theme.display(30))
                        .foregroundStyle(.white)
                    Text(plan.map { "\($0.title) · Week \(player.week), Session \(player.sessionIndex + 1)" } ?? "Nice work")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                }

                // Stats
                HStack(spacing: 0) {
                    completionStat("\(Int((Double(player.totalSeconds) / 60).rounded()))", "minutes")
                    Divider().frame(height: 36).overlay(.white.opacity(0.3))
                    completionStat("\(Int((Double(player.runSecondsElapsed(now: Date())) / 60).rounded()))", "run min")
                }
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.white.opacity(0.15)))

                // Feel rating
                VStack(spacing: 10) {
                    Text("How did it feel?")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    HStack(spacing: 10) {
                        ForEach(1...5, id: \.self) { i in
                            Button {
                                feltRating = (feltRating == i) ? 0 : i
                                Haptics.tap(settings.hapticCues)
                            } label: {
                                Image(systemName: i <= feltRating ? "star.fill" : "star")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                            }
                            .accessibilityLabel("\(i) star\(i == 1 ? "" : "s")")
                            .accessibilityAddTraits(i <= feltRating ? [.isSelected] : [])
                        }
                    }
                }

                // Manual distance
                VStack(spacing: 8) {
                    Text("Distance (optional)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    HStack {
                        TextField("0.0", text: $distanceText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 10)
                            .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.9)))
                            .foregroundStyle(Theme.primaryText(.light))
                            .frame(width: 110)
                            .accessibilityLabel("Distance in \(settings.units.label)")
                        Text(settings.units.label)
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                }

                Button {
                    save()
                } label: {
                    Label(saved ? "Saved" : "Save & finish", systemImage: saved ? "checkmark" : "square.and.arrow.down")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Theme.coral)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white))
                }
                .disabled(saved)

                Button("Discard") {
                    player.stop()
                    isPresented = false
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.85))
                .padding(.bottom, 24)
            }
            .padding(20)
        }
        .background(
            LinearGradient(colors: [Theme.positive, Theme.tealDeep], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
    }

    private func completionStat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(Theme.numeral(30)).foregroundStyle(.white)
            Text(label).font(.caption.weight(.semibold)).foregroundStyle(.white.opacity(0.85))
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }

    private func save() {
        guard let plan, !saved else { return }
        let distanceMeters = parseDistance()
        Enrollment.recordCompletion(
            plan: plan,
            week: player.week,
            sessionIndex: player.sessionIndex,
            durationSeconds: player.totalSeconds,
            runSeconds: player.runSecondsElapsed(now: Date()),
            feltRating: feltRating == 0 ? nil : feltRating,
            distanceMeters: distanceMeters,
            context: modelContext
        )
        saved = true
        Haptics.success(settings.hapticCues)
        player.stop()
        // Small delay-free dismissal; the engine is now idle.
        isPresented = false
    }

    /// Parse the manual distance field into meters. Locale-tolerant; nil if blank/invalid.
    private func parseDistance() -> Double? {
        let trimmed = distanceText.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        guard !trimmed.isEmpty, let value = Double(trimmed), value > 0 else { return nil }
        return settings.units.toMeters(value)
    }
}

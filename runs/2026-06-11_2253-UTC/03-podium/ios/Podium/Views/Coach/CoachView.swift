import SwiftUI

/// Drills with technique guidance — each launches a targeted practice take.
struct CoachView: View {
    @Environment(\.colorScheme) private var scheme
    @State private var selectedDrill: Drill?
    @State private var practicePrompt: Prompt?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Six drills, each attacking one habit. Do one per day; watch the Progress tab move.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.inkSoft(scheme))
                    ForEach(DrillLibrary.all) { drill in
                        drillCard(drill)
                    }
                }
                .padding()
            }
            .background(Theme.background(scheme))
            .navigationTitle("Coach")
            .sheet(item: $selectedDrill) { drill in
                drillDetail(drill)
            }
            .fullScreenCover(item: $practicePrompt) { prompt in
                RecordingView(prompt: prompt)
            }
        }
    }

    private func drillCard(_ drill: Drill) -> some View {
        Button {
            Haptics.tap()
            selectedDrill = drill
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "target")
                    .font(.title2)
                    .foregroundStyle(Theme.violet)
                    .frame(width: 40)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text(drill.title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Theme.ink(scheme))
                    Text("Focus: \(drill.focus) · ~\(drill.suggestedSeconds)s")
                        .font(.caption)
                        .foregroundStyle(Theme.inkSoft(scheme))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Theme.inkSoft(scheme))
                    .accessibilityHidden(true)
            }
            .podiumCard()
        }
        .buttonStyle(.plain)
        .accessibilityHint("Shows the drill instructions")
    }

    private func drillDetail(_ drill: Drill) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Label(drill.focus, systemImage: "target")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Theme.violet.opacity(0.15), in: Capsule())
                        .foregroundStyle(Theme.violet)
                    Text(drill.instructions)
                        .font(.body)
                        .foregroundStyle(Theme.ink(scheme))
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Prompt for this drill")
                            .font(.caption)
                            .foregroundStyle(Theme.inkSoft(scheme))
                        let prompt = DrillLibrary.prompt(for: drill)
                        Text(prompt.title)
                            .font(.subheadline.weight(.semibold))
                        Text(prompt.text)
                            .font(.caption)
                            .foregroundStyle(Theme.inkSoft(scheme))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .podiumCard()
                    Button {
                        let prompt = DrillLibrary.prompt(for: drill)
                        selectedDrill = nil
                        // Present the recorder after the sheet closes.
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            practicePrompt = prompt
                        }
                    } label: {
                        Label("Start drill", systemImage: "mic.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.violet)
                }
                .padding()
            }
            .background(Theme.background(scheme))
            .navigationTitle(drill.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { selectedDrill = nil }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

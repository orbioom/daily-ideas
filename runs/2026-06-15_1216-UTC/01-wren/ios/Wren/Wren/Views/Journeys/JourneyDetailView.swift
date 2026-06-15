import SwiftUI

struct JourneyDetailView: View {
    let journey: Journey
    let currentEnergy: Int
    let onStart: () -> Void
    @Environment(\.dismiss) private var dismiss

    private var canAfford: Bool { currentEnergy >= journey.energyCost }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    SceneArtView(scene: journey.rewardScene)
                        .frame(height: 170)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous).strokeBorder(Theme.hairline))

                    Text(journey.title)
                        .font(Theme.serif(26, .bold))
                        .foregroundStyle(Theme.ink)
                    Text(journey.detail)
                        .font(Theme.rounded(15))
                        .foregroundStyle(Theme.inkSoft)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 12) {
                        infoTile("\(journey.energyCost)", "Energy cost", "bolt.fill", canAfford ? Theme.good : Theme.bad)
                        infoTile("\(journey.requiredCompletions)", "Acts of care", "checkmark.seal", Theme.accent)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Label("Reward", systemImage: journey.rewardKind.systemImage)
                            .font(Theme.rounded(13, .semibold))
                            .foregroundStyle(Theme.inkSoft)
                        Text(journey.rewardName)
                            .font(Theme.rounded(18, .bold))
                            .foregroundStyle(Theme.ink)
                        if journey.rewardKind == .pebbles {
                            Text("+\(journey.rewardPebbles) pebbles on arrival")
                                .font(Theme.rounded(13))
                                .foregroundStyle(Theme.warn)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .card(Theme.surfaceAlt)

                    if !canAfford {
                        Text("Your Wren needs \(journey.energyCost - currentEnergy) more energy. Complete a few goals first.")
                            .font(Theme.rounded(13))
                            .foregroundStyle(Theme.bad)
                            .multilineTextAlignment(.center)
                    }

                    Button("Set off") { onStart() }
                        .buttonStyle(WrenPrimaryButtonStyle())
                        .disabled(!canAfford)
                }
                .padding()
            }
            .background(Theme.bg)
            .navigationTitle("Journey")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func infoTile(_ value: String, _ label: String, _ icon: String, _ tint: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).foregroundStyle(tint)
            Text(value).font(Theme.rounded(20, .bold)).foregroundStyle(Theme.ink)
            Text(label).font(Theme.rounded(11)).foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .card(Theme.surface)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

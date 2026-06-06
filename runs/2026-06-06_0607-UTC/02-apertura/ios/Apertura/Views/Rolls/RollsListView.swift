import SwiftUI
import SwiftData

/// The roll library: every roll with stock, format, frame count, and status.
struct RollsListView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var context
    @Query(sort: \Roll.createdAt, order: .reverse) private var rolls: [Roll]

    @State private var path: [Roll] = []
    @State private var showingNewRoll = false

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Brand.pageBackground

                if rolls.isEmpty {
                    EmptyStateView(
                        icon: "film",
                        title: "No rolls yet",
                        message: "Start a roll — pick the film stock, ISO, format, and camera — then log the frames you shoot.",
                        actionTitle: "Start a roll",
                        action: { showingNewRoll = true }
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(rolls) { roll in
                                Button {
                                    path.append(roll)
                                } label: {
                                    RollCard(roll: roll)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Rolls")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingNewRoll = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("New roll")
                }
            }
            .navigationDestination(for: Roll.self) { roll in
                RollDetailView(roll: roll)
            }
            .sheet(isPresented: $showingNewRoll) {
                RollEditView(roll: nil)
            }
        }
    }
}

/// A single roll summary card.
private struct RollCard: View {
    var roll: Roll

    private var frameCount: Int { roll.frames.count }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: roll.format.systemImage)
                        .font(.title2)
                        .foregroundStyle(Brand.text)
                        .frame(width: 30)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(roll.filmStock)
                            .font(.headline)
                            .foregroundStyle(Brand.text)
                            .lineLimit(1)
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(Brand.text2)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 4)
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Brand.text3)
                        .accessibilityHidden(true)
                }

                Divider().overlay(Brand.glassStroke.opacity(0.4))

                HStack {
                    FormatBadge(format: roll.format)
                    Text("ISO \(Int(roll.iso.rounded()))")
                        .font(Brand.mono(13, weight: .semibold))
                        .foregroundStyle(Brand.text2)
                    Spacer()
                    if roll.isFinished {
                        Label("Developed", systemImage: "checkmark.seal.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Brand.live)
                            .labelStyle(.titleAndIcon)
                    } else {
                        Text("\(frameCount) frame\(frameCount == 1 ? "" : "s")")
                            .font(Brand.mono(13, weight: .semibold))
                            .foregroundStyle(Brand.text2)
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(roll.filmStock), \(roll.format.title), ISO \(Int(roll.iso.rounded())), \(frameCount) frames\(roll.isFinished ? ", developed" : "")")
        .accessibilityHint("Opens the roll")
    }

    private var subtitle: String {
        let cam = roll.camera.isEmpty ? "No camera noted" : roll.camera
        return cam
    }
}

#Preview {
    RollsListView()
        .environment(SettingsStore())
        .modelContainer(for: [Roll.self, Frame.self], inMemory: true)
}

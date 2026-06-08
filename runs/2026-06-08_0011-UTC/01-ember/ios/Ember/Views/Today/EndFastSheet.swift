import SwiftUI
import SwiftData

/// Presented right after a fast ends: rate how it felt and add a note.
struct EndFastSheet: View {
    @Bindable var fast: Fast
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(spacing: 6) {
                            Image(systemName: fast.didReachGoal ? "checkmark.seal.fill" : "flag.checkered")
                                .font(.system(size: 48))
                                .foregroundStyle(fast.didReachGoal ? Brand.live : Brand.text2)
                                .accessibilityHidden(true)
                            Text("\(Format.hours(fast.elapsedSeconds / 3600)) hours")
                                .font(Brand.mono(34, weight: .semibold))
                                .foregroundStyle(Brand.text)
                            Text(fast.didReachGoal
                                 ? "You hit your \(Int(fast.goalHours))h goal."
                                 : "Fast logged — every hour counts.")
                                .font(.subheadline)
                                .foregroundStyle(Brand.text2)
                        }
                        .padding(.top, 12)

                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Eyebrow(text: "HOW DID YOU FEEL?")
                                HStack(spacing: 10) {
                                    ForEach(1...5, id: \.self) { i in
                                        Button {
                                            fast.feeling = i
                                            Haptics.selection()
                                        } label: {
                                            Image(systemName: i <= fast.feeling ? "star.fill" : "star")
                                                .font(.title2)
                                                .foregroundStyle(i <= fast.feeling ? Color(hex: 0xE0884F) : Brand.text3)
                                                .frame(maxWidth: .infinity)
                                        }
                                        .buttonStyle(.plain)
                                        .accessibilityLabel("\(i) star\(i == 1 ? "" : "s")")
                                    }
                                }
                            }
                        }

                        GlassCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Eyebrow(text: "NOTE")
                                TextField("Anything worth remembering?",
                                          text: $fast.note, axis: .vertical)
                                    .lineLimit(2...5)
                                    .font(.body)
                                    .foregroundStyle(Brand.text)
                            }
                        }

                        Button("Save") {
                            try? context.save()
                            Haptics.success()
                            dismiss()
                        }
                        .buttonStyle(InkButtonStyle())
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Fast complete")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { try? context.save(); dismiss() }
                }
            }
        }
    }
}

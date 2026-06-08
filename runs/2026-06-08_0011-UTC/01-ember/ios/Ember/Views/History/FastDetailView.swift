import SwiftUI
import SwiftData

struct FastDetailView: View {
    @Bindable var fast: Fast
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Brand.pageBackground
            ScrollView {
                VStack(spacing: 18) {
                    GlassCard {
                        VStack(spacing: 8) {
                            Text("\(Format.hours(fast.elapsedSeconds / 3600)) h")
                                .font(Brand.mono(40, weight: .semibold))
                                .foregroundStyle(Brand.text)
                            if fast.didReachGoal {
                                Label("Reached \(Int(fast.goalHours))h goal", systemImage: "checkmark.circle.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(Brand.live)
                            } else {
                                Text("\(Int(fast.goalHours))h goal")
                                    .font(.subheadline)
                                    .foregroundStyle(Brand.text2)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            detailRow("Plan", fast.planName)
                            Divider().overlay(Brand.hairline)
                            detailRow("Started", Format.dayTime.string(from: fast.start))
                            Divider().overlay(Brand.hairline)
                            detailRow("Ended", fast.end.map { Format.dayTime.string(from: $0) } ?? "—")
                            Divider().overlay(Brand.hairline)
                            let stage = FastEngine.currentStage(elapsedHours: fast.elapsedSeconds / 3600)
                            detailRow("Reached stage", stage.title)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Eyebrow(text: "HOW IT FELT")
                            HStack(spacing: 10) {
                                ForEach(1...5, id: \.self) { i in
                                    Button {
                                        fast.feeling = (fast.feeling == i) ? 0 : i
                                        try? context.save(); Haptics.selection()
                                    } label: {
                                        Image(systemName: i <= fast.feeling ? "star.fill" : "star")
                                            .font(.title3)
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
                            TextField("Add a note", text: $fast.note, axis: .vertical)
                                .lineLimit(2...6)
                                .foregroundStyle(Brand.text)
                                .onChange(of: fast.note) { _, _ in try? context.save() }
                        }
                    }

                    Button(role: .destructive) {
                        context.delete(fast)
                        try? context.save()
                        Haptics.warning()
                        dismiss()
                    } label: {
                        Label("Delete fast", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(GlassButtonStyle())
                }
                .padding(20)
            }
        }
        .navigationTitle("Fast")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(Brand.text2)
            Spacer()
            Text(value).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
        }
    }
}

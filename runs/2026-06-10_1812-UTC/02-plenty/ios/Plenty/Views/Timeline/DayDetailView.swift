import SwiftUI

struct DayDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let day: GratitudeDay

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        if let mood = Mood(rawValue: day.mood) {
                            HStack(spacing: 10) {
                                Text(mood.emoji).font(.largeTitle)
                                Text("Felt \(mood.label.lowercased())")
                                    .font(.title3.weight(.semibold)).foregroundStyle(Brand.text)
                            }
                        }
                        if !day.filledGratitudes.isEmpty {
                            section("Grateful for", items: day.filledGratitudes, icon: "sunrise.fill", tint: Brand.warn)
                        }
                        if !day.dailyIntention.trimmingCharacters(in: .whitespaces).isEmpty {
                            section("Intention", items: [day.dailyIntention], icon: "scope", tint: Brand.magic)
                        }
                        if !day.filledWins.isEmpty {
                            section("Good things", items: day.filledWins, icon: "star.fill", tint: Brand.info)
                        }
                        if !day.improvement.trimmingCharacters(in: .whitespaces).isEmpty {
                            section("Could improve", items: [day.improvement], icon: "arrow.up.forward", tint: Brand.text2)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle(day.date.formatted(.dateTime.month().day().year()))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func section(_ title: String, items: [String], icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon).foregroundStyle(tint)
                Eyebrow(text: title)
            }
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                Text("• \(item)").font(.body).foregroundStyle(Brand.text)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }
}

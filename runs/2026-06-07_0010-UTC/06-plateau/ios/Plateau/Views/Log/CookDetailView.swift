import SwiftUI
import SwiftData

struct CookDetailView: View {
    @Bindable var cook: Cook
    @Environment(\.modelContext) private var context
    @AppStorage("useMetric") private var useMetric = true

    var body: some View {
        ZStack {
            Brand.pageBackground
            ScrollView {
                VStack(spacing: 16) {
                    header
                    breakdownCard
                    ratingCard
                    notesCard
                }
                .padding(.horizontal, 18).padding(.vertical, 12)
            }
        }
        .navigationTitle(cook.foodName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    cook.isFavorite.toggle(); try? context.save(); Haptics.tap()
                } label: {
                    Image(systemName: cook.isFavorite ? "star.fill" : "star")
                        .foregroundStyle(cook.isFavorite ? Brand.warn : Brand.text2)
                }
                .accessibilityLabel(cook.isFavorite ? "Unfavorite" : "Favorite")
            }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Text(TempFmt.temp(cook.bathC, metric: useMetric))
                .font(Brand.mono(36, weight: .bold)).foregroundStyle(Brand.text)
            HStack(spacing: 8) {
                Chip(text: cook.category.isEmpty ? cook.shape.short : cook.category)
                Chip(text: "\(Int(cook.thicknessMM)) mm")
                Chip(text: cook.startState.label)
            }
            Text(Fmt.date(cook.startedAt)).font(.caption).foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity).glassCard(padding: 20)
    }

    private var breakdownCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Time breakdown")
            row("Come-up", TempFmt.duration(cook.comeUpMinutes), Brand.info)
            if cook.pasteurizeMinutes > 0 {
                row("Pasteurization hold", TempFmt.duration(cook.pasteurizeMinutes), Brand.live)
                row("Log reductions", "\(formatted(cook.logReductions))-log", Brand.text2)
            } else {
                row("Pasteurization", "Cook-and-serve", Brand.warn)
            }
            Divider().overlay(Brand.hairline)
            row("Total", TempFmt.duration(cook.totalMinutes), Brand.text)
        }
        .glassCard()
    }

    private func row(_ label: String, _ value: String, _ tint: Color) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(Brand.text2)
            Spacer()
            Text(value).font(Brand.mono(15, weight: .semibold)).foregroundStyle(tint)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private var ratingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Your rating")
            HStack(spacing: 10) {
                ForEach(1...5, id: \.self) { i in
                    Button {
                        cook.rating = (cook.rating == i) ? 0 : i
                        try? context.save(); Haptics.selection()
                    } label: {
                        Image(systemName: i <= cook.rating ? "star.fill" : "star")
                            .font(.title2).foregroundStyle(i <= cook.rating ? Brand.warn : Brand.text3)
                    }
                    .accessibilityLabel("\(i) star\(i == 1 ? "" : "s")")
                }
                Spacer()
            }
        }
        .glassCard()
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Notes")
            TextField("How did it turn out?", text: $cook.notes, axis: .vertical)
                .lineLimit(3...6)
                .font(.subheadline)
                .onChange(of: cook.notes) { _, _ in try? context.save() }
        }
        .glassCard()
    }

    private func formatted(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(v)) : String(v)
    }
}

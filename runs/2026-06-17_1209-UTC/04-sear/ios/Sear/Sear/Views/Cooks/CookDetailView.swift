import SwiftUI
import SwiftData

/// Detail for any cook. Active/planned cooks get a "track live" button; done cooks
/// show their results and temp curve.
struct CookDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss
    @Bindable var cook: Cook

    @State private var showRating = false

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    headerCard
                    if cook.status.isActive {
                        NavigationLink {
                            LiveCookView(cook: cook)
                        } label: {
                            Label("Track this cook live", systemImage: "flame.fill")
                                .font(Theme.rounded(16, .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.accent))
                        }
                    } else if cook.status == .planned {
                        PrimaryButton(title: "Start this cook", systemImage: "play.fill") {
                            start()
                        }
                    }
                    detailsCard
                    if !cook.tempLogs.isEmpty {
                        TempCurveCard(cook: cook)
                    }
                    if cook.status == .done {
                        resultCard
                    }
                    if !cook.notes.isEmpty {
                        notesCard
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle(cook.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showRating) {
            RateCookSheet(cook: cook)
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Pill(text: cook.status.label, systemImage: cook.status.symbol, tint: cook.status.hue)
                Pill(text: cook.method.label, systemImage: cook.method.symbol, tint: cook.method.hue)
            }
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(settings.temp(cook.targetInternalTempC))
                    .font(Theme.numeral(40, .heavy))
                    .foregroundStyle(Theme.accent)
                    .monospacedDigit()
                Text("target")
                    .font(Theme.rounded(15))
                    .foregroundStyle(Theme.inkSoft)
            }
            Text("\(cook.protein.label) · \(cook.cut)")
                .font(Theme.rounded(15, .semibold))
                .foregroundStyle(Theme.ink)
        }
        .searCard()
    }

    private var detailsCard: some View {
        VStack(spacing: 10) {
            row("Weight", settings.weight(cook.weightKg), "scalemass")
            Divider().background(Theme.hairline)
            row("Pit temp", settings.temp(cook.ambientTempC), "flame")
            if let wood = cook.woodType {
                Divider().background(Theme.hairline)
                row("Wood", wood, "leaf")
            }
            if let rub = cook.rubName {
                Divider().background(Theme.hairline)
                row("Rub", rub, "fork.knife")
            }
            if let start = cook.startDate {
                Divider().background(Theme.hairline)
                row("Started", start.formatted(date: .abbreviated, time: .shortened), "clock")
            }
        }
        .searCard()
    }

    private func row(_ title: String, _ value: String, _ symbol: String) -> some View {
        HStack {
            Label(title, systemImage: symbol)
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.inkSoft)
            Spacer()
            Text(value)
                .font(Theme.rounded(15, .semibold))
                .foregroundStyle(Theme.ink)
        }
        .accessibilityElement(children: .combine)
    }

    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Result")
                .font(Theme.rounded(17, .bold))
                .foregroundStyle(Theme.ink)
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { i in
                    Image(systemName: i <= (cook.clampedRating ?? 0) ? "star.fill" : "star")
                        .foregroundStyle(Theme.ember)
                }
                Spacer()
                Button("Edit rating") { showRating = true }
                    .font(Theme.rounded(13, .semibold))
                    .foregroundStyle(Theme.accent)
            }
            .accessibilityLabel("Rated \(cook.clampedRating ?? 0) of 5")
        }
        .searCard()
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(Theme.rounded(17, .bold))
                .foregroundStyle(Theme.ink)
            Text(cook.notes)
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .searCard()
    }

    private func start() {
        cook.status = .cooking
        cook.startDate = Date()
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
    }
}

/// Compact temperature curve chart used in cook detail.
private struct TempCurveCard: View {
    @Environment(AppSettings.self) private var settings
    let cook: Cook

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Temperature log")
                .font(Theme.rounded(17, .bold))
                .foregroundStyle(Theme.ink)
            TempCurveChart(cook: cook)
                .frame(height: 160)
        }
        .searCard()
    }
}

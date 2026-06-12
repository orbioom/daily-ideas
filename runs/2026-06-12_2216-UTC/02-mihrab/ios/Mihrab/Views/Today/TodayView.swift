import SwiftUI

struct TodayView: View {
    @AppStorage("cityID") private var cityID = Gazetteer.defaultCityID
    @AppStorage("method") private var methodRaw = CalculationMethod.mwl.rawValue
    @AppStorage("hanafiAsr") private var hanafiAsr = false
    @AppStorage("use24Hour") private var use24Hour = false
    @Environment(\.colorScheme) private var colorScheme

    @State private var dayOffset = 0

    private var settings: PrayerSettings {
        PrayerSettings(
            city: Gazetteer.city(id: cityID) ?? Gazetteer.cities[0],
            method: CalculationMethod(rawValue: methodRaw) ?? .mwl,
            hanafiAsr: hanafiAsr,
            use24Hour: use24Hour
        )
    }

    private var displayedDate: Date {
        Calendar.current.date(byAdding: .day, value: dayOffset, to: .now) ?? .now
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    header
                    dayNavigator
                    timesList
                    methodFootnote
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Mihrab")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Header (sky panel with countdown)

    private var header: some View {
        let formatter = settings.timeFormatter()

        return TimelineView(.periodic(from: .now, by: 1)) { context in
            let next = nextPrayer(after: context.date)
            VStack(spacing: 10) {
                Label(settings.city.displayName, systemImage: "building.2")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.8))
                if let next {
                    Text(next.prayer.displayName)
                        .font(.system(.largeTitle, design: .serif, weight: .semibold))
                        .foregroundStyle(MihrabTheme.gold)
                    Text(next.prayer.arabicName)
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.85))
                    Text("in \(countdownString(to: next.date, from: context.date)) · \(formatter.string(from: next.date))")
                        .font(.callout.monospacedDigit())
                        .foregroundStyle(.white)
                } else {
                    Text("All prayer times computed")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                Divider().overlay(.white.opacity(0.3))
                HStack {
                    Text(Date.now, format: .dateTime.weekday(.wide).day().month(.wide))
                    Spacer()
                    Text(settings.hijriString(for: .now))
                }
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.75))
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(MihrabTheme.skyGradient(colorScheme), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .accessibilityElement(children: .combine)
        }
    }

    /// Next of today's (or tomorrow's fajr) obligatory+sunrise times.
    private func nextPrayer(after date: Date) -> (prayer: Prayer, date: Date)? {
        let today = settings.times(on: date)
        let candidates = Prayer.allCases.compactMap { p -> (Prayer, Date)? in
            guard let t = today.time(for: p) else { return nil }
            return (p, t)
        }.filter { $0.1 > date }
        if let first = candidates.min(by: { $0.1 < $1.1 }) {
            return first
        }
        // After isha: show tomorrow's fajr.
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: date) else { return nil }
        let t = settings.times(on: tomorrow)
        guard let fajr = t.time(for: .fajr) else { return nil }
        return (.fajr, fajr)
    }

    private func countdownString(to target: Date, from now: Date) -> String {
        let seconds = max(0, Int(target.timeIntervalSince(now)))
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 { return String(format: "%dh %02dm", h, m) }
        return String(format: "%dm %02ds", m, s)
    }

    // MARK: - Day navigation + times

    private var dayNavigator: some View {
        HStack {
            Button {
                Haptics.tap()
                dayOffset -= 1
            } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 36, height: 36)
            }
            .accessibilityLabel("Previous day")

            Spacer()
            VStack(spacing: 2) {
                Text(displayedDate, format: .dateTime.weekday(.wide).day().month(.abbreviated))
                    .font(.headline)
                Text(settings.hijriString(for: displayedDate))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()

            Button {
                Haptics.tap()
                dayOffset += 1
            } label: {
                Image(systemName: "chevron.right")
                    .frame(width: 36, height: 36)
            }
            .accessibilityLabel("Next day")
        }
        .overlay {
            if dayOffset != 0 {
                Button("Today") {
                    Haptics.tap()
                    withAnimation { dayOffset = 0 }
                }
                .font(.caption.weight(.semibold))
                .buttonStyle(.bordered)
                .offset(y: 34)
            }
        }
        .padding(.bottom, dayOffset != 0 ? 28 : 0)
    }

    private var timesList: some View {
        let times = settings.times(on: displayedDate)
        let formatter = settings.timeFormatter()
        let next = dayOffset == 0 ? nextPrayer(after: .now) : nil

        return VStack(spacing: 0) {
            ForEach(Prayer.allCases) { prayer in
                let isNext = next?.prayer == prayer && Calendar.current.isDate(next?.date ?? .distantPast, inSameDayAs: displayedDate)
                HStack(spacing: 14) {
                    Image(systemName: prayer.symbol)
                        .font(.body)
                        .foregroundStyle(isNext ? MihrabTheme.gold : Color.secondary)
                        .frame(width: 28)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(prayer.displayName)
                            .font(.body.weight(isNext ? .semibold : .regular))
                        Text(prayer.arabicName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if let t = times.time(for: prayer) {
                        Text(formatter.string(from: t))
                            .font(.body.monospacedDigit().weight(isNext ? .semibold : .regular))
                            .foregroundStyle(isNext ? MihrabTheme.gold : .primary)
                    } else {
                        Text("—")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(isNext ? MihrabTheme.gold.opacity(0.10) : Color.clear)
                .accessibilityElement(children: .combine)
                if prayer != .isha {
                    Divider().padding(.leading, 58)
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var methodFootnote: some View {
        Text("\(settings.method.displayName) · \(settings.hanafiAsr ? "Hanafi" : "Standard") Asr · computed on this device")
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
    }
}

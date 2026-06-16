import SwiftUI

/// Highlights for the selected location now. Also the app's accessible textual path.
struct TonightView: View {
    @Bindable var sky: SkyViewModel
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @State private var showLocationPicker = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("Tonight")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showLocationPicker = true
                    } label: {
                        Image(systemName: "location.circle")
                    }
                    .accessibilityLabel("Change location")
                }
            }
            .sheet(isPresented: $showLocationPicker) {
                LocationsView()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch sky.state {
        case .idle, .loading:
            LoadingView()
        case .failed(let message):
            ErrorStateView(message: message) {
                Task { await sky.refresh(settings: settings, isPro: isPro) }
            }
        case .loaded(let snap):
            loaded(snap)
        }
    }

    private func loaded(_ snap: SkySnapshot) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                locationBar(snap)
                skyConditionsCard(snap)
                moonCard(snap)
                planetsCard(snap)
                bestObjectsCard(snap)
            }
            .padding(16)
        }
        .scrollIndicators(.hidden)
        .refreshable {
            await sky.refresh(settings: settings, isPro: isPro)
        }
    }

    private func locationBar(_ snap: SkySnapshot) -> some View {
        Button {
            showLocationPicker = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(snap.context.name)
                        .font(Theme.rounded(16, .semibold))
                        .foregroundStyle(Theme.ink)
                    Text(timeLabel(snap))
                        .font(.caption)
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(Theme.inkFaint)
            }
            .padding(14)
            .cardSurface()
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Location \(snap.context.name). \(timeLabel(snap)). Tap to change.")
    }

    private func skyConditionsCard(_ snap: SkySnapshot) -> some View {
        let tw = snap.twilight
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Sky conditions", systemImage: tw.currentStage.symbol)
            HStack(spacing: 12) {
                Image(systemName: tw.currentStage.symbol)
                    .font(.system(size: 30))
                    .foregroundStyle(Theme.gold)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text(tw.currentStage.rawValue)
                        .font(Theme.rounded(18, .semibold))
                        .foregroundStyle(Theme.ink)
                    Text(tw.currentStage.detail)
                        .font(.footnote)
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Divider().overlay(Theme.hairline)
            HStack {
                twilightTime("Sunrise", tw.sunrise, snap.context.timeZone)
                twilightTime("Sunset", tw.sunset, snap.context.timeZone)
                twilightTime("Dark", tw.astronomicalDusk, snap.context.timeZone)
            }
        }
        .padding(16)
        .cardSurface()
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func moonCard(_ snap: SkySnapshot) -> some View {
        if let moon = snap.planets.first(where: { $0.body == .moon }) {
            NavigationLink {
                ObjectDetailView(object: moon, context: snap.context)
            } label: {
                HStack(spacing: 14) {
                    MoonGlyph(illumination: snap.moonPhase.illumination, waxing: snap.moonPhase.isWaxing, size: 52)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(snap.moonPhase.name.rawValue)
                            .font(Theme.rounded(18, .semibold))
                            .foregroundStyle(Theme.ink)
                        Text("\(snap.moonPhase.illuminationPercent)% illuminated")
                            .font(.footnote)
                            .foregroundStyle(Theme.inkSoft)
                        Text(moon.isAboveHorizon ? "Up now • \(moon.horizontal.compass16)" : "Below the horizon")
                            .font(.caption)
                            .foregroundStyle(moon.isAboveHorizon ? Theme.good : Theme.inkFaint)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption).foregroundStyle(Theme.inkFaint)
                }
                .padding(16)
                .cardSurface()
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Moon. \(snap.moonPhase.name.rawValue), \(snap.moonPhase.illuminationPercent) percent illuminated.")
        }
    }

    private func planetsCard(_ snap: SkySnapshot) -> some View {
        let up = snap.planetsUp
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Planets up now", systemImage: "circle.fill")
            if up.isEmpty {
                Text("No planets are above the horizon right now. Check back later, or use the sky map to plan ahead.")
                    .font(.footnote)
                    .foregroundStyle(Theme.inkSoft)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(up) { p in
                    NavigationLink {
                        ObjectDetailView(object: p, context: snap.context)
                    } label: {
                        objectRow(p)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .cardSurface()
    }

    private func bestObjectsCard(_ snap: SkySnapshot) -> some View {
        let best = Array(snap.bestUpNow.prefix(8))
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Best objects up now", systemImage: "star.fill")
            if best.isEmpty {
                Text("Nothing notable is above the horizon at the moment.")
                    .font(.footnote)
                    .foregroundStyle(Theme.inkSoft)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(best) { o in
                    NavigationLink {
                        ObjectDetailView(object: o, context: snap.context)
                    } label: {
                        objectRow(o)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .cardSurface()
    }

    private func objectRow(_ o: SkyObject) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(o.tint.opacity(0.2)).frame(width: 34, height: 34)
                Image(systemName: o.kind.symbol).font(.caption).foregroundStyle(o.tint)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(o.name).font(Theme.rounded(15, .semibold)).foregroundStyle(Theme.ink)
                Text("\(o.horizontal.compass16) • \(Fmt.altitude(o.horizontal.altitude))")
                    .font(.caption).foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            Text(Fmt.mag(o.magnitude)).font(.caption2).foregroundStyle(Theme.inkFaint)
            Image(systemName: "chevron.right").font(.caption2).foregroundStyle(Theme.inkFaint)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(o.name), \(o.directionPhrase), \(Fmt.mag(o.magnitude))")
    }

    private func twilightTime(_ title: String, _ date: Date?, _ tz: TimeZone) -> some View {
        VStack(spacing: 4) {
            Text(Fmt.time(date, timeZone: tz)).font(Theme.rounded(16, .semibold)).foregroundStyle(Theme.ink)
            Text(title).font(.caption2).foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) \(Fmt.time(date, timeZone: tz))")
    }

    private func timeLabel(_ snap: SkySnapshot) -> String {
        if settings.timeMode == .custom {
            return "Custom time • " + Fmt.dateTime(snap.context.date, timeZone: snap.context.timeZone)
        }
        return "Now • " + Fmt.dateTime(snap.context.date, timeZone: snap.context.timeZone)
    }
}

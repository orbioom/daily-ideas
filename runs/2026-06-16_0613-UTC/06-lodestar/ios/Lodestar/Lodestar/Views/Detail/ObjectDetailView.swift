import SwiftUI
import SwiftData

/// Full detail for a sky object — reachable from Map, Search and Tonight.
struct ObjectDetailView: View {
    let object: SkyObject
    let context: ObserverContext

    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var modelContext
    @Query private var favorites: [FavoriteObject]

    @State private var events: RiseSetEvent?
    @State private var computingEvents = true
    @State private var showLogSheet = false
    @State private var toast: String?

    private var isFavorite: Bool {
        favorites.contains { $0.identifier == object.id }
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 18) {
                    header
                    positionCard
                    riseSetCard
                    aboutCard
                    actions
                }
                .padding(16)
            }
            .scrollIndicators(.hidden)

            if let toast {
                VStack {
                    Spacer()
                    SuccessToast(text: toast)
                        .padding(.bottom, 24)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationTitle(object.name)
        .navigationBarTitleDisplayMode(.inline)
        .task { await computeEvents() }
        .sheet(isPresented: $showLogSheet) {
            LogObservationSheet(prefilledObject: object.name, locationName: context.name)
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(object.tint.opacity(0.18))
                    .frame(width: 92, height: 92)
                Image(systemName: object.kind.symbol)
                    .font(.system(size: 40))
                    .foregroundStyle(object.tint)
                    .accessibilityHidden(true)
            }
            Text(object.name)
                .font(Theme.rounded(26, .bold))
                .foregroundStyle(Theme.ink)
            HStack(spacing: 8) {
                Pill(text: object.kind.rawValue, color: Theme.accent)
                if !object.constellation.isEmpty {
                    Pill(text: object.constellation, color: Theme.gold)
                }
                if object.kind != .sun {
                    Pill(text: Fmt.mag(object.magnitude), color: Theme.inkSoft)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
        .accessibilityElement(children: .combine)
    }

    private var positionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Right now", systemImage: "location.north.line")
            HStack {
                statBox(title: "Altitude", value: Fmt.altitude(object.horizontal.altitude),
                        tint: object.isAboveHorizon ? Theme.good : Theme.inkSoft)
                statBox(title: "Direction", value: object.horizontal.compass16, tint: Theme.accent)
                statBox(title: "Azimuth", value: Fmt.deg(object.horizontal.azimuth), tint: Theme.inkSoft)
            }
            Text(object.isAboveHorizon
                 ? "Visible — \(object.directionPhrase)."
                 : "Currently below the horizon at \(context.name).")
                .font(.footnote)
                .foregroundStyle(Theme.inkSoft)
        }
        .padding(16)
        .cardSurface()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Position. \(object.directionPhrase). Azimuth \(Int(object.horizontal.azimuth)) degrees.")
    }

    private var riseSetCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Rise, transit & set", systemImage: "arrow.up.arrow.down")
            if computingEvents {
                HStack { ProgressView().tint(Theme.accent); Text("Computing times…").font(.footnote).foregroundStyle(Theme.inkSoft) }
            } else if let e = events {
                if e.alwaysUp {
                    Text("Above the horizon all day (circumpolar).")
                        .font(.callout).foregroundStyle(Theme.good)
                } else if e.alwaysDown {
                    Text("Below the horizon all day.")
                        .font(.callout).foregroundStyle(Theme.inkSoft)
                } else {
                    HStack {
                        timeBox("Rise", e.rise, "sunrise")
                        timeBox("Transit", e.transit, "arrow.up.to.line")
                        timeBox("Set", e.set, "sunset")
                    }
                }
            } else {
                Text("Rise and set times are available for the Sun, Moon and planets.")
                    .font(.footnote).foregroundStyle(Theme.inkSoft)
            }
        }
        .padding(16)
        .cardSurface()
    }

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "About", systemImage: "text.alignleft")
            Text(object.summary)
                .font(.callout)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .cardSurface()
    }

    private var actions: some View {
        VStack(spacing: 10) {
            Button {
                toggleFavorite()
            } label: {
                Label(isFavorite ? "Remove from favourites" : "Add to favourites",
                      systemImage: isFavorite ? "star.fill" : "star")
                    .font(Theme.rounded(16, .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(RoundedRectangle(cornerRadius: Theme.cornerSmall)
                        .fill(isFavorite ? Theme.gold.opacity(0.18) : Theme.accent.opacity(0.15)))
                    .foregroundStyle(isFavorite ? Theme.gold : Theme.accent)
            }
            Button {
                showLogSheet = true
            } label: {
                Label("Log an observation", systemImage: "book.closed")
                    .font(Theme.rounded(16, .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(RoundedRectangle(cornerRadius: Theme.cornerSmall)
                        .strokeBorder(Theme.hairline, lineWidth: 1))
                    .foregroundStyle(Theme.ink)
            }
        }
    }

    private func statBox(title: String, value: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            Text(value).font(Theme.rounded(19, .bold)).foregroundStyle(tint)
            Text(title).font(.caption2).foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
    }

    private func timeBox(_ title: String, _ date: Date?, _ symbol: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: symbol).font(.callout).foregroundStyle(Theme.accent).accessibilityHidden(true)
            Text(Fmt.time(date, timeZone: context.timeZone)).font(Theme.rounded(16, .semibold)).foregroundStyle(Theme.ink)
            Text(title).font(.caption2).foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) \(Fmt.time(date, timeZone: context.timeZone))")
    }

    private func computeEvents() async {
        computingEvents = true
        guard let body = object.body else {
            computingEvents = false
            return
        }
        let ctx = context
        let result = await Task.detached(priority: .userInitiated) {
            RiseSetEngine.events(for: body, on: ctx.date, latitude: ctx.latitude,
                                 longitude: ctx.longitude, timeZone: ctx.timeZone)
        }.value
        events = result
        computingEvents = false
    }

    private func toggleFavorite() {
        if let existing = favorites.first(where: { $0.identifier == object.id }) {
            modelContext.delete(existing)
            try? modelContext.save()
            Haptics.selection(settings.hapticsEnabled)
            showToast("Removed from favourites")
        } else {
            modelContext.insert(FavoriteObject(identifier: object.id, name: object.name, kindRaw: object.kind.rawValue))
            try? modelContext.save()
            Haptics.success(settings.hapticsEnabled)
            showToast("Added to favourites")
        }
    }

    private func showToast(_ text: String) {
        withAnimation { toast = text }
        Task {
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            withAnimation { toast = nil }
        }
    }
}

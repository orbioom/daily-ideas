import SwiftUI
import SwiftData

/// Wishlist shows: upcoming (with live countdown) and undated bucket-list entries.
/// "Mark as attended" converts a wishlist item into an attended show.
struct BucketListScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query(sort: \Concert.date) private var concerts: [Concert]
    @Query private var allGenres: [Genre]

    @State private var showEditor = false
    @State private var markTarget: Concert?
    @State private var paywallReason: PaywallReason?

    private var wishlist: [Concert] {
        concerts.filter { $0.status == .wishlist }
    }

    private var upcoming: [Concert] {
        wishlist.filter { $0.isUpcoming }.sorted { $0.date < $1.date }
    }

    /// Wishlist with no future date (someday / TBD entries).
    private var someday: [Concert] {
        wishlist.filter { !$0.isUpcoming }.sorted { $0.headliner.localizedCaseInsensitiveCompare($1.headliner) == .orderedAscending }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Theme.bg.ignoresSafeArea()
                content
                addButton
            }
            .navigationTitle("Bucket List")
            .navigationDestination(for: Concert.self) { c in
                ConcertDetailView(concert: c, allGenres: allGenres)
            }
            .sheet(isPresented: $showEditor) {
                ConcertEditorView(concert: nil, allGenres: allGenres)
            }
            .sheet(item: $markTarget) { target in
                MarkAttendedSheet(concert: target)
            }
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
        }
    }

    @ViewBuilder
    private var content: some View {
        if wishlist.isEmpty {
            EmptyStateView(symbol: "star",
                           title: "Nothing on the list yet",
                           message: "Add the artists and shows you're dying to see. Give a date to get a live countdown to the big night.",
                           actionTitle: "Add to bucket list") { presentEditor() }
        } else {
            List {
                if !upcoming.isEmpty {
                    Section {
                        ForEach(upcoming) { c in
                            NavigationLink(value: c) {
                                BucketRow(concert: c, showCountdown: settings.showCountdowns)
                            }
                            .listRowBackground(Theme.bg)
                            .listRowSeparator(.hidden)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) { delete(c) } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                Button { markTarget = c } label: {
                                    Label("Attended", systemImage: "checkmark")
                                }
                                .tint(Theme.good)
                            }
                        }
                    } header: {
                        Text("Upcoming").font(Theme.rounded(13, .bold)).foregroundStyle(Theme.ink).textCase(nil)
                    }
                }

                if !someday.isEmpty {
                    Section {
                        ForEach(someday) { c in
                            NavigationLink(value: c) {
                                BucketRow(concert: c, showCountdown: false)
                            }
                            .listRowBackground(Theme.bg)
                            .listRowSeparator(.hidden)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) { delete(c) } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                Button { markTarget = c } label: {
                                    Label("Attended", systemImage: "checkmark")
                                }
                                .tint(Theme.good)
                            }
                        }
                    } header: {
                        Text("Someday").font(Theme.rounded(13, .bold)).foregroundStyle(Theme.ink).textCase(nil)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }

    private var addButton: some View {
        Button {
            presentEditor()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 58, height: 58)
                .background(Circle().fill(Theme.heroGradient))
                .shadow(color: Theme.accent.opacity(0.4), radius: 10, y: 4)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 20)
        .accessibilityLabel("Add to bucket list")
    }

    private func presentEditor() {
        if !Pro.canAddShow(currentCount: concerts.count, isPro: isPro) {
            paywallReason = .showLimit
            Haptics.warning(enabled: settings.hapticsEnabled)
            return
        }
        Haptics.tap(enabled: settings.hapticsEnabled)
        showEditor = true
    }

    private func delete(_ c: Concert) {
        context.delete(c)
        try? context.save()
        Haptics.tap(enabled: settings.hapticsEnabled)
    }
}

/// A bucket-list row with optional live countdown.
struct BucketRow: View {
    let concert: Concert
    let showCountdown: Bool

    var body: some View {
        HStack(spacing: 12) {
            if showCountdown, concert.isUpcoming {
                TimelineView(.periodic(from: .now, by: 60)) { _ in
                    countdownBadge(days: concert.daysUntil ?? 0)
                }
            } else {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Theme.ticketGradient(seed: concert.colorSeed))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "star.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.white)
                    )
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(concert.headliner)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                Text(subtitle)
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
                    .lineLimit(1)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(Theme.inkFaint)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private func countdownBadge(days: Int) -> some View {
        VStack(spacing: 0) {
            Text("\(days)")
                .font(Theme.rounded(18, .bold))
                .foregroundStyle(.white)
            Text(days == 1 ? "day" : "days")
                .font(Theme.rounded(8, .semibold))
                .foregroundStyle(.white.opacity(0.9))
        }
        .frame(width: 50, height: 50)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.heroGradient))
        .accessibilityHidden(true)
    }

    private var subtitle: String {
        var parts: [String] = []
        if !concert.locationLine.isEmpty { parts.append(concert.locationLine) }
        if concert.isUpcoming {
            parts.append(concert.date.formatted(date: .abbreviated, time: .omitted))
        } else if !concert.tourName.isEmpty {
            parts.append(concert.tourName)
        } else {
            parts.append("No date yet")
        }
        return parts.joined(separator: " · ")
    }

    private var accessibilityText: String {
        var s = concert.headliner + ", " + subtitle
        if showCountdown, concert.isUpcoming, let d = concert.daysUntil {
            s += ", in \(d) \(d == 1 ? "day" : "days")"
        }
        return s
    }
}

/// Sheet to confirm a wishlist show as attended — sets/confirms date and venue,
/// then flips status to attended.
private struct MarkAttendedSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @Bindable var concert: Concert

    @State private var date: Date = .now
    @State private var venueName = ""
    @State private var city = ""
    @State private var rating: Double?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(concert.headliner)
                        .font(Theme.rounded(20, .bold))
                        .foregroundStyle(Theme.ink)
                } footer: {
                    Text("Moving this from your bucket list into your attended history.")
                }
                Section("When & where") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Venue", text: $venueName)
                    TextField("City", text: $city)
                }
                Section("How was it?") {
                    HStack {
                        Text("Rating")
                        Spacer()
                        RatingStarsEditor(rating: $rating, hapticsEnabled: settings.hapticsEnabled, size: 24)
                    }
                }
                Section {
                    Button {
                        confirm()
                    } label: {
                        Text("Mark as attended")
                            .font(Theme.rounded(17, .semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .listRowBackground(Theme.accent)
                    .foregroundStyle(.white)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Mark attended")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
            }
            .onAppear {
                // Prefill from the existing wishlist entry; default date to the planned date if past.
                date = concert.date <= Date() ? concert.date : Date()
                venueName = concert.venueName
                city = concert.city
                rating = concert.rating
            }
        }
    }

    private func confirm() {
        concert.status = .attended
        concert.date = date
        concert.venueName = venueName.trimmingCharacters(in: .whitespacesAndNewlines)
        concert.city = city.trimmingCharacters(in: .whitespacesAndNewlines)
        concert.rating = rating
        try? context.save()
        Haptics.success(enabled: settings.hapticsEnabled)
        dismiss()
    }
}

#Preview("Bucket List") {
    BucketListScreen()
        .environmentObject(AppSettings())
        .modelContainer(PreviewContainer.shared)
}

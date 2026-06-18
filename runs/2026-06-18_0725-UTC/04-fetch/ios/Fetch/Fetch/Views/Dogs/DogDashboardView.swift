import SwiftUI
import SwiftData

struct DogDashboardView: View {
    @Bindable var dog: Dog

    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @Query(sort: \Dog.createdAt) private var dogs: [Dog]
    @Query(sort: \CustomTrick.createdAt) private var customTricks: [CustomTrick]
    @State private var showEditor = false

    private var counts: [TrickStatus: Int] { ProgressEngine.counts(for: dog) }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 18) {
                    profileHeader
                    if !dog.isActive {
                        Button {
                            DogManager.setActive(dog, in: dogs, context: context)
                            Haptics.selection(enabled: settings.hapticsEnabled)
                        } label: {
                            Label("Set as active dog", systemImage: "checkmark.circle")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                    statusBreakdown
                    if !dog.notes.isEmpty { notesCard }
                    recentCard
                    Color.clear.frame(height: 12)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
        .navigationTitle(dog.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { showEditor = true }
            }
        }
        .sheet(isPresented: $showEditor) {
            DogEditorView(dog: dog)
        }
    }

    private var profileHeader: some View {
        Card {
            HStack(spacing: 16) {
                DogAvatar(dog: dog, size: 72)
                VStack(alignment: .leading, spacing: 5) {
                    Text(dog.name)
                        .font(Theme.rounded(22, .bold))
                        .foregroundStyle(Theme.ink)
                    if !dog.breed.isEmpty {
                        Text(dog.breed)
                            .font(Theme.rounded(14))
                            .foregroundStyle(Theme.inkSoft)
                    }
                    HStack(spacing: 8) {
                        if let age = Format.ageString(from: dog.birthdate) {
                            Chip(text: age, systemImage: "birthday.cake.fill", color: Theme.warn)
                        }
                        Chip(text: "\(ProgressEngine.trainingStreak(for: dog))d streak", systemImage: "flame.fill", color: Theme.bad)
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var statusBreakdown: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Training breakdown", systemImage: "chart.pie.fill")
                HStack(spacing: 10) {
                    ProgressRing(
                        fraction: ProgressEngine.masteryFraction(for: dog),
                        size: 76, lineWidth: 9,
                        label: "\(Int(ProgressEngine.masteryFraction(for: dog) * 100))%"
                    )
                    VStack(alignment: .leading, spacing: 8) {
                        breakdownRow(.mastered, color: Theme.good)
                        breakdownRow(.practicing, color: Theme.accent)
                        breakdownRow(.learning, color: Theme.warn)
                    }
                    Spacer(minLength: 0)
                }
                Text("Mastery is measured across all \(TrickCatalog.all.count) catalog tricks.")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
    }

    private func breakdownRow(_ status: TrickStatus, color: Color) -> some View {
        HStack(spacing: 8) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(status.rawValue)
                .font(Theme.rounded(14, .medium))
                .foregroundStyle(Theme.ink)
            Spacer()
            Text("\(counts[status] ?? 0)")
                .font(Theme.rounded(15, .bold))
                .foregroundStyle(Theme.ink)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(status.rawValue): \(counts[status] ?? 0)")
    }

    private var notesCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "Notes", systemImage: "note.text")
                Text(dog.notes)
                    .font(Theme.rounded(15))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var recentCard: some View {
        let recent = dog.sessions.sorted { $0.date > $1.date }.prefix(6)
        return VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Recent sessions", systemImage: "clock.arrow.circlepath")
            if recent.isEmpty {
                Card {
                    EmptyStateView(
                        systemImage: "timer",
                        title: "No sessions yet",
                        message: "Practice sessions will appear here."
                    )
                }
            } else {
                ForEach(Array(recent)) { session in
                    SessionRow(session: session, custom: customTricks)
                }
            }
        }
    }
}

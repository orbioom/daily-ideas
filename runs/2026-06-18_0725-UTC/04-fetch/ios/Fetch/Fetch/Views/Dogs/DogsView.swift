import SwiftUI
import SwiftData

struct DogsView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query(sort: \Dog.createdAt) private var dogs: [Dog]

    @State private var showEditor = false
    @State private var editingDog: Dog?
    @State private var showPaywall = false

    private var atFreeLimit: Bool { !isPro && dogs.count >= Pro.freeDogLimit }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                Group {
                    if dogs.isEmpty {
                        EmptyStateView(
                            systemImage: "pawprint.circle",
                            title: "No dogs yet",
                            message: "Add your first dog to start tracking training and progress.",
                            actionTitle: "Add a dog"
                        ) { addDog() }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 14) {
                                ForEach(dogs) { dog in
                                    NavigationLink {
                                        DogDashboardView(dog: dog)
                                    } label: {
                                        DogListCard(dog: dog)
                                    }
                                    .buttonStyle(.plain)
                                }
                                addButton
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                            .padding(.bottom, 28)
                        }
                    }
                }
            }
            .navigationTitle("Dogs")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { addDog() } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add a dog")
                }
            }
            .sheet(isPresented: $showEditor) {
                DogEditorView(dog: editingDog)
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private var addButton: some View {
        Button { addDog() } label: {
            HStack(spacing: 10) {
                Image(systemName: atFreeLimit ? "lock.fill" : "plus.circle.fill")
                    .font(.system(size: 18, weight: .bold))
                Text(atFreeLimit ? "Unlock more dogs with Pro" : "Add another dog")
                    .font(Theme.rounded(16, .semibold))
            }
            .foregroundStyle(atFreeLimit ? Theme.warn : Theme.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                    .foregroundStyle((atFreeLimit ? Theme.warn : Theme.accent).opacity(0.5))
            )
        }
    }

    private func addDog() {
        if atFreeLimit {
            showPaywall = true
            return
        }
        editingDog = nil
        showEditor = true
    }
}

struct DogListCard: View {
    let dog: Dog

    private var mastered: Int { ProgressEngine.masteredCount(for: dog) }
    private var streak: Int { ProgressEngine.trainingStreak(for: dog) }

    var body: some View {
        Card {
            HStack(spacing: 14) {
                DogAvatar(dog: dog, size: 60)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(dog.name)
                            .font(Theme.rounded(18, .bold))
                            .foregroundStyle(Theme.ink)
                        if dog.isActive {
                            Chip(text: "Active", systemImage: "checkmark", color: Theme.good)
                        }
                    }
                    if !dog.breed.isEmpty || Format.ageString(from: dog.birthdate) != nil {
                        Text([dog.breed, Format.ageString(from: dog.birthdate)].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " \u{2022} "))
                            .font(Theme.rounded(13))
                            .foregroundStyle(Theme.inkSoft)
                    }
                    HStack(spacing: 10) {
                        Label("\(mastered) mastered", systemImage: "checkmark.seal.fill")
                        Label("\(streak)d streak", systemImage: "flame.fill")
                    }
                    .font(Theme.rounded(12, .medium))
                    .foregroundStyle(Theme.inkSoft)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(dog.name), \(mastered) tricks mastered, \(streak) day streak")
    }
}

import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("sessionSize") private var sessionSize = 10
    @AppStorage("showPinyin") private var showPinyin = true

    @Environment(\.modelContext) private var modelContext
    @Query private var reviews: [CardReview]
    @Query private var sessions: [StudySession]

    @State private var showResetConfirmation = false

    private let sessionSizeOptions = [5, 10, 20]

    // App version from bundle
    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(v) (\(b))"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ShuTheme.darkNavy.ignoresSafeArea()

                List {
                    // MARK: Study Preferences
                    Section {
                        // Session size picker
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Cards per Session")
                                .font(ShuTheme.labelFont(size: 15))
                                .foregroundStyle(ShuTheme.primaryText)

                            Picker("Session Size", selection: $sessionSize) {
                                ForEach(sessionSizeOptions, id: \.self) { size in
                                    Text("\(size)").tag(size)
                                }
                            }
                            .pickerStyle(.segmented)
                            .tint(ShuTheme.gold)
                        }
                        .listRowBackground(ShuTheme.cardBg)
                        .padding(.vertical, 4)

                        // Show pinyin toggle
                        Toggle(isOn: $showPinyin) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Show Pinyin Hints")
                                    .font(ShuTheme.labelFont(size: 15))
                                    .foregroundStyle(ShuTheme.primaryText)
                                Text("Display romanization on flashcard front")
                                    .font(.system(size: 12, design: .rounded))
                                    .foregroundStyle(ShuTheme.subtleText)
                            }
                        }
                        .tint(ShuTheme.gold)
                        .listRowBackground(ShuTheme.cardBg)
                    } header: {
                        sectionHeader("Study Preferences")
                    }

                    // MARK: Progress
                    Section {
                        HStack {
                            settingsIcon(systemName: "book.closed.fill", color: Color(red: 0.35, green: 0.70, blue: 0.96))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Cards with data")
                                    .font(ShuTheme.labelFont(size: 15))
                                    .foregroundStyle(ShuTheme.primaryText)
                                Text("\(reviews.filter { $0.repetitions > 0 }.count) of \(reviews.count) started")
                                    .font(.system(size: 12, design: .rounded))
                                    .foregroundStyle(ShuTheme.subtleText)
                            }
                            Spacer()
                        }
                        .listRowBackground(ShuTheme.cardBg)

                        HStack {
                            settingsIcon(systemName: "calendar.badge.checkmark", color: ShuTheme.correctGreen)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Study sessions")
                                    .font(ShuTheme.labelFont(size: 15))
                                    .foregroundStyle(ShuTheme.primaryText)
                                Text("\(sessions.count) total sessions completed")
                                    .font(.system(size: 12, design: .rounded))
                                    .foregroundStyle(ShuTheme.subtleText)
                            }
                            Spacer()
                        }
                        .listRowBackground(ShuTheme.cardBg)

                        Button(role: .destructive) {
                            showResetConfirmation = true
                        } label: {
                            HStack {
                                settingsIcon(systemName: "trash.fill", color: ShuTheme.wrongRed)
                                Text("Reset All Progress")
                                    .font(ShuTheme.labelFont(size: 15))
                                    .foregroundStyle(ShuTheme.wrongRed)
                                Spacer()
                            }
                        }
                        .listRowBackground(ShuTheme.cardBg)
                    } header: {
                        sectionHeader("Progress")
                    }

                    // MARK: About
                    Section {
                        HStack {
                            settingsIcon(systemName: "info.circle.fill", color: ShuTheme.gold)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Shu · 书")
                                    .font(ShuTheme.labelFont(size: 15))
                                    .foregroundStyle(ShuTheme.primaryText)
                                Text(appVersion)
                                    .font(.system(size: 12, design: .rounded))
                                    .foregroundStyle(ShuTheme.subtleText)
                            }
                            Spacer()
                        }
                        .listRowBackground(ShuTheme.cardBg)

                        HStack {
                            settingsIcon(systemName: "brain.head.profile", color: ShuTheme.toneColors[1])
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Algorithm")
                                    .font(ShuTheme.labelFont(size: 15))
                                    .foregroundStyle(ShuTheme.primaryText)
                                Text("SM-2 Spaced Repetition")
                                    .font(.system(size: 12, design: .rounded))
                                    .foregroundStyle(ShuTheme.subtleText)
                            }
                            Spacer()
                        }
                        .listRowBackground(ShuTheme.cardBg)

                        HStack {
                            settingsIcon(systemName: "books.vertical.fill", color: ShuTheme.toneColors[0])
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Vocabulary")
                                    .font(ShuTheme.labelFont(size: 15))
                                    .foregroundStyle(ShuTheme.primaryText)
                                Text("100 HSK Level 1 words")
                                    .font(.system(size: 12, design: .rounded))
                                    .foregroundStyle(ShuTheme.subtleText)
                            }
                            Spacer()
                        }
                        .listRowBackground(ShuTheme.cardBg)
                    } header: {
                        sectionHeader("About")
                    }
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(ShuTheme.darkNavy, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .confirmationDialog(
                "Reset All Progress?",
                isPresented: $showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset Everything", role: .destructive) {
                    resetAllProgress()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will delete all your card reviews and study sessions. This cannot be undone.")
            }
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(ShuTheme.labelFont(size: 12))
            .foregroundStyle(ShuTheme.subtleText)
            .textCase(.uppercase)
    }

    private func settingsIcon(systemName: String, color: Color) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 16))
            .foregroundStyle(color)
            .frame(width: 32, height: 32)
            .background(color.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 7))
    }

    private func resetAllProgress() {
        for review in reviews {
            modelContext.delete(review)
        }
        for session in sessions {
            modelContext.delete(session)
        }
        try? modelContext.save()
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [CardReview.self, StudySession.self], inMemory: true)
}

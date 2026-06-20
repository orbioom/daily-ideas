import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("dojoUserName") private var userName = ""
    @AppStorage("dojoTrainingGoal") private var trainingGoal = 3
    @AppStorage("dojoCurrentBelt") private var currentBeltRaw = BjjBelt.white.rawValue
    @AppStorage("dojoOnboarded") private var onboarded = true

    @Environment(\.modelContext) private var modelContext
    @Query private var sessions: [TrainingSession]
    @Query private var techniques: [Technique]
    @Query private var beltRecords: [BeltRecord]
    @Query private var competitions: [Competition]

    @State private var showClearDataAlert = false
    @State private var showResetOnboardingAlert = false

    private var currentBelt: BjjBelt {
        BjjBelt(rawValue: currentBeltRaw) ?? .white
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DojoTheme.darkBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        // Profile card
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(DojoTheme.crimson.opacity(0.15))
                                    .frame(width: 72, height: 72)
                                Image(systemName: "figure.martial.arts")
                                    .font(.system(size: 30))
                                    .foregroundColor(DojoTheme.crimson)
                            }

                            VStack(spacing: 6) {
                                Text(userName.isEmpty ? "Athlete" : userName)
                                    .font(.title2.bold())
                                    .foregroundColor(.white)

                                HStack(spacing: 8) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(DojoTheme.beltColor(currentBelt))
                                        .frame(width: 24, height: 8)
                                    Text(currentBelt.rawValue + " Belt")
                                        .font(.subheadline)
                                        .foregroundColor(DojoTheme.subtleText)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .cardStyle()
                        .padding(.horizontal)

                        // Training goal section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("TRAINING GOAL")
                                .font(.caption.bold())
                                .foregroundColor(DojoTheme.subtleText)
                                .padding(.horizontal)

                            VStack(spacing: 0) {
                                HStack {
                                    Image(systemName: "target")
                                        .foregroundColor(DojoTheme.crimson)
                                        .frame(width: 24)
                                    Text("Sessions per Week")
                                        .foregroundColor(.white)
                                    Spacer()
                                    HStack(spacing: 16) {
                                        Button {
                                            if trainingGoal > 1 { trainingGoal -= 1 }
                                        } label: {
                                            Image(systemName: "minus.circle")
                                                .foregroundColor(DojoTheme.subtleText)
                                                .font(.title3)
                                        }

                                        Text("\(trainingGoal)")
                                            .font(.title3.bold())
                                            .foregroundColor(DojoTheme.crimson)
                                            .frame(width: 28, alignment: .center)

                                        Button {
                                            if trainingGoal < 7 { trainingGoal += 1 }
                                        } label: {
                                            Image(systemName: "plus.circle")
                                                .foregroundColor(DojoTheme.crimson)
                                                .font(.title3)
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)

                                Divider()
                                    .background(DojoTheme.elevatedBg)
                                    .padding(.leading, 56)

                                // This week progress
                                HStack {
                                    Image(systemName: "calendar.badge.clock")
                                        .foregroundColor(DojoTheme.gold)
                                        .frame(width: 24)
                                    Text("This Week")
                                        .foregroundColor(.white)
                                    Spacer()
                                    let thisWeek = BeltEngine.sessionsThisWeek(sessions)
                                    Text("\(thisWeek) / \(trainingGoal) sessions")
                                        .font(.subheadline)
                                        .foregroundColor(thisWeek >= trainingGoal ? .green : DojoTheme.subtleText)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                            }
                            .cardStyle()
                            .padding(.horizontal)
                        }

                        // Stats overview
                        VStack(alignment: .leading, spacing: 8) {
                            Text("YOUR STATS")
                                .font(.caption.bold())
                                .foregroundColor(DojoTheme.subtleText)
                                .padding(.horizontal)

                            VStack(spacing: 0) {
                                SettingsStatRow(
                                    icon: "figure.martial.arts",
                                    label: "Total Sessions",
                                    value: "\(sessions.count)",
                                    color: DojoTheme.crimson
                                )
                                Divider().background(DojoTheme.elevatedBg).padding(.leading, 56)
                                SettingsStatRow(
                                    icon: "clock.fill",
                                    label: "Hours on Mat",
                                    value: "\(BeltEngine.totalHours(sessions))h",
                                    color: DojoTheme.gold
                                )
                                Divider().background(DojoTheme.elevatedBg).padding(.leading, 56)
                                SettingsStatRow(
                                    icon: "book.fill",
                                    label: "Techniques",
                                    value: "\(techniques.count)",
                                    color: .blue
                                )
                                Divider().background(DojoTheme.elevatedBg).padding(.leading, 56)
                                SettingsStatRow(
                                    icon: "trophy.fill",
                                    label: "Competitions",
                                    value: "\(competitions.count)",
                                    color: DojoTheme.gold
                                )
                                Divider().background(DojoTheme.elevatedBg).padding(.leading, 56)
                                SettingsStatRow(
                                    icon: "flame.fill",
                                    label: "Current Streak",
                                    value: "\(BeltEngine.streakDays(sessions)) days",
                                    color: .orange
                                )
                            }
                            .cardStyle()
                            .padding(.horizontal)
                        }

                        // App info
                        VStack(alignment: .leading, spacing: 8) {
                            Text("APP INFO")
                                .font(.caption.bold())
                                .foregroundColor(DojoTheme.subtleText)
                                .padding(.horizontal)

                            VStack(spacing: 0) {
                                SettingsInfoRow(
                                    icon: "info.circle.fill",
                                    label: "Version",
                                    value: "1.0",
                                    color: .blue
                                )
                                Divider().background(DojoTheme.elevatedBg).padding(.leading, 56)
                                SettingsInfoRow(
                                    icon: "ant.fill",
                                    label: "Built for",
                                    value: "BJJ Athletes",
                                    color: DojoTheme.crimson
                                )
                                Divider().background(DojoTheme.elevatedBg).padding(.leading, 56)
                                SettingsInfoRow(
                                    icon: "heart.fill",
                                    label: "Philosophy",
                                    value: "Oss 🤙",
                                    color: .pink
                                )
                            }
                            .cardStyle()
                            .padding(.horizontal)
                        }

                        // Danger zone
                        VStack(alignment: .leading, spacing: 8) {
                            Text("DATA")
                                .font(.caption.bold())
                                .foregroundColor(DojoTheme.subtleText)
                                .padding(.horizontal)

                            VStack(spacing: 12) {
                                Button {
                                    showClearDataAlert = true
                                } label: {
                                    HStack {
                                        Image(systemName: "trash.fill")
                                            .foregroundColor(DojoTheme.crimson)
                                            .frame(width: 24)
                                        Text("Clear All Data")
                                            .foregroundColor(DojoTheme.crimson)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(DojoTheme.subtleText)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .cardStyle()
                                }
                                .padding(.horizontal)
                            }
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(DojoTheme.darkBg, for: .navigationBar)
            .confirmationDialog(
                "Clear All Data",
                isPresented: $showClearDataAlert,
                titleVisibility: .visible
            ) {
                Button("Delete All Sessions, Techniques & Competitions", role: .destructive) {
                    clearAllData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all your training sessions, techniques, belt records, and competitions. This cannot be undone.")
            }
        }
        .tint(DojoTheme.crimson)
    }

    private func clearAllData() {
        for session in sessions { modelContext.delete(session) }
        for technique in techniques { modelContext.delete(technique) }
        for record in beltRecords { modelContext.delete(record) }
        for competition in competitions { modelContext.delete(competition) }
        try? modelContext.save()
    }
}

// MARK: - Settings Row Components

struct SettingsStatRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
                .padding(.trailing, 8)
            Text(label)
                .foregroundColor(.white)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(DojoTheme.subtleText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

struct SettingsInfoRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
                .padding(.trailing, 8)
            Text(label)
                .foregroundColor(.white)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundColor(DojoTheme.subtleText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [TrainingSession.self, Technique.self, BeltRecord.self, Competition.self], inMemory: true)
}

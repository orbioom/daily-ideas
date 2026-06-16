import SwiftUI
import SwiftData
import UIKit

/// The calm SOS home: a large reassuring primary action plus quick tiles.
struct HomeView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.modelContext) private var context

    @Query private var episodes: [PanicEpisode]

    @AppStorage(PrefKey.emergencyContactName) private var contactName = ""
    @AppStorage(PrefKey.emergencyContactPhone) private var contactPhone = ""
    @AppStorage(PrefKey.showCrisisLine) private var showCrisisLine = true
    @AppStorage(PrefKey.defaultBreathingPattern) private var defaultPatternRaw = BreathPattern.calm.rawValue

    @State private var showBreathe = false
    @State private var showGrounding = false
    @State private var showReassurance = false
    @State private var showSettings = false
    @State private var showLogMoment = false
    @State private var showSafetyPlan = false
    @State private var noContactAlert = false

    private var stats: StatsEngine { StatsEngine(episodes: episodes) }

    var body: some View {
        NavigationStack {
            ZStack {
                HavenBackground()
                ScrollView {
                    VStack(spacing: 22) {
                        greeting
                        sosButton
                        quickTiles
                        if showCrisisLine { crisisRow }
                    }
                    .padding(20)
                    .padding(.bottom, 12)
                }
            }
            .navigationTitle("Haven")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .fullScreenCover(isPresented: $showBreathe) {
                BreatheView(initialPattern: BreathPattern(rawValue: defaultPatternRaw) ?? .calm)
            }
            .fullScreenCover(isPresented: $showGrounding) {
                GroundingView()
            }
            .sheet(isPresented: $showReassurance) {
                ReassuranceDeckView()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showLogMoment) {
                LogMomentView(episode: nil)
            }
            .sheet(isPresented: $showSafetyPlan) {
                NavigationStack { SafetyPlanView() }
            }
            .alert("No safe person yet", isPresented: $noContactAlert) {
                Button("Add in Settings") { showSettings = true }
                Button("Not now", role: .cancel) { }
            } message: {
                Text("You can add someone to reach quickly from Settings, anytime.")
            }
        }
    }

    // MARK: Greeting / streak

    private var greeting: some View {
        VStack(spacing: 6) {
            Text(greetingTitle)
                .font(.title2.weight(.semibold))
                .foregroundStyle(HavenTheme.primaryText(scheme))
                .multilineTextAlignment(.center)
            Text(streakLine)
                .font(.subheadline)
                .foregroundStyle(HavenTheme.secondaryText(scheme))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(greetingTitle). \(streakLine)")
    }

    private var greetingTitle: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "You're not alone tonight"
        }
    }

    private var streakLine: String {
        guard let days = stats.daysSinceLast else {
            return "Whenever a hard moment comes, Haven is right here."
        }
        switch days {
        case 0: return "Today was hard. You showed up, and that matters."
        case 1: return "1 day since your last hard moment. Gently does it."
        default: return "\(days) days since your last hard moment."
        }
    }

    // MARK: SOS

    private var sosButton: some View {
        Button {
            tapHaptic()
            showBreathe = true
        } label: {
            VStack(spacing: 10) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 34, weight: .medium))
                    .accessibilityHidden(true)
                Text("I'm having a hard time")
                    .font(.title2.weight(.bold))
                Text("Start a calming breath now")
                    .font(.subheadline)
                    .opacity(0.95)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 30)
            .background(HavenTheme.sosGradient)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.cornerLarge, style: .continuous))
            .shadow(color: HavenTheme.accent.opacity(0.35), radius: 18, y: 8)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Start SOS. I'm having a hard time.")
        .accessibilityHint("Opens a calming breathing exercise")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: Quick tiles

    private var quickTiles: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
            QuickTile(title: "Breathe", subtitle: "Guided slow breathing", systemImage: "wind") {
                showBreathe = true
            }
            QuickTile(title: "Grounding", subtitle: "5-4-3-2-1 senses", systemImage: "leaf") {
                showGrounding = true
            }
            QuickTile(title: "Reassurance", subtitle: "Calm reminders", systemImage: "quote.bubble") {
                showReassurance = true
            }
            QuickTile(title: "Call my person", subtitle: callSubtitle, systemImage: "phone.fill") {
                callPerson()
            }
            QuickTile(title: "Log a moment", subtitle: "Note how you felt", systemImage: "square.and.pencil") {
                showLogMoment = true
            }
            QuickTile(title: "Safety plan", subtitle: "Your reminders to stay safe", systemImage: "list.bullet.clipboard") {
                showSafetyPlan = true
            }
        }
    }

    private var callSubtitle: String {
        contactName.isEmpty ? "Add a safe person" : "Call \(contactName)"
    }

    private func callPerson() {
        guard let url = PhoneURL.make(from: contactPhone) else {
            noContactAlert = true
            return
        }
        UIApplication.shared.open(url)
    }

    // MARK: Crisis row

    private var crisisRow: some View {
        HavenCard(padding: 14) {
            HStack(spacing: 12) {
                Image(systemName: "lifepreserver")
                    .foregroundStyle(HavenTheme.accentDeep)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("In crisis right now?")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(HavenTheme.primaryText(scheme))
                    Text("Call or text 988 (US), or your local emergency line.")
                        .font(.caption)
                        .foregroundStyle(HavenTheme.secondaryText(scheme))
                }
                Spacer()
                Button("Call 988") {
                    if let url = PhoneURL.make(from: CrisisInfo.dial) {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(HavenTheme.accentDeep)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens your phone dialler for the 988 crisis line")
    }

    // MARK: Haptics

    private func tapHaptic() {
        if hapticsAllowed { Haptics.soft() }
    }

    @AppStorage(PrefKey.hapticsEnabled) private var hapticsEnabled = true
    private var hapticsAllowed: Bool { hapticsEnabled }
}

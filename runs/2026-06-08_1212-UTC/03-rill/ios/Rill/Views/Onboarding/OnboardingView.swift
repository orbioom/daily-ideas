import SwiftUI
import SwiftData

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("weightKg") private var weightKg = 70.0
    @AppStorage("bodyProfile") private var bodyProfileRaw = BodyProfile.other.rawValue
    @AppStorage("activityLevel") private var activityRaw = ActivityLevel.moderate.rawValue
    @AppStorage("climate") private var climateRaw = Climate.temperate.rawValue
    @AppStorage("volumeUnit") private var unitRaw = VolumeUnit.ml.rawValue
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var page = 0
    @State private var seedSample = true
    @State private var wave = false

    private var unit: VolumeUnit { VolumeUnit(rawValue: unitRaw) ?? .ml }
    private var goal: Double {
        HydrationEngine().recommendedGoalML(
            weightKg: weightKg,
            profile: BodyProfile(rawValue: bodyProfileRaw) ?? .other,
            activity: ActivityLevel(rawValue: activityRaw) ?? .moderate,
            climate: Climate(rawValue: climateRaw) ?? .temperate)
    }

    var body: some View {
        ZStack {
            Brand.pageBackground
            VStack(spacing: 0) {
                if page < 2 { intro } else { profileSetup }
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) { wave = true }
        }
    }

    private var intro: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 24) {
                ZStack {
                    Circle().fill(.ultraThinMaterial)
                        .frame(width: 150, height: 150)
                        .overlay(Circle().strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: 1))
                    Image(systemName: page == 0 ? "drop.fill" : "bell.badge.fill")
                        .font(.system(size: 54, weight: .light))
                        .foregroundStyle(Color.accentColor)
                        .scaleEffect(wave && !reduceMotion ? 1.06 : 1)
                        .accessibilityHidden(true)
                }
                VStack(spacing: 12) {
                    Text(page == 0 ? "Hydration, honestly" : "Gentle, simple reminders")
                        .font(.title.weight(.bold)).foregroundStyle(Brand.text)
                        .multilineTextAlignment(.center)
                    Text(page == 0
                         ? "Rill counts what you actually drink — coffee and a beer don't hydrate like water, and Rill knows the difference."
                         : "Pick one interval and Rill nudges you, calmly. No ads, no pop-ups, no guilt. Everything stays on your device.")
                        .font(.body).foregroundStyle(Brand.text2)
                        .multilineTextAlignment(.center).padding(.horizontal, 32)
                }
            }
            Spacer()
            Button("Continue") {
                Haptics.tap()
                withAnimation(Brand.ease()) { page += 1 }
            }
            .buttonStyle(InkButtonStyle())
            .padding(.horizontal, 24).padding(.bottom, 32)
        }
    }

    private var profileSetup: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Your daily goal").font(.title2.weight(.bold)).foregroundStyle(Brand.text)
                        Text("A few details set a smart target. You can change all of this later.")
                            .font(.subheadline).foregroundStyle(Brand.text2)
                    }

                    goalPreview

                    VStack(alignment: .leading, spacing: 8) {
                        Eyebrow(text: "Units")
                        Picker("Units", selection: $unitRaw) {
                            Text("ml").tag(VolumeUnit.ml.rawValue)
                            Text("oz").tag(VolumeUnit.floz.rawValue)
                        }.pickerStyle(.segmented)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Eyebrow(text: "Weight — \(Int(weightKg)) kg")
                        Slider(value: $weightKg, in: 35...160, step: 1)
                            .accessibilityValue("\(Int(weightKg)) kilograms")
                    }

                    pickerRow("Body", selection: $bodyProfileRaw, options: BodyProfile.allCases.map { ($0.rawValue, $0.label) })
                    pickerRow("Activity", selection: $activityRaw, options: ActivityLevel.allCases.map { ($0.rawValue, $0.label) })
                    pickerRow("Climate", selection: $climateRaw, options: Climate.allCases.map { ($0.rawValue, $0.label) })

                    Toggle(isOn: $seedSample) {
                        Text("Add a few days of example logs").font(.subheadline).foregroundStyle(Brand.text2)
                    }.tint(Color.accentColor)
                }
                .padding()
            }
            Button("Start") {
                Haptics.success()
                UserDefaults.standard.set(true, forKey: "useSmartGoal")
                if seedSample { SeedData.seedSampleLogs(context) }
                withAnimation(Brand.ease()) { hasOnboarded = true }
            }
            .buttonStyle(InkButtonStyle())
            .padding(.horizontal, 24).padding(.bottom, 32)
        }
    }

    private var goalPreview: some View {
        VStack(spacing: 4) {
            Text(Units.headline(goal, as: unit))
                .font(.system(size: 40, design: .rounded).weight(.bold))
                .foregroundStyle(Color.accentColor)
            Text("recommended per day")
                .font(.caption).foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity)
        .glassCard()
    }

    private func pickerRow(_ title: String, selection: Binding<String>, options: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Eyebrow(text: title)
            Picker(title, selection: selection) {
                ForEach(options, id: \.0) { Text($0.1).tag($0.0) }
            }.pickerStyle(.segmented)
        }
    }
}

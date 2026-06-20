import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Query private var settingsQuery: [CanopySettings]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var currentPage: Int = 0
    @State private var weeklyGoalKg: Double = 92.0
    @State private var goalText: String = "92"

    private var settings: CanopySettings {
        if let s = settingsQuery.first { return s }
        let s = CanopySettings()
        modelContext.insert(s)
        return s
    }

    var body: some View {
        TabView(selection: $currentPage) {
            welcomePage.tag(0)
            categoriesPage.tag(1)
            goalPage.tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .animation(reduceMotion ? nil : .easeInOut, value: currentPage)
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Page 1: Welcome

    private var welcomePage: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(.canopyGreen.opacity(0.12))
                        .frame(width: 140, height: 140)
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.canopyGreen)
                }
                .accessibilityHidden(true)

                VStack(spacing: 12) {
                    Text("Welcome to Canopy")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("Track your footprint.\nLighten your impact.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: 16) {
                    featureBullet(icon: "lock.fill", color: .canopyGreen, text: "Fully private — no account, no cloud")
                    featureBullet(icon: "wifi.slash", color: Color(hex: "4A90D9"), text: "Works completely offline")
                    featureBullet(icon: "leaf.fill", color: Color(hex: "E8821A"), text: "28 activities, science-backed CO₂e factors")
                }
                .padding(.horizontal, 8)
            }
            .padding(.horizontal, 32)

            Spacer()

            nextButton(title: "Get Started") {
                withAnimation(reduceMotion ? nil : .easeInOut) {
                    currentPage = 1
                }
            }
            .padding(.bottom, 60)
        }
    }

    private func featureBullet(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(color)
            }
            .accessibilityHidden(true)

            Text(text)
                .font(.body)
                .foregroundStyle(.primary)
        }
    }

    // MARK: - Page 2: Categories

    private var categoriesPage: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                VStack(spacing: 10) {
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.canopyLight)
                        .accessibilityHidden(true)

                    Text("5 Emission Categories")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("Log activities across the areas that make up your personal carbon footprint.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }

                VStack(spacing: 14) {
                    ForEach(EmissionCategory.allCases, id: \.self) { category in
                        categoryRow(category)
                    }
                }
                .padding(.horizontal, 8)
            }
            .padding(.horizontal, 24)

            Spacer()

            nextButton(title: "Set Your Goal") {
                withAnimation(reduceMotion ? nil : .easeInOut) {
                    currentPage = 2
                }
            }
            .padding(.bottom, 60)
        }
    }

    private func categoryRow(_ category: EmissionCategory) -> some View {
        HStack(spacing: 14) {
            CategoryIcon(category: category, size: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(category.rawValue)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text(categorySubtitle(for: category))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(category.rawValue): \(categorySubtitle(for: category))")
    }

    private func categorySubtitle(for category: EmissionCategory) -> String {
        switch category {
        case .transport: return "Car, flights, train, bus, cycling"
        case .food: return "Meat, dairy, vegetables, coffee"
        case .energy: return "Electricity, gas, heating oil, solar"
        case .shopping: return "Clothing, electronics, furniture"
        case .waste: return "Landfill, recycled, composted"
        }
    }

    // MARK: - Page 3: Goal

    private var goalPage: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                VStack(spacing: 10) {
                    Image(systemName: "target")
                        .font(.system(size: 48))
                        .foregroundStyle(.canopyLight)
                        .accessibilityHidden(true)

                    Text("Set Your Weekly Goal")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("How much CO₂e do you want to emit per week? You can always change this later.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }

                VStack(spacing: 20) {
                    // Goal display
                    VStack(spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(String(format: "%.0f", weeklyGoalKg))
                                .font(.system(size: 56, weight: .bold, design: .rounded))
                                .foregroundStyle(.canopyGreen)
                            Text("kg / week")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityLabel("Weekly goal: \(Int(weeklyGoalKg)) kilograms per week")

                        Text(goalContextLabel)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Slider(value: $weeklyGoalKg, in: 10...300, step: 5)
                        .tint(.canopyGreen)
                        .padding(.horizontal)
                        .onChange(of: weeklyGoalKg) { _, value in
                            goalText = String(Int(value))
                        }
                        .accessibilityLabel("Weekly goal slider")
                        .accessibilityValue("\(Int(weeklyGoalKg)) kilograms per week")

                    // Preset buttons
                    HStack(spacing: 12) {
                        onboardingPresetButton(label: "Ambitious\n96 kg", value: 96.2,
                            description: "Paris-aligned")
                        onboardingPresetButton(label: "Moderate\n150 kg", value: 150,
                            description: "Below world avg")
                        onboardingPresetButton(label: "Starting\n192 kg", value: 192.3,
                            description: "World average")
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            Button(action: completeOnboarding) {
                HStack {
                    Spacer()
                    Text("Start Tracking")
                        .font(.body)
                        .fontWeight(.semibold)
                    Image(systemName: "arrow.right")
                    Spacer()
                }
                .foregroundStyle(.white)
                .padding(.vertical, 18)
                .background(.canopyGreen, in: RoundedRectangle(cornerRadius: CanopyTheme.cornerRadius))
                .padding(.horizontal, 24)
            }
            .accessibilityLabel("Start tracking with weekly goal of \(Int(weeklyGoalKg)) kilograms")
            .padding(.bottom, 60)
        }
    }

    private var goalContextLabel: String {
        switch weeklyGoalKg {
        case ..<70:
            return "Very ambitious — below Paris target"
        case 70..<110:
            return "Paris-aligned target"
        case 110..<160:
            return "Well below world average"
        case 160..<200:
            return "Near world average"
        default:
            return "Above world average"
        }
    }

    private func onboardingPresetButton(label: String, value: Double, description: String) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                weeklyGoalKg = value
            }
        } label: {
            VStack(spacing: 2) {
                Text(label)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                Text(description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                abs(weeklyGoalKg - value) < 5
                    ? Color.canopyGreen.opacity(0.15)
                    : Color(.secondarySystemBackground),
                in: RoundedRectangle(cornerRadius: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        abs(weeklyGoalKg - value) < 5 ? Color.canopyGreen : Color.clear,
                        lineWidth: 1.5
                    )
            )
        }
        .accessibilityLabel("Set goal to \(description): \(Int(value)) kilograms per week")
    }

    // MARK: - Helpers

    private func nextButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Spacer()
                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
                Image(systemName: "arrow.right")
                Spacer()
            }
            .foregroundStyle(.white)
            .padding(.vertical, 18)
            .background(.canopyGreen, in: RoundedRectangle(cornerRadius: CanopyTheme.cornerRadius))
            .padding(.horizontal, 24)
        }
        .accessibilityLabel(title)
    }

    private func completeOnboarding() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        settings.weeklyGoalKg = weeklyGoalKg
        settings.hasCompletedOnboarding = true
    }
}

#Preview {
    OnboardingView()
        .modelContainer(for: [EmissionEntry.self, CanopySettings.self], inMemory: true)
}

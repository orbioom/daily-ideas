import SwiftUI

struct OnboardingPage: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let body: String
}

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    // Profile collected during onboarding.
    @State private var sex: BiologicalSex = .male
    @State private var unit: UnitSystem = .metric
    @State private var heightText = "175"

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "ruler.fill",
            title: "Track every measurement",
            body: "Log weight, body-fat %, and tape sites across your whole body — all private and on your device."
        ),
        OnboardingPage(
            icon: "chart.xyaxis.line",
            title: "See real trends",
            body: "Smooth charts and computed metrics like Navy body-fat, BMI, waist-to-hip and FFMI show where you're actually heading."
        ),
        OnboardingPage(
            icon: "target",
            title: "Reach your goals",
            body: "Set targets, watch progress fill, and stay motivated without ads or a subscription."
        )
    ]

    private var totalPages: Int { pages.count + 1 }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, p in
                        infoPage(p).tag(index)
                    }
                    profilePage.tag(pages.count)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(reduceMotion ? .none : .easeInOut, value: page)

                pageDots
                    .padding(.vertical, 18)

                controls
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
            }
        }
    }

    private func infoPage(_ p: OnboardingPage) -> some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                Circle().fill(Theme.accent.opacity(0.14)).frame(width: 150, height: 150)
                Image(systemName: p.icon)
                    .font(.system(size: 64, weight: .semibold))
                    .foregroundStyle(Theme.accent)
            }
            .accessibilityHidden(true)
            Text(p.title)
                .font(Theme.rounded(28, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(p.body)
                .font(.body)
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
            Spacer()
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }

    private var profilePage: some View {
        ScrollView {
            VStack(spacing: 22) {
                ZStack {
                    Circle().fill(Theme.accent.opacity(0.14)).frame(width: 110, height: 110)
                    Image(systemName: "person.text.rectangle.fill")
                        .font(.system(size: 46, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                }
                .accessibilityHidden(true)
                .padding(.top, 24)

                Text("A few quick details")
                    .font(Theme.rounded(24, .bold))
                    .foregroundStyle(Theme.ink)
                Text("Used for unit display and the Navy body-fat formula. You can change these anytime in Settings.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                VStack(alignment: .leading, spacing: 18) {
                    pickerRow(title: "Units") {
                        Picker("Units", selection: $unit) {
                            ForEach(UnitSystem.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented)
                    }
                    pickerRow(title: "Biological sex") {
                        Picker("Biological sex", selection: $sex) {
                            ForEach(BiologicalSex.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented)
                    }
                    pickerRow(title: "Height (\(unit.lengthUnit))") {
                        TextField("Height", text: $heightText)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                            .accessibilityLabel("Height in \(unit.lengthUnit)")
                    }
                }
                .padding(18)
                .cardSurface()
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 30)
        }
        .onChange(of: unit) { oldValue, newValue in
            // Convert the entered height so it stays sensible when units flip.
            guard oldValue != newValue, let v = Double(heightText) else { return }
            let converted: Double
            if newValue == .imperial {
                converted = v / Units.cmPerInch
            } else {
                converted = v * Units.cmPerInch
            }
            heightText = Units.number(converted, digits: 1)
        }
    }

    private func pickerRow<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(Theme.rounded(15, .semibold))
                .foregroundStyle(Theme.ink)
            content()
        }
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { i in
                Capsule()
                    .fill(i == page ? Theme.accent : Theme.hairline)
                    .frame(width: i == page ? 22 : 8, height: 8)
                    .animation(reduceMotion ? .none : .easeInOut, value: page)
            }
        }
        .accessibilityHidden(true)
    }

    private var controls: some View {
        HStack {
            if page < pages.count {
                Button("Skip") { finish() }
                    .font(Theme.rounded(16, .medium))
                    .foregroundStyle(Theme.inkSoft)
                Spacer()
                Button {
                    Haptics.selection(enabled: settings.hapticsEnabled)
                    withAnimation(reduceMotion ? .none : .easeInOut) { page += 1 }
                } label: {
                    primaryLabel("Next")
                }
            } else {
                Button {
                    finish()
                } label: {
                    primaryLabel("Get started")
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func primaryLabel(_ text: String) -> some View {
        Text(text)
            .font(Theme.rounded(17, .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 30)
            .padding(.vertical, 14)
            .frame(maxWidth: page < pages.count ? nil : .infinity)
            .background(Theme.accent, in: Capsule())
    }

    private func finish() {
        // Persist the collected profile.
        settings.unitSystem = unit
        settings.biologicalSex = sex
        if let v = Double(heightText) {
            settings.heightCm = unit == .metric ? v : v * Units.cmPerInch
        }
        Haptics.success(enabled: settings.hapticsEnabled)
        hasOnboarded = true
    }
}

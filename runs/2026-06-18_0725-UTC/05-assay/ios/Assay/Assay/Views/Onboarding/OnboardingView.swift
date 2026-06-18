import SwiftUI

/// Multi-page onboarding. Explains the value, collects biological sex and unit
/// preferences (which drive range selection), then sets `hasOnboarded`.
struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var page = 0
    @State private var chosenSex: BiologicalSex = .unspecified
    @State private var glucoseUnit: GlucoseUnit = .mgdl
    @State private var cholUnit: CholesterolUnit = .mgdl

    private let lastPage = 3

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    welcome.tag(0)
                    explain.tag(1)
                    profile.tag(2)
                    finish.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(reduceMotion ? nil : .easeInOut, value: page)

                controls
            }
            .padding()
        }
    }

    // MARK: - Pages

    private var welcome: some View {
        pageScaffold(
            icon: "drop.fill",
            title: "Welcome to Assay",
            body: "Your private lab-results journal. Log any blood panel, see every marker scored against reference and optimal ranges, and watch your trends over time.",
            extra: AnyView(disclaimerNote)
        )
    }

    private var explain: some View {
        pageScaffold(
            icon: "chart.xyaxis.line",
            title: "Track what matters",
            body: "Works with any lab — Quest, Labcorp, InsideTracker, your doctor. Everything stays on your device. Export a clean report whenever you need to share.",
            extra: AnyView(featureBullets)
        )
    }

    private var profile: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                headline(icon: "person.fill", title: "A little about you", subtitle: "These set the correct reference ranges. You can change them later in Settings.")

                VStack(alignment: .leading, spacing: 10) {
                    Text("Biological sex (for ranges)")
                        .font(Theme.rounded(15, .semibold))
                        .foregroundStyle(Theme.ink)
                    Picker("Biological sex", selection: $chosenSex) {
                        ForEach(BiologicalSex.allCases) { s in Text(s.rawValue).tag(s) }
                    }
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Glucose units")
                        .font(Theme.rounded(15, .semibold))
                        .foregroundStyle(Theme.ink)
                    Picker("Glucose units", selection: $glucoseUnit) {
                        ForEach(GlucoseUnit.allCases) { u in Text(u.rawValue).tag(u) }
                    }
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Cholesterol units")
                        .font(Theme.rounded(15, .semibold))
                        .foregroundStyle(Theme.ink)
                    Picker("Cholesterol units", selection: $cholUnit) {
                        ForEach(CholesterolUnit.allCases) { u in Text(u.rawValue).tag(u) }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .padding(4)
        }
    }

    private var finish: some View {
        pageScaffold(
            icon: "checkmark.seal.fill",
            title: "You're all set",
            body: "We've added sample panels so you can explore right away. Replace them with your own results any time from the Log tab.",
            extra: AnyView(disclaimerNote)
        )
    }

    // MARK: - Reusable bits

    private func headline(icon: String, title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                Circle().fill(Theme.accentSoft).frame(width: 70, height: 70)
                Image(systemName: icon)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(Theme.accent)
            }
            .accessibilityHidden(true)
            Text(title)
                .font(Theme.rounded(28, .bold))
                .foregroundStyle(Theme.ink)
            Text(subtitle)
                .font(.body)
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func pageScaffold(icon: String, title: String, body: String, extra: AnyView?) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                headline(icon: icon, title: title, subtitle: body)
                if let extra { extra }
                Spacer(minLength: 0)
            }
            .padding(4)
        }
    }

    private var featureBullets: some View {
        VStack(alignment: .leading, spacing: 12) {
            bullet("list.bullet.rectangle.fill", "36+ biomarkers across 10 categories")
            bullet("waveform.path.ecg", "Optimal vs. standard range scoring")
            bullet("square.and.arrow.up", "Doctor-ready CSV & text export")
            bullet("lock.fill", "100% on-device — nothing leaves your phone")
        }
        .padding(.top, 6)
    }

    private func bullet(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 26)
                .accessibilityHidden(true)
            Text(text)
                .font(.callout)
                .foregroundStyle(Theme.ink)
        }
    }

    private var disclaimerNote: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(Theme.inkSoft)
                .accessibilityHidden(true)
            Text("Assay is for personal tracking and education only. It is not medical advice and does not diagnose or treat any condition. Always consult a clinician.")
                .font(.footnote)
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(Theme.surfaceAlt)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.top, 8)
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                ForEach(0...lastPage, id: \.self) { i in
                    Capsule()
                        .fill(i == page ? Theme.accent : Theme.hairline)
                        .frame(width: i == page ? 22 : 8, height: 8)
                        .animation(reduceMotion ? nil : .easeInOut, value: page)
                }
            }
            .accessibilityHidden(true)

            Button {
                if page < lastPage {
                    withAnimation(reduceMotion ? nil : .easeInOut) { page += 1 }
                } else {
                    complete()
                }
            } label: {
                Text(page < lastPage ? "Continue" : "Start using Assay")
                    .font(Theme.rounded(17, .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Theme.accent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            if page < lastPage {
                Button("Skip") { complete() }
                    .font(.callout)
                    .foregroundStyle(Theme.inkSoft)
            }
        }
    }

    private func complete() {
        settings.biologicalSex = chosenSex
        settings.glucoseUnit = glucoseUnit
        settings.cholesterolUnit = cholUnit
        Haptics.success(enabled: settings.hapticsEnabled)
        hasOnboarded = true
    }
}

import SwiftUI
import SwiftData

struct HomeView: View {
    @EnvironmentObject private var settings: AppSettings
    @Query(sort: \HearingTest.date, order: .reverse) private var tests: [HearingTest]
    @State private var showingTest = false

    private var latest: HearingTest? { tests.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    header

                    if let latest {
                        lastResultCard(latest)
                    } else {
                        Card {
                            EmptyStateView(
                                icon: "ear.badge.checkmark",
                                title: "No screening yet",
                                message: "Pop in your headphones, find a quiet spot, and run your first hearing check. It takes a couple of minutes.",
                                ctaTitle: "Start Hearing Check",
                                ctaAction: { showingTest = true }
                            )
                        }
                    }

                    if latest != nil {
                        PrimaryButton(title: "Start Hearing Check", systemImage: "play.fill") {
                            showingTest = true
                        }
                    }

                    setupCard
                    DisclaimerBanner()
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 28)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Hark")
            .fullScreenCover(isPresented: $showingTest) {
                TestRunnerView()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greeting)
                .font(Theme.rounded(15, .medium))
                .foregroundStyle(Theme.inkSoft)
            Text("Your hearing, tracked")
                .font(Theme.rounded(24, .bold))
                .foregroundStyle(Theme.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: .now)
        switch h {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private func lastResultCard(_ test: HearingTest) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    SectionLabel(text: "Last result")
                    Spacer()
                    Text(test.date, format: .dateTime.month().day().year())
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                }

                AudiogramChart(
                    leftThresholds: test.thresholdMap(for: .left),
                    rightThresholds: test.thresholdMap(for: .right),
                    maxLevel: test.maxLevelUsed,
                    mini: true
                )

                EarSummaryRow(analysis: test.analysis(for: .right))
                Divider().background(Theme.hairline)
                EarSummaryRow(analysis: test.analysis(for: .left))

                NavigationLink {
                    ResultsView(test: test)
                } label: {
                    HStack {
                        Text("See full audiogram")
                            .font(Theme.rounded(15, .semibold))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(Theme.rounded(13, .semibold))
                    }
                    .foregroundStyle(Theme.accent)
                }
                .padding(.top, 2)
            }
        }
    }

    private var setupCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                SectionLabel(text: "Before you start")
                setupRow(icon: "headphones", text: "Wear wired or sealed headphones")
                setupRow(icon: "speaker.wave.2", text: "Set your volume to a comfortable mid-level")
                setupRow(icon: "moon.zzz", text: "Find a quiet room with no background noise")
            }
        }
    }

    private func setupRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.accent)
                .frame(width: 24)
                .accessibilityHidden(true)
            Text(text)
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.ink)
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }
}

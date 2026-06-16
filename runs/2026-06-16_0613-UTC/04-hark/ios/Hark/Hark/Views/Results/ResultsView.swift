import SwiftUI
import SwiftData

struct ResultsView: View {
    let test: HearingTest
    @AppStorage("isPro") private var isPro = false
    @State private var showPaywall = false

    private var leftMap: [Int: Double] { test.thresholdMap(for: .left) }
    private var rightMap: [Int: Double] { test.thresholdMap(for: .right) }

    private var asymmetryNote: String {
        AnalysisEngine.asymmetryNote(left: test.ptaLeft, right: test.ptaRight)
    }

    private var exportText: String {
        ResultsExporter.text(for: test)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            SectionLabel(text: "Audiogram")
                            Spacer()
                            Text(test.date, format: .dateTime.month().day().year())
                                .font(Theme.rounded(13))
                                .foregroundStyle(Theme.inkSoft)
                        }
                        AudiogramChart(
                            leftThresholds: leftMap,
                            rightThresholds: rightMap,
                            maxLevel: test.maxLevelUsed
                        )
                        AudiogramLegend()
                    }
                }

                Card {
                    VStack(alignment: .leading, spacing: 14) {
                        SectionLabel(text: "Per ear")
                        EarSummaryRow(analysis: test.analysis(for: .right))
                        Divider().background(Theme.hairline)
                        EarSummaryRow(analysis: test.analysis(for: .left))
                    }
                }

                classificationCard

                asymmetryCard

                if isPro {
                    perEarDetailCard
                    exportRow
                } else {
                    proTeaser
                }

                caveatsCard
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 28)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    private var classificationCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                SectionLabel(text: "What this suggests")
                ForEach(Ear.allCases) { ear in
                    let a = test.analysis(for: ear)
                    if let band = a.band {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Text(ear.rawValue + " ear")
                                    .font(Theme.rounded(15, .semibold))
                                    .foregroundStyle(Theme.ink)
                                BandChip(band: band)
                            }
                            Text(band.plainLanguage)
                                .font(Theme.rounded(14))
                                .foregroundStyle(Theme.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .accessibilityElement(children: .combine)
                        if ear == .right { Divider().background(Theme.hairline) }
                    }
                }
            }
        }
    }

    private var asymmetryCard: some View {
        Card {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Left / right balance")
                        .font(Theme.rounded(15, .semibold))
                        .foregroundStyle(Theme.ink)
                    Text(asymmetryNote)
                        .font(Theme.rounded(14))
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var perEarDetailCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                SectionLabel(text: "Frequency detail")
                ForEach(Audiometry.frequencies, id: \.self) { f in
                    HStack {
                        Text(Audiometry.label(forFrequency: f))
                            .font(Theme.rounded(14, .medium))
                            .foregroundStyle(Theme.ink)
                            .frame(width: 80, alignment: .leading)
                        detailValue(rightMap[f], color: Theme.earRight, ear: "Right")
                        Spacer()
                        detailValue(leftMap[f], color: Theme.earLeft, ear: "Left")
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(detailA11y(freq: f))
                    if f != Audiometry.frequencies.last { Divider().background(Theme.hairline) }
                }
            }
        }
    }

    private func detailValue(_ db: Double?, color: Color, ear: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8).accessibilityHidden(true)
            Text(db.map { "\(Int($0.rounded())) dB" } ?? "—")
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.ink)
        }
    }

    private func detailA11y(freq: Int) -> String {
        let r = rightMap[freq].map { "\(Int($0.rounded())) decibels" } ?? "not measured"
        let l = leftMap[freq].map { "\(Int($0.rounded())) decibels" } ?? "not measured"
        return "\(Audiometry.label(forFrequency: freq)): right \(r), left \(l)."
    }

    private var exportRow: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                SectionLabel(text: "Export")
                Text("Share this audiogram as text or CSV — handy to bring to a professional.")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
                HStack(spacing: 12) {
                    ShareLink(item: exportText,
                              preview: SharePreview("Hark audiogram")) {
                        labelChip(icon: "doc.text", text: "Text")
                    }
                    ShareLink(item: ResultsExporter.csv(for: test),
                              preview: SharePreview("Hark audiogram CSV")) {
                        labelChip(icon: "tablecells", text: "CSV")
                    }
                }
            }
        }
    }

    private func labelChip(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(text)
        }
        .font(Theme.rounded(15, .semibold))
        .foregroundStyle(Theme.accent)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Capsule().fill(Theme.accentSoft))
    }

    private var proTeaser: some View {
        Button { showPaywall = true } label: {
            Card {
                HStack(spacing: 14) {
                    Image(systemName: "lock.fill")
                        .font(Theme.rounded(18, .semibold))
                        .foregroundStyle(Theme.accent)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Unlock per-ear detail & export")
                            .font(Theme.rounded(15, .semibold))
                            .foregroundStyle(Theme.ink)
                        Text("See every frequency and share your audiogram with Hark Pro.")
                            .font(Theme.rounded(13))
                            .foregroundStyle(Theme.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(Theme.inkSoft)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens the Hark Pro upgrade screen.")
    }

    private var caveatsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            DisclaimerBanner()
            Text("Hark estimates relative thresholds and can't replace a calibrated audiogram. For sudden changes, one-sided loss, pain, or ringing that starts abruptly, see a professional.")
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

import SwiftUI
import SwiftData

struct ReportView: View {
    @Query(sort: \FoodLogEntry.date) private var foodLogs: [FoodLogEntry]
    @Query(sort: \SymptomEntry.date) private var symptomLogs: [SymptomEntry]
    @Query(sort: \EliminationPhase.startDate) private var phases: [EliminationPhase]
    @Query private var settings: [NourishSettings]

    @State private var showingShareSheet = false
    @State private var reportText: String = ""

    private var windowHours: Double { settings.first?.windowHoursForCorrelation ?? 24.0 }

    private var triggers: [CorrelationEngine.TriggerResult] {
        CorrelationEngine.topTriggers(
            foodLogs: foodLogs,
            symptomLogs: symptomLogs,
            windowHours: windowHours,
            topN: 5
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                NourishTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: NourishTheme.Spacing.lg) {
                        // Preview card
                        reportPreviewSection

                        // Stats summary
                        statsSummary

                        // Top triggers preview
                        if !triggers.isEmpty {
                            triggersPreview
                        }

                        // Generate button
                        Button(action: generateAndShare) {
                            HStack(spacing: NourishTheme.Spacing.sm) {
                                Image(systemName: "square.and.arrow.up")
                                    .accessibilityHidden(true)
                                Text("Share Report")
                            }
                        }
                        .primaryButton()
                        .padding(.horizontal, NourishTheme.Spacing.md)

                        Text("Generates a plain-text report you can share with your doctor or dietitian.")
                            .font(NourishTheme.Typography.caption)
                            .foregroundColor(NourishTheme.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, NourishTheme.Spacing.md)
                    }
                    .padding(.vertical, NourishTheme.Spacing.md)
                }
            }
            .navigationTitle("Report")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(items: [reportText])
            }
        }
    }

    // MARK: - Sections

    private var reportPreviewSection: some View {
        VStack(alignment: .leading, spacing: NourishTheme.Spacing.md) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .font(.title2)
                    .foregroundColor(NourishTheme.sage)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Nourish Food Sensitivity Report")
                        .font(NourishTheme.Typography.headline)
                        .foregroundColor(NourishTheme.charcoal)
                    Text("Generated \(Date().formatted(date: .abbreviated, time: .shortened))")
                        .font(NourishTheme.Typography.caption)
                        .foregroundColor(NourishTheme.secondaryText)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: NourishTheme.Spacing.xs) {
                ReportLine(icon: "calendar", text: "Date range: \(dateRange)")
                ReportLine(icon: "fork.knife", text: "\(foodLogs.count) food log entries")
                ReportLine(icon: "waveform.path.ecg", text: "\(symptomLogs.count) symptom entries")
                ReportLine(icon: "list.clipboard", text: "\(phases.count) protocol phases")
            }
        }
        .padding(NourishTheme.Spacing.md)
        .nourishCard()
        .padding(.horizontal, NourishTheme.Spacing.md)
    }

    private var statsSummary: some View {
        VStack(alignment: .leading, spacing: NourishTheme.Spacing.sm) {
            Text("Summary")
                .font(NourishTheme.Typography.headline)
                .foregroundColor(NourishTheme.charcoal)
                .padding(.horizontal, NourishTheme.Spacing.md)

            HStack(spacing: NourishTheme.Spacing.sm) {
                ReportStatCard(
                    value: "\(completedPhases.count)",
                    label: "Phases\nCompleted",
                    color: NourishTheme.sage
                )
                ReportStatCard(
                    value: "\(triggers.count)",
                    label: "Suspected\nTriggers",
                    color: triggers.isEmpty ? NourishTheme.sage : NourishTheme.terra
                )
                ReportStatCard(
                    value: "\(uniqueFoodsCount)",
                    label: "Unique\nFoods",
                    color: NourishTheme.sage
                )
            }
            .padding(.horizontal, NourishTheme.Spacing.md)
        }
    }

    private var triggersPreview: some View {
        VStack(alignment: .leading, spacing: NourishTheme.Spacing.sm) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(NourishTheme.terra)
                    .accessibilityHidden(true)
                Text("Top Suspected Triggers")
                    .font(NourishTheme.Typography.headline)
                    .foregroundColor(NourishTheme.charcoal)
            }
            .padding(.horizontal, NourishTheme.Spacing.md)

            VStack(spacing: NourishTheme.Spacing.sm) {
                ForEach(Array(triggers.enumerated()), id: \.element.id) { index, trigger in
                    HStack {
                        Text("#\(index + 1)")
                            .font(NourishTheme.Typography.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(NourishTheme.terra))
                            .accessibilityHidden(true)

                        Text(trigger.food)
                            .font(NourishTheme.Typography.callout)
                            .foregroundColor(NourishTheme.charcoal)

                        Spacer()

                        Text("\(Int(trigger.score * 100))% correlation")
                            .font(NourishTheme.Typography.caption)
                            .foregroundColor(NourishTheme.terra)
                            .fontWeight(.semibold)
                    }
                }
            }
            .padding(NourishTheme.Spacing.md)
            .background(NourishTheme.card)
            .cornerRadius(NourishTheme.CornerRadius.lg)
            .shadow(
                color: NourishTheme.Shadow.card.color,
                radius: NourishTheme.Shadow.card.radius,
                x: NourishTheme.Shadow.card.x,
                y: NourishTheme.Shadow.card.y
            )
            .padding(.horizontal, NourishTheme.Spacing.md)
        }
    }

    // MARK: - Computed

    private var dateRange: String {
        guard let first = foodLogs.first?.date ?? symptomLogs.first?.date else {
            return "No data"
        }
        let last = foodLogs.last?.date ?? symptomLogs.last?.date ?? Date()
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return "\(formatter.string(from: first)) – \(formatter.string(from: last))"
    }

    private var completedPhases: [EliminationPhase] {
        phases.filter { $0.isCompleted }
    }

    private var uniqueFoodsCount: Int {
        Set(foodLogs.map { $0.foodName }).count
    }

    // MARK: - Report Generation

    private func generateAndShare() {
        reportText = buildReportText()
        showingShareSheet = true
    }

    private func buildReportText() -> String {
        var lines: [String] = []

        // Header
        lines.append("NOURISH FOOD SENSITIVITY REPORT")
        lines.append(String(repeating: "=", count: 40))
        lines.append("Generated: \(Date().formatted(date: .long, time: .shortened))")
        lines.append("")

        // Summary
        lines.append("SUMMARY")
        lines.append(String(repeating: "-", count: 20))
        lines.append("Total food log entries: \(foodLogs.count)")
        lines.append("Total symptom entries: \(symptomLogs.count)")
        lines.append("Unique foods logged: \(uniqueFoodsCount)")
        lines.append("Date range: \(dateRange)")
        lines.append("")

        // Protocol phases
        if !phases.isEmpty {
            lines.append("ELIMINATION PROTOCOL")
            lines.append(String(repeating: "-", count: 20))
            for phase in phases {
                let status = phase.isCompleted ? "COMPLETED" : (phase.isActive ? "IN PROGRESS" : "UPCOMING")
                lines.append("[\(status)] \(phase.name)")
                lines.append("  Start: \(phase.startDate.formatted(date: .abbreviated, time: .omitted))")
                if let end = phase.endDate {
                    lines.append("  End: \(end.formatted(date: .abbreviated, time: .omitted))")
                }
                if !phase.foodsToAvoid.isEmpty {
                    lines.append("  Avoided: \(phase.foodsToAvoid.joined(separator: ", "))")
                }
                lines.append("")
            }
        }

        // Top suspected triggers
        if !triggers.isEmpty {
            lines.append("TOP SUSPECTED FOOD TRIGGERS")
            lines.append(String(repeating: "-", count: 20))
            lines.append("(Correlation window: \(Int(windowHours)) hours)")
            lines.append("")
            for (index, trigger) in triggers.enumerated() {
                lines.append("\(index + 1). \(trigger.food)")
                lines.append("   Correlation score: \(Int(trigger.score * 100))% (\(trigger.confidenceLabel) confidence)")
                lines.append("   Symptoms after eating: \(trigger.count) of \(trigger.totalEaten) meals")
                if !trigger.allergenTags.isEmpty {
                    lines.append("   Allergen category: \(trigger.allergenTags.joined(separator: ", "))")
                }
                lines.append("")
            }
        } else {
            lines.append("TOP SUSPECTED FOOD TRIGGERS")
            lines.append(String(repeating: "-", count: 20))
            lines.append("No significant triggers identified yet.")
            lines.append("Continue logging meals and symptoms for more accurate analysis.")
            lines.append("")
        }

        // Most frequent symptoms
        let topSymptoms = CorrelationEngine.mostFrequentSymptoms(symptomLogs: symptomLogs, topN: 8)
        if !topSymptoms.isEmpty {
            lines.append("MOST FREQUENT SYMPTOMS")
            lines.append(String(repeating: "-", count: 20))
            for item in topSymptoms {
                lines.append("- \(item.symptom): \(item.count) occurrence(s)")
            }
            lines.append("")
        }

        // Recent symptom log (last 30 entries)
        if !symptomLogs.isEmpty {
            lines.append("SYMPTOM LOG (Most Recent \(min(30, symptomLogs.count)) Entries)")
            lines.append(String(repeating: "-", count: 20))
            for entry in symptomLogs.suffix(30) {
                let date = entry.date.formatted(date: .abbreviated, time: .shortened)
                lines.append("\(date) | \(entry.symptomName) | Severity: \(entry.severity)/5")
                if !entry.notes.isEmpty {
                    lines.append("  Notes: \(entry.notes)")
                }
            }
            lines.append("")
        }

        // Disclaimer
        lines.append(String(repeating: "=", count: 40))
        lines.append("DISCLAIMER")
        lines.append("This report is generated by the Nourish app for informational purposes only.")
        lines.append("It is not a medical diagnosis. Please consult with a qualified healthcare")
        lines.append("professional before making dietary changes or drawing medical conclusions.")
        lines.append(String(repeating: "=", count: 40))

        return lines.joined(separator: "\n")
    }
}

// MARK: - ReportLine

private struct ReportLine: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: NourishTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(NourishTheme.sage)
                .frame(width: 16)
                .accessibilityHidden(true)
            Text(text)
                .font(NourishTheme.Typography.callout)
                .foregroundColor(NourishTheme.charcoal)
        }
    }
}

// MARK: - ReportStatCard

private struct ReportStatCard: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(NourishTheme.Typography.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(NourishTheme.Typography.caption)
                .foregroundColor(NourishTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(NourishTheme.Spacing.md)
        .nourishCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label.replacingOccurrences(of: "\n", with: " "))")
    }
}

// MARK: - ShareSheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

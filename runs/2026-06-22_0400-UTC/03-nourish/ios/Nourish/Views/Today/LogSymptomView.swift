import SwiftUI
import SwiftData

struct LogSymptomView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedSymptom: SymptomItem? = nil
    @State private var customSymptom: String = ""
    @State private var severity: Int = 3
    @State private var notes: String = ""
    @State private var logDate: Date = Date()
    @State private var selectedCategory: SymptomCategory? = nil
    @State private var useCustom: Bool = false

    @Query private var settings: [NourishSettings]
    private var hapticsEnabled: Bool { settings.first?.hapticsEnabled ?? true }

    private var symptomName: String {
        if useCustom {
            return customSymptom.trimmingCharacters(in: .whitespaces)
        }
        return selectedSymptom?.name ?? ""
    }

    private var canSave: Bool {
        !symptomName.isEmpty && severity > 0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                NourishTheme.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: NourishTheme.Spacing.lg) {
                        // Category filter
                        categoryPicker

                        // Symptom picker
                        symptomPickerSection

                        // Custom input
                        customSymptomSection

                        // Severity
                        severitySection

                        // Date/time
                        dateSection

                        // Notes
                        notesSection

                        // Save button
                        Button(action: save) {
                            Text("Log Symptom")
                        }
                        .primaryButton(isDestructive: false)
                        .disabled(!canSave)
                        .padding(.horizontal, NourishTheme.Spacing.md)
                    }
                    .padding(.vertical, NourishTheme.Spacing.md)
                }
            }
            .navigationTitle("Log Symptom")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(NourishTheme.Colors.sage)
                }
            }
        }
    }

    // MARK: - Sections

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: NourishTheme.Spacing.sm) {
                // "All" chip
                CategoryChip(
                    label: "All",
                    icon: "square.grid.2x2.fill",
                    isSelected: selectedCategory == nil,
                    action: {
                        selectedCategory = nil
                        selectedSymptom = nil
                    }
                )

                ForEach(SymptomCategory.allCases) { cat in
                    CategoryChip(
                        label: cat.rawValue,
                        icon: cat.icon,
                        isSelected: selectedCategory == cat,
                        action: {
                            selectedCategory = cat
                            selectedSymptom = nil
                        }
                    )
                }
            }
            .padding(.horizontal, NourishTheme.Spacing.md)
        }
    }

    private var filteredSymptoms: [SymptomItem] {
        if let cat = selectedCategory {
            return SymptomLibrary.items(in: cat)
        }
        return SymptomLibrary.all
    }

    private var symptomPickerSection: some View {
        VStack(alignment: .leading, spacing: NourishTheme.Spacing.sm) {
            Text("Select Symptom")
                .font(NourishTheme.Typography.subheadline)
                .foregroundColor(NourishTheme.Colors.secondaryText)
                .padding(.horizontal, NourishTheme.Spacing.md)

            FlowLayout(spacing: NourishTheme.Spacing.xs) {
                ForEach(filteredSymptoms) { symptom in
                    Button(action: {
                        selectedSymptom = symptom
                        useCustom = false
                    }) {
                        Text(symptom.name)
                            .font(NourishTheme.Typography.caption)
                            .fontWeight(.medium)
                            .foregroundColor(selectedSymptom?.id == symptom.id ? .white : NourishTheme.Colors.text)
                            .padding(.horizontal, NourishTheme.Spacing.sm)
                            .padding(.vertical, 7)
                            .background(
                                Capsule()
                                    .fill(selectedSymptom?.id == symptom.id ? NourishTheme.Colors.terra : NourishTheme.Colors.cardBackground)
                                    .shadow(color: NourishTheme.Shadow.card.color, radius: 4)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(symptom.name)
                    .accessibilityAddTraits(selectedSymptom?.id == symptom.id ? .isSelected : [])
                }
            }
            .padding(.horizontal, NourishTheme.Spacing.md)
        }
    }

    private var customSymptomSection: some View {
        VStack(alignment: .leading, spacing: NourishTheme.Spacing.sm) {
            Toggle(isOn: $useCustom) {
                Text("Enter custom symptom")
                    .font(NourishTheme.Typography.subheadline)
                    .foregroundColor(NourishTheme.Colors.secondaryText)
            }
            .tint(NourishTheme.Colors.terra)
            .onChange(of: useCustom) { _, newVal in
                if newVal { selectedSymptom = nil }
            }
            .padding(.horizontal, NourishTheme.Spacing.md)

            if useCustom {
                TextField("Describe your symptom...", text: $customSymptom)
                    .font(NourishTheme.Typography.body)
                    .foregroundColor(NourishTheme.Colors.text)
                    .padding(NourishTheme.Spacing.md)
                    .background(NourishTheme.Colors.cardBackground)
                    .cornerRadius(NourishTheme.CornerRadius.md)
                    .shadow(color: NourishTheme.Shadow.card.color, radius: NourishTheme.Shadow.card.radius)
                    .padding(.horizontal, NourishTheme.Spacing.md)
            }
        }
    }

    private var severitySection: some View {
        VStack(alignment: .leading, spacing: NourishTheme.Spacing.sm) {
            SeverityPicker(severity: $severity)
                .padding(NourishTheme.Spacing.md)
                .background(NourishTheme.Colors.cardBackground)
                .cornerRadius(NourishTheme.CornerRadius.md)
                .shadow(color: NourishTheme.Shadow.card.color, radius: NourishTheme.Shadow.card.radius)
                .padding(.horizontal, NourishTheme.Spacing.md)
        }
    }

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: NourishTheme.Spacing.sm) {
            Text("Time")
                .font(NourishTheme.Typography.subheadline)
                .foregroundColor(NourishTheme.Colors.secondaryText)
                .padding(.horizontal, NourishTheme.Spacing.md)

            DatePicker("Log time", selection: $logDate, displayedComponents: [.date, .hourAndMinute])
                .labelsHidden()
                .padding(NourishTheme.Spacing.md)
                .background(NourishTheme.Colors.cardBackground)
                .cornerRadius(NourishTheme.CornerRadius.md)
                .shadow(color: NourishTheme.Shadow.card.color, radius: NourishTheme.Shadow.card.radius)
                .padding(.horizontal, NourishTheme.Spacing.md)
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: NourishTheme.Spacing.sm) {
            Text("Notes (optional)")
                .font(NourishTheme.Typography.subheadline)
                .foregroundColor(NourishTheme.Colors.secondaryText)
                .padding(.horizontal, NourishTheme.Spacing.md)

            TextField("What were you doing, how did it come on...", text: $notes, axis: .vertical)
                .font(NourishTheme.Typography.body)
                .foregroundColor(NourishTheme.Colors.text)
                .lineLimit(3, reservesSpace: true)
                .padding(NourishTheme.Spacing.md)
                .background(NourishTheme.Colors.cardBackground)
                .cornerRadius(NourishTheme.CornerRadius.md)
                .shadow(color: NourishTheme.Shadow.card.color, radius: NourishTheme.Shadow.card.radius)
                .padding(.horizontal, NourishTheme.Spacing.md)
        }
    }

    // MARK: - Actions

    private func save() {
        guard !symptomName.isEmpty, severity > 0 else { return }

        let entry = SymptomEntry(
            date: logDate,
            symptomName: symptomName,
            severity: severity,
            notes: notes.trimmingCharacters(in: .whitespaces)
        )
        modelContext.insert(entry)

        if hapticsEnabled {
            let feedback = UINotificationFeedbackGenerator()
            feedback.notificationOccurred(.warning)
        }

        dismiss()
    }
}

// MARK: - CategoryChip

private struct CategoryChip: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .accessibilityHidden(true)
                Text(label)
                    .font(NourishTheme.Typography.caption)
            }
            .foregroundColor(isSelected ? .white : NourishTheme.Colors.text)
            .padding(.horizontal, NourishTheme.Spacing.sm)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isSelected ? NourishTheme.Colors.terra : NourishTheme.Colors.cardBackground)
                    .shadow(color: NourishTheme.Shadow.card.color, radius: 4)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

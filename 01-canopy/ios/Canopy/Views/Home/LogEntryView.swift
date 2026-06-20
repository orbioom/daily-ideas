import SwiftUI
import SwiftData

struct LogEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Edit mode
    var editingEntry: EmissionEntry?

    // Steps
    @State private var currentStep: Int = 1
    @State private var selectedCategory: EmissionCategory?
    @State private var selectedActivity: Activity?
    @State private var amount: Double = 1.0
    @State private var amountText: String = "1"
    @State private var entryDate: Date = Date()
    @State private var notes: String = ""
    @State private var showDeleteAlert: Bool = false

    private var isEditing: Bool { editingEntry != nil }

    private var livePreviewKg: Double {
        guard let activity = selectedActivity else { return 0 }
        let parsedAmount = Double(amountText) ?? amount
        return EmissionsEngine.co2e(activityKey: activity.id, amount: parsedAmount)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                stepIndicator
                    .padding(.vertical, 16)

                Group {
                    switch currentStep {
                    case 1: categoryStep
                    case 2: activityStep
                    case 3: amountStep
                    default: categoryStep
                    }
                }
                .transition(reduceMotion ? .opacity : .asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: currentStep)
            }
            .navigationTitle(isEditing ? "Edit Entry" : "Log Emission")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityLabel("Cancel logging entry")
                }
                if isEditing {
                    ToolbarItem(placement: .destructiveAction) {
                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            Image(systemName: "trash")
                        }
                        .accessibilityLabel("Delete this entry")
                    }
                }
            }
            .alert("Delete Entry", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) { deleteEntry() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This entry will be permanently removed.")
            }
        }
        .onAppear { prefillIfEditing() }
    }

    // MARK: - Step Indicator

    private var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(1...3, id: \.self) { step in
                Circle()
                    .fill(step <= currentStep ? Color.canopyGreen : Color.secondary.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .accessibilityHidden(true)
                if step < 3 {
                    Rectangle()
                        .fill(step < currentStep ? Color.canopyGreen : Color.secondary.opacity(0.3))
                        .frame(height: 2)
                        .accessibilityHidden(true)
                }
            }
        }
        .padding(.horizontal, 48)
    }

    // MARK: - Step 1: Category

    private var categoryStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Choose a category")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)

                VStack(spacing: 12) {
                    ForEach(EmissionCategory.allCases, id: \.self) { category in
                        categoryPill(category)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }

    private func categoryPill(_ category: EmissionCategory) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            selectedCategory = category
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
                currentStep = 2
            }
        } label: {
            HStack(spacing: 16) {
                CategoryIcon(category: category, size: 48)

                Text(category.rawValue)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(
                selectedCategory == category
                    ? category.swiftUIColor.opacity(0.12)
                    : Color(.secondarySystemBackground),
                in: RoundedRectangle(cornerRadius: CanopyTheme.cornerRadius)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CanopyTheme.cornerRadius)
                    .stroke(
                        selectedCategory == category ? category.swiftUIColor : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .accessibilityLabel(category.rawValue)
        .accessibilityHint("Select \(category.rawValue) as the emission category")
    }

    // MARK: - Step 2: Activity

    private var activityStep: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
                        currentStep = 1
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.body)
                    .foregroundStyle(.canopyGreen)
                }
                .accessibilityLabel("Go back to category selection")
                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom, 8)

            if let category = selectedCategory {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select activity")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)

                    List(EmissionsEngine.activities(in: category)) { activity in
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            selectedActivity = activity
                            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
                                currentStep = 3
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(activity.name)
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Text("\(String(format: activity.kgCO2ePerUnit < 1 ? "%.3f" : "%.1f", activity.kgCO2ePerUnit)) kg/\(activity.unit)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Text(activity.tip)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            .padding(.vertical, 4)
                        }
                        .accessibilityLabel("\(activity.name), \(String(format: "%.3f", activity.kgCO2ePerUnit)) kg CO2 per \(activity.unit)")
                        .accessibilityHint(activity.tip)
                    }
                    .listStyle(.plain)
                }
            }
        }
    }

    // MARK: - Step 3: Amount

    private var amountStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Button {
                        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
                            currentStep = 2
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(.body)
                        .foregroundStyle(.canopyGreen)
                    }
                    .accessibilityLabel("Go back to activity selection")
                    Spacer()
                }

                if let activity = selectedActivity {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How much \(activity.name.lowercased())?")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(activity.tip)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // Amount input
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            TextField("0", text: $amountText)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundStyle(.canopyGreen)
                                .frame(maxWidth: 200)
                                .onChange(of: amountText) { _, newVal in
                                    if let parsed = Double(newVal) {
                                        amount = parsed
                                    }
                                }
                                .accessibilityLabel("Amount in \(activity.unit)")

                            Text(activity.unit)
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }

                        // Live preview
                        Co2Badge(kg: livePreviewKg)
                            .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: livePreviewKg)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: CanopyTheme.cornerRadius))

                    // Date picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Date")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)

                        DatePicker(
                            "Entry date",
                            selection: $entryDate,
                            in: ...Date(),
                            displayedComponents: .date
                        )
                        .labelsHidden()
                        .accessibilityLabel("Select entry date")
                    }

                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes (optional)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)

                        TextEditor(text: $notes)
                            .frame(minHeight: 80)
                            .padding(8)
                            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: CanopyTheme.smallCornerRadius))
                            .accessibilityLabel("Add notes about this entry")
                    }

                    // Save button
                    Button(action: saveEntry) {
                        HStack {
                            Spacer()
                            Text(isEditing ? "Save Changes" : "Log Emission")
                                .font(.body)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .foregroundStyle(.white)
                        .padding(.vertical, 16)
                        .background(.canopyGreen, in: RoundedRectangle(cornerRadius: CanopyTheme.cornerRadius))
                    }
                    .disabled(amountText.isEmpty || Double(amountText) == nil || (Double(amountText) ?? 0) <= 0)
                    .opacity((Double(amountText) ?? 0) > 0 ? 1 : 0.5)
                    .accessibilityLabel(isEditing ? "Save changes to this entry" : "Log this emission entry")
                }
            }
            .padding()
        }
    }

    // MARK: - Actions

    private func saveEntry() {
        guard let activity = selectedActivity,
              let parsedAmount = Double(amountText),
              parsedAmount > 0 else { return }

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        let co2e = EmissionsEngine.co2e(activityKey: activity.id, amount: parsedAmount)

        if let entry = editingEntry {
            entry.category = activity.category
            entry.activityKey = activity.id
            entry.amount = parsedAmount
            entry.co2eKg = co2e
            entry.date = entryDate
            entry.notes = notes
        } else {
            let entry = EmissionEntry(
                date: entryDate,
                category: activity.category,
                activityKey: activity.id,
                amount: parsedAmount,
                co2eKg: co2e,
                notes: notes
            )
            modelContext.insert(entry)
        }

        dismiss()
    }

    private func deleteEntry() {
        guard let entry = editingEntry else { return }
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        modelContext.delete(entry)
        dismiss()
    }

    private func prefillIfEditing() {
        guard let entry = editingEntry else { return }
        selectedCategory = entry.category
        if let activity = EmissionsEngine.activity(for: entry.activityKey) {
            selectedActivity = activity
        }
        amount = entry.amount
        amountText = String(format: "%g", entry.amount)
        entryDate = entry.date
        notes = entry.notes
        currentStep = 3
    }
}

#Preview {
    LogEntryView()
        .modelContainer(for: [EmissionEntry.self, CanopySettings.self], inMemory: true)
}

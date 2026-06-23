import SwiftUI
import SwiftData

/// Multi-step create-trip flow presented as a sheet:
/// 1. Details  2. Activities  3. Generated list preview.
struct TripFormFlow: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var allSettings: [AppSettings]
    @AppStorage("activeTripID") private var activeTripID: String = ""

    @State private var model: TripFormViewModel
    @State private var step = 0

    init() {
        _model = State(initialValue: TripFormViewModel())
    }

    private var settings: AppSettings? { allSettings.first }
    private var hapticsOn: Bool { settings?.hapticsEnabled ?? true }
    private var style: PackingStyle { settings?.packingStyle ?? .normal }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                StepIndicator(current: step, total: 3)
                    .padding(.horizontal, Theme.Space.lg)
                    .padding(.top, Theme.Space.md)

                Group {
                    switch step {
                    case 0: detailsStep
                    case 1: activitiesStep
                    default: previewStep
                    }
                }
            }
            .background(Theme.background)
            .navigationTitle(stepTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                bottomBar
            }
        }
        .onAppear {
            if let s = settings { model.travelerCount = max(1, s.defaultTravelerCount) }
        }
    }

    private var stepTitle: String {
        switch step {
        case 0: return "Trip details"
        case 1: return "Activities"
        default: return "Your packing list"
        }
    }

    // MARK: Steps

    private var detailsStep: some View {
        Form {
            Section("Basics") {
                TextField("Trip name", text: $model.name)
                    .textInputAutocapitalization(.words)
                TextField("Destination", text: $model.destination)
                    .textInputAutocapitalization(.words)
            }
            Section("Dates") {
                DatePicker("Departure", selection: $model.startDate, displayedComponents: .date)
                DatePicker("Return", selection: $model.endDate,
                           in: model.startDate..., displayedComponents: .date)
                HStack {
                    Text("Length")
                    Spacer()
                    Text("\(model.nights) night\(model.nights == 1 ? "" : "s")")
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            Section("Trip type") {
                tripTypeGrid
            }
            Section("Travelers") {
                Stepper(value: $model.travelerCount, in: 1...12) {
                    Label("\(model.travelerCount) traveler\(model.travelerCount == 1 ? "" : "s")",
                          systemImage: "person.2.fill")
                }
            }
            Section("Notes (optional)") {
                TextField("Anything to remember…", text: $model.notes, axis: .vertical)
                    .lineLimit(2...4)
            }
        }
        .scrollContentBackground(.hidden)
    }

    private var tripTypeGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: Theme.Space.sm)],
                  spacing: Theme.Space.sm) {
            ForEach(TripType.allCases) { type in
                Button {
                    model.tripType = type
                    Haptics.selection(enabled: hapticsOn)
                } label: {
                    VStack(spacing: Theme.Space.xs) {
                        Image(systemName: type.symbol)
                            .font(.title3)
                        Text(type.title)
                            .font(.caption.weight(.medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Space.md)
                    .background(model.tripType == type ? type.tint.opacity(0.18) : Theme.surface)
                    .foregroundStyle(model.tripType == type ? type.tint : Theme.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.chip, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.chip, style: .continuous)
                            .strokeBorder(model.tripType == type ? type.tint : Theme.hairline,
                                          lineWidth: model.tripType == type ? 2 : 1)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(model.tripType == type ? [.isSelected] : [])
            }
        }
        .padding(.vertical, Theme.Space.xs)
    }

    private var activitiesStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.lg) {
                Text("Tag what you'll be doing. Each one adds the right gear to your list.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)

                FlowChips(
                    activities: Activity.allCases,
                    selected: model.selectedActivities
                ) { activity in
                    model.toggleActivity(activity)
                    Haptics.selection(enabled: hapticsOn)
                }

                if model.selectedActivities.isEmpty {
                    Text("No activities selected — that's fine, you'll still get the essentials.")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.top, Theme.Space.sm)
                }
            }
            .padding(Theme.Space.lg)
        }
    }

    private var previewStep: some View {
        Group {
            if model.isGenerating {
                LoadingStateView(message: "Tailoring your packing list…")
            } else if model.generatedItems.isEmpty {
                EmptyStateView(
                    symbol: "wand.and.stars",
                    title: "Ready to generate",
                    message: "Tap Generate to build your tailored list."
                )
            } else {
                generatedList
            }
        }
    }

    private var generatedList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.lg) {
                HStack(spacing: Theme.Space.md) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Theme.success)
                        .font(.title2)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(model.generatedItems.count) items ready")
                            .font(.headline)
                        Text(model.generationSummary)
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                .card()

                ForEach(PackCategory.allCases.sorted { $0.sortIndex < $1.sortIndex }) { cat in
                    let items = model.generatedItems.filter { $0.category == cat }
                    if !items.isEmpty {
                        VStack(alignment: .leading, spacing: Theme.Space.sm) {
                            Label(cat.title, systemImage: cat.symbol)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(cat.tint)
                            ForEach(items) { item in
                                HStack {
                                    Text(item.name)
                                        .font(.subheadline)
                                        .foregroundStyle(Theme.textPrimary)
                                    Spacer()
                                    if item.quantity > 1 {
                                        Text("×\(item.quantity)")
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(Theme.textSecondary)
                                            .monospacedDigit()
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .card()
                    }
                }
            }
            .padding(Theme.Space.lg)
        }
    }

    // MARK: Bottom bar

    private var bottomBar: some View {
        VStack(spacing: Theme.Space.sm) {
            if step == 0, let msg = model.validationMessage {
                Text(msg)
                    .font(.footnote)
                    .foregroundStyle(Theme.secondary)
            }
            HStack(spacing: Theme.Space.md) {
                if step > 0 {
                    Button {
                        withAnimation { step -= 1 }
                    } label: {
                        Text("Back")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.Space.md)
                    }
                    .buttonStyle(.bordered)
                    .tint(Theme.primary)
                }
                Button {
                    primaryAction()
                } label: {
                    Text(primaryLabel)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Space.md)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.primary)
                .disabled(primaryDisabled)
            }
        }
        .padding(Theme.Space.lg)
        .background(.bar)
    }

    private var primaryLabel: String {
        switch step {
        case 0: return "Next"
        case 1: return "Generate list"
        default: return "Save trip"
        }
    }

    private var primaryDisabled: Bool {
        if step == 0 { return !model.isValid }
        if step == 2 { return model.isGenerating || model.generatedItems.isEmpty }
        return false
    }

    private func primaryAction() {
        switch step {
        case 0:
            withAnimation { step = 1 }
        case 1:
            withAnimation { step = 2 }
            Task {
                await model.generate(style: style)
                Haptics.notify(.success, enabled: hapticsOn)
            }
        default:
            let trip = model.createTrip(in: context)
            activeTripID = trip.id.uuidString
            Haptics.notify(.success, enabled: hapticsOn)
            dismiss()
        }
    }
}

/// Step progress dots.
private struct StepIndicator: View {
    let current: Int
    let total: Int
    var body: some View {
        HStack(spacing: Theme.Space.sm) {
            ForEach(0..<total, id: \.self) { i in
                Capsule()
                    .fill(i <= current ? Theme.primary : Theme.hairline)
                    .frame(height: 5)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(current + 1) of \(total)")
    }
}

/// Wrapping chip layout for activities.
private struct FlowChips: View {
    let activities: [Activity]
    let selected: Set<Activity>
    let onTap: (Activity) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: Theme.Space.sm)],
                  alignment: .leading, spacing: Theme.Space.sm) {
            ForEach(activities) { activity in
                SelectableChip(
                    title: activity.title,
                    symbol: activity.symbol,
                    isSelected: selected.contains(activity),
                    tint: Theme.primary
                ) {
                    onTap(activity)
                }
            }
        }
    }
}

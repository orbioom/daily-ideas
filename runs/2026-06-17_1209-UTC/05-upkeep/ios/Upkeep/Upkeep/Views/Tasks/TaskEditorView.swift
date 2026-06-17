import SwiftUI
import SwiftData

/// Create or edit a task, with a full cadence editor. `task == nil` means create.
struct TaskEditorView: View {
    let task: MaintenanceTask?
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    @State private var title = ""
    @State private var systemName = SystemCatalog.all.first?.name ?? "General"
    @State private var cadence: CadenceType = .everyNMonths
    @State private var interval = 3
    @State private var season: Season = .spring
    @State private var minutesText = "15"
    @State private var costText = ""
    @State private var priority = 2
    @State private var notes = ""
    @State private var isActive = true
    @State private var hasLastDone = false
    @State private var lastDone = Date()
    @State private var showPaywall = false

    private var isEditing: Bool { task != nil }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("Title", text: $title)
                    Picker("System", selection: $systemName) {
                        ForEach(SystemCatalog.all, id: \.name) { entry in
                            Label(entry.name, systemImage: entry.symbol).tag(entry.name)
                        }
                    }
                    Picker("Priority", selection: $priority) {
                        Text("High").tag(1)
                        Text("Medium").tag(2)
                        Text("Low").tag(3)
                    }
                    .pickerStyle(.segmented)
                }

                Section("How often") {
                    Picker("Cadence", selection: $cadence) {
                        ForEach(CadenceType.allCases) { c in
                            Text(c.label).tag(c)
                        }
                    }
                    if cadence.usesInterval {
                        Stepper(value: $interval, in: 1...60) {
                            Text("Every \(interval) \(unitLabel)")
                        }
                    } else {
                        Picker("Season", selection: $season) {
                            ForEach(Season.allCases) { s in
                                Label(s.label, systemImage: s.symbol).tag(s)
                            }
                        }
                    }
                }

                Section("Last done") {
                    Toggle("Has been done before", isOn: $hasLastDone)
                    if hasLastDone {
                        DatePicker("Last done", selection: $lastDone,
                                   in: ...Date(), displayedComponents: .date)
                    } else {
                        Text("Treated as due now until first completed.")
                            .font(Theme.rounded(13))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }

                Section("Estimates") {
                    HStack {
                        Image(systemName: "clock").foregroundStyle(Theme.inkSoft)
                        TextField("Minutes", text: $minutesText)
                            .keyboardType(.numberPad)
                    }
                    if isPro {
                        HStack {
                            Text(settings.currencySymbol.isEmpty ? "$" : settings.currencySymbol)
                                .foregroundStyle(Theme.inkSoft)
                            TextField("Estimated cost (optional)", text: $costText)
                                .keyboardType(.decimalPad)
                        }
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            HStack {
                                Label("Estimated cost", systemImage: "dollarsign.circle")
                                Spacer()
                                Image(systemName: "lock.fill").foregroundStyle(Theme.inkFaint)
                            }
                        }
                    }
                }

                Section("More") {
                    Toggle("Active", isOn: $isActive)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(1...4)
                }
            }
            .navigationTitle(isEditing ? "Edit task" : "New task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(reason: .costTracking)
            }
            .onAppear(perform: loadIfEditing)
        }
    }

    private var unitLabel: String {
        switch cadence {
        case .everyNDays: return interval == 1 ? "day" : "days"
        case .everyNWeeks: return interval == 1 ? "week" : "weeks"
        case .everyNMonths: return interval == 1 ? "month" : "months"
        case .everyNYears: return interval == 1 ? "year" : "years"
        case .seasonal: return "season"
        }
    }

    private func loadIfEditing() {
        guard let task else { return }
        title = task.title
        systemName = task.systemName
        cadence = task.cadenceType
        interval = task.intervalCount
        if let s = task.season { season = s }
        minutesText = String(task.estimatedMinutes)
        if let cost = task.estimatedCost { costText = String(format: "%.2f", cost) }
        priority = task.priority
        notes = task.notes
        isActive = task.isActive
        if let last = task.lastDone {
            hasLastDone = true
            lastDone = last
        }
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        let minutes = Int(minutesText.trimmingCharacters(in: .whitespaces)) ?? 0
        let cost: Double? = isPro ? parseCost(costText) : (task?.estimatedCost)
        let resolvedSeason: Season? = cadence == .seasonal ? season : nil
        let resolvedLastDone: Date? = hasLastDone ? lastDone : nil

        if let task {
            task.title = trimmedTitle
            task.systemName = systemName
            task.cadenceType = cadence
            task.intervalCount = max(1, interval)
            task.season = resolvedSeason
            task.estimatedMinutes = max(0, minutes)
            task.estimatedCost = cost
            task.priority = priority
            task.notes = notes
            task.isActive = isActive
            task.lastDone = resolvedLastDone
            task.system = systemForName(systemName)
        } else {
            let newTask = MaintenanceTask(title: trimmedTitle,
                                          systemName: systemName,
                                          cadenceType: cadence,
                                          intervalCount: max(1, interval),
                                          season: resolvedSeason,
                                          lastDone: resolvedLastDone,
                                          estimatedMinutes: max(0, minutes),
                                          estimatedCost: cost,
                                          priority: priority,
                                          isActive: isActive,
                                          notes: notes)
            context.insert(newTask)
            newTask.system = systemForName(systemName)
        }
        Haptics.success(settings.hapticsEnabled)
        dismiss()
    }

    private func systemForName(_ name: String) -> HomeSystem? {
        let systems = TaskFactory.ensureSystems(in: context)
        return systems[name]
    }

    private func parseCost(_ text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, let decimal = Decimal(string: trimmed) else { return nil }
        let value = (decimal as NSDecimalNumber).doubleValue
        return value > 0 ? value : nil
    }
}

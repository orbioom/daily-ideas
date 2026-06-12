import SwiftUI
import SwiftData

struct ShiftEditView: View {
    let shift: Shift?
    let preselectedJob: Job?
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Job.createdAt) private var jobs: [Job]

    @State private var jobID: UUID?
    @State private var date = Date()
    @State private var hours = ""
    @State private var cash = ""
    @State private var card = ""
    @State private var tipOut = ""
    @State private var sales = ""
    @State private var notes = ""

    private var isEditing: Bool { shift != nil }
    private var selectableJobs: [Job] { jobs.filter { !$0.isArchived || $0.id == jobID } }
    private var canSave: Bool { parse(hours) > 0 }

    private var livePreview: (net: Double, total: Double, hourly: Double) {
        let h = parse(hours)
        let net = max(parse(cash) + parse(card) - parse(tipOut), 0)
        let wage = h * (jobs.first { $0.id == jobID }?.hourlyWage ?? 0)
        let total = net + wage
        return (net, total, h > 0 ? total / h : 0)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Job", selection: $jobID) {
                        Text("None").tag(UUID?.none)
                        ForEach(selectableJobs) { Text($0.name).tag(UUID?.some($0.id)) }
                    }
                    DatePicker("Date", selection: $date, in: ...Date(), displayedComponents: .date)
                    HStack {
                        Text("Hours worked")
                        Spacer()
                        TextField("0", text: $hours).keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing).frame(maxWidth: 90)
                        Text("h").font(.caption).foregroundStyle(Theme.textSecondary)
                    }
                }
                Section("Tips") {
                    CurrencyField(label: "Cash tips", text: $cash, color: Theme.cash)
                    CurrencyField(label: "Card tips", text: $card, color: Theme.card)
                    CurrencyField(label: "Tip-out (paid out)", text: $tipOut)
                }
                Section {
                    CurrencyField(label: "Sales (optional)", text: $sales)
                } header: {
                    Text("Sales")
                } footer: {
                    Text("Add your total sales to track your tip percentage.")
                }
                Section("Notes") {
                    TextField("Section, weather, events…", text: $notes, axis: .vertical).lineLimit(2...4)
                }
                Section {
                    HStack {
                        Text("Net tips").foregroundStyle(Theme.textSecondary)
                        Spacer()
                        Text(Currency.precise(livePreview.net)).foregroundStyle(Theme.accent).fontWeight(.semibold)
                    }
                    HStack {
                        Text("Take-home this shift").foregroundStyle(Theme.textSecondary)
                        Spacer()
                        Text(Currency.precise(livePreview.total)).foregroundStyle(Theme.textPrimary).fontWeight(.bold)
                    }
                    HStack {
                        Text("Effective hourly").foregroundStyle(Theme.textSecondary)
                        Spacer()
                        Text(livePreview.hourly > 0 ? Currency.string(livePreview.hourly) + "/h" : "—")
                            .foregroundStyle(Theme.accent)
                    }
                } header: {
                    Text("Preview")
                }
            }
            .navigationTitle(isEditing ? "Edit Shift" : "Log Shift")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(!canSave) }
            }
            .onAppear(perform: load)
        }
    }

    private func parse(_ s: String) -> Double {
        Double(s.replacingOccurrences(of: ",", with: ".").filter { "0123456789.".contains($0) }) ?? 0
    }
    private func trimmed(_ d: Double) -> String {
        guard d != 0 else { return "" }
        return d.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(d)) : String(format: "%.2f", d)
    }

    private func load() {
        if let sh = shift {
            jobID = sh.job?.id
            date = sh.date
            hours = trimmed(sh.hoursWorked)
            cash = trimmed(sh.cashTips); card = trimmed(sh.cardTips)
            tipOut = trimmed(sh.tipOut); sales = trimmed(sh.sales); notes = sh.notes
        } else {
            jobID = preselectedJob?.id ?? jobs.first { !$0.isArchived }?.id
        }
    }

    private func save() {
        guard parse(hours) > 0 else { return }
        let targetJob = jobs.first { $0.id == jobID }
        let sh = shift ?? Shift()
        sh.date = date
        sh.hoursWorked = parse(hours)
        sh.cashTips = parse(cash)
        sh.cardTips = parse(card)
        sh.tipOut = parse(tipOut)
        sh.sales = parse(sales)
        sh.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        if shift == nil { context.insert(sh) }
        sh.job = targetJob
        if let targetJob, !(targetJob.shifts.contains { $0.id == sh.id }) {
            targetJob.shifts.append(sh)
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}

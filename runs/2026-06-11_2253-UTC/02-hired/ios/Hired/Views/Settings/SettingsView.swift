import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var scheme
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("staleDays") private var staleDays = 10
    @AppStorage("appearance") private var appearance = "system"
    @Query private var applications: [Application]

    @State private var confirmDelete = false
    @State private var sampleLoaded = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Pipeline") {
                    Stepper(value: $staleDays, in: 5...30) {
                        HStack {
                            Text("Quiet threshold")
                            Spacer()
                            Text("\(staleDays) days")
                                .foregroundStyle(.secondary)
                        }
                    }
                    Text("Applications with no movement for this long appear in “Going quiet” on the Up next tab.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Section("Experience") {
                    Toggle("Haptic feedback", isOn: $hapticsEnabled)
                    Picker("Appearance", selection: $appearance) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                }
                Section("Data") {
                    LabeledContent("Applications", value: "\(applications.count)")
                    Button("Load sample pipeline") { loadSample() }
                        .disabled(sampleLoaded)
                    Button("Delete all data", role: .destructive) { confirmDelete = true }
                        .disabled(applications.isEmpty)
                }
                Section("About") {
                    LabeledContent("Version", value: "1.0")
                    Text("Hired is fully offline. Your job search stays on your phone — no account, no tracking, no upsell mid-application.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background(scheme))
            .navigationTitle("Settings")
            .confirmationDialog("Delete all \(applications.count) applications?",
                                isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete everything", role: .destructive) {
                    for app in applications { context.delete(app) }
                    sampleLoaded = false
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    /// A believable 12-application pipeline exercising every stage and screen.
    private func loadSample() {
        let calendar = Calendar.current
        func daysAgo(_ d: Int) -> Date {
            calendar.date(byAdding: .day, value: -d, to: Date()) ?? Date()
        }
        let specs: [(company: String, role: String, stage: Stage, applied: Int?, excitement: Int,
                     mode: WorkMode, salary: String, history: [(Stage, Int)])] = [
            ("Northwind Labs", "Senior iOS Engineer", .interview, 18, 5, .remote, "$165–190k",
             [(.applied, 18), (.screening, 12), (.interview, 5)]),
            ("Beacon Health", "Mobile Engineer", .screening, 10, 4, .hybrid, "$140–160k",
             [(.applied, 10), (.screening, 3)]),
            ("Foundry AI", "Staff Engineer, Apps", .applied, 6, 5, .remote, "$190–220k",
             [(.applied, 6)]),
            ("Cobalt Systems", "iOS Developer", .applied, 14, 2, .onsite, "",
             [(.applied, 14)]),
            ("Juniper & Co", "Product Engineer", .offer, 30, 4, .hybrid, "$150k + equity",
             [(.applied, 30), (.screening, 24), (.interview, 14), (.offer, 2)]),
            ("Atlas Freight", "Senior Swift Engineer", .rejected, 25, 3, .remote, "",
             [(.applied, 25), (.screening, 20), (.rejected, 9)]),
            ("Quill Media", "Mobile Lead", .ghosted, 40, 3, .remote, "$170k",
             [(.applied, 40), (.screening, 33), (.ghosted, 12)]),
            ("Harbor Bank", "iOS Engineer II", .applied, 3, 3, .onsite, "$135–150k",
             [(.applied, 3)]),
            ("Lumen Fitness", "Founding Mobile Engineer", .interview, 12, 5, .remote, "$160k + 0.5%",
             [(.applied, 12), (.screening, 8), (.interview, 2)]),
            ("Civic Works", "Software Engineer, iOS", .withdrawn, 22, 2, .hybrid, "",
             [(.applied, 22), (.screening, 16), (.withdrawn, 10)]),
            ("Solstice Games", "Gameplay UI Engineer", .wishlist, nil, 4, .remote, "",
             []),
            ("Meridian Travel", "iOS Engineer", .wishlist, nil, 3, .hybrid, "",
             []),
        ]
        for spec in specs {
            let app = Application(company: spec.company, role: spec.role,
                                  location: spec.mode == .onsite ? "New York, NY" : "",
                                  workMode: spec.mode, salaryText: spec.salary,
                                  excitement: spec.excitement,
                                  appliedDate: spec.applied.map(daysAgo),
                                  stage: spec.stage)
            context.insert(app)
            for (stage, ago) in spec.history {
                let event = StageEvent(date: daysAgo(ago), stage: stage)
                event.application = app
                context.insert(event)
            }
        }
        // Interviews + follow-ups on the active threads.
        let descriptor = FetchDescriptor<Application>()
        if let all = try? context.fetch(descriptor) {
            if let northwind = all.first(where: { $0.company == "Northwind Labs" }) {
                let iv = Interview(kind: .technical,
                                   scheduledAt: calendar.date(byAdding: .day, value: 2, to: Date()) ?? Date(),
                                   notes: "Pair programming, bring questions about the widget team")
                iv.application = northwind
                context.insert(iv)
                let person = JobContact(name: "Maya Chen", title: "Recruiter", email: "maya@northwindlabs.example")
                person.application = northwind
                context.insert(person)
            }
            if let lumen = all.first(where: { $0.company == "Lumen Fitness" }) {
                let iv = Interview(kind: .final,
                                   scheduledAt: calendar.date(byAdding: .day, value: 5, to: Date()) ?? Date(),
                                   notes: "With both founders")
                iv.application = lumen
                context.insert(iv)
                let task = FollowUp(title: "Send thank-you note",
                                    dueDate: calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date())
                task.application = lumen
                context.insert(task)
            }
            if let juniper = all.first(where: { $0.company == "Juniper & Co" }) {
                let task = FollowUp(title: "Respond to offer — negotiate base",
                                    dueDate: calendar.date(byAdding: .day, value: 2, to: Date()) ?? Date())
                task.application = juniper
                context.insert(task)
            }
        }
        sampleLoaded = true
        Haptics.success()
    }
}

import SwiftUI
import SwiftData

@Model final class SleepEntry {
    @Attribute(.unique) var id: UUID = UUID()
    var date: Date
    var sleepTime: Date
    var wakeTime: Date
    var quality: Int // 1-5
    var notes: String = ""

    var duration: TimeInterval { wakeTime.timeIntervalSince(sleepTime) }
    var durationHours: Double { duration / 3600 }
}

struct SleepDebtCalculator {
    static let targetHours = 8.0

    static func calculateDebt(entries: [SleepEntry]) -> Double {
        let last7 = entries.filter { Calendar.current.dateComponents([.day], from: $0.date, to: Date()).day ?? 0 < 7 }.sorted { $0.date > $1.date }
        let totalSlept = last7.reduce(0) { $0 + $1.durationHours }
        let targetTotal = targetHours * Double(last7.count)
        return max(0, targetTotal - totalSlept)
    }

    static func suggestBedtime(entries: [SleepEntry]) -> Date {
        let avgOnsetTime = 15.0 // minutes to fall asleep
        let needed = 8.0 // target hours
        let wakeTime = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
        let sleepDuration = needed * 3600 + avgOnsetTime * 60
        return Date(timeIntervalSince1970: wakeTime.timeIntervalSince1970 - sleepDuration)
    }
}

@main
struct SleepDebtAIApp: App {
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding = false

    var modelContainer: ModelContainer = {
        let schema = Schema([SleepEntry.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try! ModelContainer(for: schema, configurations: [config])
    }()

    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                MainView()
            } else {
                OnboardingView(hasSeenOnboarding: $hasSeenOnboarding)
            }
        }
        .modelContainer(modelContainer)
    }
}

struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool

    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            Text("😴").font(.system(size: 80))
            VStack {
                Text("Sleep Debt AI")
                    .font(.title).fontWeight(.bold)
                Text("Learn your sleep patterns and optimize your rest")
                    .font(.body).foregroundColor(.secondary).multilineTextAlignment(.center)
            }
            Spacer()
            Button(action: { hasSeenOnboarding = true }) {
                Text("Get Started").frame(maxWidth: .infinity).padding().background(Color.accentColor).foregroundColor(.white).cornerRadius(8)
            }
        }
        .padding()
    }
}

struct MainView: View {
    @Query(sort: \SleepEntry.date, order: .reverse) var entries: [SleepEntry]
    @State var showAddSleep = false
    @State var selectedDate = Date()

    var sleepDebt: Double { SleepDebtCalculator.calculateDebt(entries: Array(entries)) }
    var suggestedBedtime: Date { SleepDebtCalculator.suggestBedtime(entries: Array(entries)) }

    var body: some View {
        TabView {
            NavigationStack {
                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        Text("Sleep Debt").font(.headline)
                        Text(String(format: "%.1f hours", sleepDebt)).font(.title).fontWeight(.bold).foregroundColor(.accentColor)
                        Text("Last 7 days").font(.caption).foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity).padding().background(Color(.systemBackground)).cornerRadius(8)

                    VStack(spacing: 8) {
                        Text("Suggested Bedtime").font(.headline)
                        Text(suggestedBedtime.formatted(time: .shortened)).font(.title3).fontWeight(.bold)
                        Text("For 8 hours of sleep").font(.caption).foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity).padding().background(Color(.systemBackground)).cornerRadius(8)

                    Spacer()

                    Button(action: { showAddSleep = true }) {
                        Text("Log Sleep").frame(maxWidth: .infinity).padding().background(Color.accentColor).foregroundColor(.white).cornerRadius(8)
                    }
                }
                .padding()
                .navigationTitle("Sleep Tracker")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink(destination: HistoryView()) {
                            Image(systemName: "calendar")
                        }
                    }
                }
            }
            .tabItem { Label("Home", systemImage: "moon.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
        .sheet(isPresented: $showAddSleep) {
            AddSleepView()
        }
    }
}

struct HistoryView: View {
    @Query(sort: \SleepEntry.date, order: .reverse) var entries: [SleepEntry]

    var body: some View {
        List {
            ForEach(entries) { entry in
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.date.formatted(date: .abbreviated, time: .omitted)).font(.headline)
                    Text("\(String(format: "%.1f", entry.durationHours))h sleep • Quality: \(entry.quality)/5").font(.caption).foregroundColor(.secondary)
                }
            }
            .onDelete { indices in
                indices.forEach { index in
                    // Delete logic
                }
            }
        }
        .navigationTitle("History")
    }
}

struct AddSleepView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    @State var sleepTime = Date().addingTimeInterval(-28800)
    @State var wakeTime = Date()
    @State var quality = 3

    var body: some View {
        NavigationStack {
            Form {
                Section("Sleep Time") {
                    DatePicker("Bedtime", selection: $sleepTime, displayedComponents: [.hourAndMinute])
                    DatePicker("Wake time", selection: $wakeTime, displayedComponents: [.hourAndMinute])
                }
                Section("Quality") {
                    Picker("How did you sleep?", selection: $quality) {
                        ForEach(1...5, id: \.self) { Text("\($0)/5").tag($0) }
                    }
                }
            }
            .navigationTitle("Log Sleep")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let entry = SleepEntry(date: Date(), sleepTime: sleepTime, wakeTime: wakeTime, quality: quality)
                        modelContext.insert(entry)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SettingsView: View {
    @AppStorage("targetSleepHours") var targetSleepHours = 8.0

    var body: some View {
        NavigationStack {
            Form {
                Section("Sleep Goals") {
                    Stepper("Target: \(String(format: "%.1f", targetSleepHours)) hours", value: $targetSleepHours, step: 0.5, in: 6...10)
                }
                Section("About") {
                    LabeledContent("Version", value: "1.0")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

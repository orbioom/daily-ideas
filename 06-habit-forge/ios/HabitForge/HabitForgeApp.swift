import SwiftUI
import SwiftData

@Model final class Habit {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String
    var icon: String
    var color: String
    var frequency: String // daily, weekdays, specific days
    @Relationship(deleteRule: .cascade) var logs: [HabitLog] = []
    var createdAt: Date

    var currentStreak: Int {
        var streak = 0
        let sorted = logs.sorted { $0.date > $1.date }
        for (idx, log) in sorted.enumerated() {
            let expectedDate = Calendar.current.date(byAdding: .day, value: -idx, to: Date())!
            if Calendar.current.isDate(log.date, inSameDayAs: expectedDate) {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }

    var longestStreak: Int {
        var longest = 0
        var current = 0
        let sorted = logs.sorted { $0.date < $1.date }
        var lastDate = Calendar.current.date(byAdding: .day, value: -1, to: sorted.first?.date ?? Date())

        for log in sorted {
            if let last = lastDate, Calendar.current.isDate(Calendar.current.date(byAdding: .day, value: 1, to: last)!, inSameDayAs: log.date) {
                current += 1
                longest = max(longest, current)
            } else {
                current = 1
            }
            lastDate = log.date
        }
        return max(longest, current)
    }

    var completionRate: Double {
        guard !logs.isEmpty else { return 0 }
        let last30 = logs.filter { Calendar.current.dateComponents([.day], from: $0.date, to: Date()).day ?? 0 < 30 }
        return Double(last30.count) / 30.0
    }
}

@Model final class HabitLog {
    @Attribute(.unique) var id: UUID = UUID()
    var date: Date
    var completed: Bool
}

@main
struct HabitForgeApp: App {
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding = false

    var modelContainer: ModelContainer = {
        let schema = Schema([Habit.self, HabitLog.self])
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
            Text("🔥").font(.system(size: 80))
            VStack {
                Text("Habit Forge")
                    .font(.title).fontWeight(.bold)
                Text("Build habits with unlimited tracking and AI motivation")
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
    @Query var habits: [Habit]
    @State var showAddHabit = false
    @State var selectedDate = Date()

    var todayHabits: [Habit] { habits.filter { habit in
        let todayLog = habit.logs.first { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
        return todayLog == nil || !todayLog!.completed
    }}

    var completedToday: Int { habits.count - todayHabits.count }

    var body: some View {
        TabView {
            NavigationStack {
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Today").font(.caption).foregroundColor(.secondary)
                            Text("\(completedToday)/\(habits.count)").font(.title2).fontWeight(.bold)
                        }
                        Spacer()
                        CircularProgress(value: Double(completedToday) / max(Double(habits.count), 1), size: 80)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(8)

                    if habits.isEmpty {
                        VStack {
                            Text("No habits yet").font(.headline)
                            Text("Add your first habit to get started").font(.body).foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(habits) { habit in
                                NavigationLink(destination: HabitDetailView(habit: habit)) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(habit.name).font(.headline)
                                            Text("🔥 \(habit.currentStreak) day streak").font(.caption).foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Button(action: { logHabit(habit) }) {
                                            Image(systemName: todayComplete(habit) ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(todayComplete(habit) ? .green : .gray)
                                        }
                                    }
                                }
                            }
                            .onDelete { indices in
                                indices.forEach { _ in }
                            }
                        }
                    }
                }
                .padding()
                .navigationTitle("Today")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: { showAddHabit = true }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .tabItem { Label("Today", systemImage: "checkmark.circle.fill") }

            NavigationStack {
                if habits.isEmpty {
                    VStack {
                        Text("No habits").font(.headline)
                    }
                } else {
                    List {
                        ForEach(habits) { habit in
                            NavigationLink(destination: HabitDetailView(habit: habit)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(habit.name).font(.headline)
                                    HStack {
                                        Text("Current: \(habit.currentStreak)d").font(.caption)
                                        Text("Best: \(habit.longestStreak)d").font(.caption).foregroundColor(.secondary)
                                        Text("\(String(format: "%.0f", habit.completionRate * 100))% completed").font(.caption)
                                    }
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Habits")
            }
            .tabItem { Label("All Habits", systemImage: "list.bullet") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
        .sheet(isPresented: $showAddHabit) {
            AddHabitView()
        }
    }

    @Environment(\.modelContext) var modelContext

    func todayComplete(_ habit: Habit) -> Bool {
        habit.logs.contains { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) && $0.completed }
    }

    func logHabit(_ habit: Habit) {
        let today = Calendar.current.startOfDay(for: selectedDate)
        if let existingLog = habit.logs.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            existingLog.completed.toggle()
        } else {
            let log = HabitLog(date: today, completed: true)
            habit.logs.append(log)
        }
    }
}

struct CircularProgress: View {
    let value: Double
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 8)

            Circle()
                .trim(from: 0, to: value)
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))

            Text("\(String(format: "%.0f", value * 100))%")
                .font(.title3).fontWeight(.bold)
        }
        .frame(width: size, height: size)
    }
}

struct HabitDetailView: View {
    let habit: Habit

    var body: some View {
        VStack {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Current Streak").font(.caption).foregroundColor(.secondary)
                        Text("🔥 \(habit.currentStreak) days").font(.title2).fontWeight(.bold)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("Best Streak").font(.caption).foregroundColor(.secondary)
                        Text("\(habit.longestStreak) days").font(.title2).fontWeight(.bold)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(8)

            List {
                Section("Last 7 Days") {
                    ForEach(0..<7, id: \.self) { idx in
                        let date = Calendar.current.date(byAdding: .day, value: -idx, to: Date())!
                        let completed = habit.logs.contains { Calendar.current.isDate($0.date, inSameDayAs: date) && $0.completed }
                        HStack {
                            Text(date.formatted(date: .abbreviated, time: .omitted))
                            Spacer()
                            Image(systemName: completed ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(completed ? .green : .gray)
                        }
                    }
                }
            }
        }
        .navigationTitle(habit.name)
    }
}

struct AddHabitView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    @State var name = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Habit name", text: $name)
                Picker("Frequency", selection: .constant("daily")) {
                    Text("Daily").tag("daily")
                    Text("Weekdays").tag("weekdays")
                }
            }
            .navigationTitle("New Habit")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let habit = Habit(name: name, icon: "🔥", color: "#FF6B6B", frequency: "daily", createdAt: Date())
                        modelContext.insert(habit)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            Form {
                Section("About") {
                    LabeledContent("Version", value: "1.0")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

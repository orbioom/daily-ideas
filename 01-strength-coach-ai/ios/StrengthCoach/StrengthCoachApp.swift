import SwiftUI
import SwiftData

@main
struct StrengthCoachApp: App {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false

    var modelContainer: ModelContainer = {
        let schema = Schema([
            Exercise.self,
            Workout.self,
            WorkoutSession.self,
            ProgressionEntry.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                MainTabView()
                    .modelContainer(modelContainer)
            } else {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                    .modelContainer(modelContainer)
            }
        }
    }
}

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Spacer()

                VStack(spacing: 16) {
                    Text("💪")
                        .font(.system(size: 80))

                    Text("Strength Coach")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Get personalized strength training with AI-powered progression")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .foregroundColor(.accentColor)
                        Text("Personalized workouts tailored to your strength level")
                    }

                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundColor(.accentColor)
                        Text("Track progressive overload automatically")
                    }

                    HStack {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.accentColor)
                        Text("Smart weight suggestions based on performance")
                    }
                }
                .font(.callout)

                Spacer()

                Button(action: { hasCompletedOnboarding = true }) {
                    Text("Get Started")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            WorkoutHistoryView()
                .tabItem {
                    Label("History", systemImage: "calendar")
                }

            ProgressionView()
                .tabItem {
                    Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .tint(.accentColor)
    }
}

struct HomeView: View {
    @Environment(\.modelContext) var modelContext
    @Query(sort: \WorkoutSession.date, order: .reverse) var sessions: [WorkoutSession]
    @State var showStartSession = false

    var lastSession: WorkoutSession? { sessions.first }

    var body: some View {
        NavigationStack {
            VStack {
                if let lastSession = lastSession {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Last Workout")
                            .font(.headline)

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(lastSession.exercises.count) exercises")
                                    .font(.body)
                                Text(lastSession.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text("\(lastSession.duration) min")
                                    .font(.body)
                                Text("Feeling: \(lastSession.feeling)/5")
                                    .font(.caption)
                            }
                        }

                        Button(action: { showStartSession = true }) {
                            Text("Log New Session")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                    .padding()
                } else {
                    VStack {
                        Text("No workouts yet")
                            .font(.headline)
                        Text("Start your first session to begin tracking")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }

                Spacer()
            }
            .navigationTitle("Strength Coach")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showStartSession = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showStartSession) {
            NewSessionView()
        }
    }
}

struct WorkoutHistoryView: View {
    @Query(sort: \WorkoutSession.date, order: .reverse) var sessions: [WorkoutSession]

    var body: some View {
        NavigationStack {
            if sessions.isEmpty {
                VStack {
                    Text("No workout history")
                        .font(.headline)
                    Text("Start logging sessions to see them here")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .navigationTitle("History")
            } else {
                List {
                    ForEach(sessions) { session in
                        NavigationLink(destination: SessionDetailView(session: session)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(session.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.headline)
                                Text("\(session.exercises.count) exercises • \(session.duration) min")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onDelete { indices in
                        indices.forEach { index in
                            modelContext.delete(sessions[index])
                        }
                    }
                }
                .navigationTitle("History")
            }
        }
    }

    @Environment(\.modelContext) var modelContext
}

struct SessionDetailView: View {
    let session: WorkoutSession

    var body: some View {
        VStack {
            List {
                Section("Exercises") {
                    ForEach(session.exercises.sorted { $0.order < $1.order }) { exercise in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(exercise.exerciseName)
                                .font(.headline)
                            Text("\(exercise.sets.count) sets")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section("Details") {
                    LabeledContent("Duration", value: "\(session.duration) min")
                    LabeledContent("Feeling", value: "\(session.feeling)/5")
                    if !session.notes.isEmpty {
                        LabeledContent("Notes", value: session.notes)
                    }
                }
            }
        }
        .navigationTitle(session.date.formatted(date: .abbreviated, time: .omitted))
    }
}

struct NewSessionView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    @State private var exercises: [SessionExercise] = []
    @State private var duration = 60
    @State private var notes = ""
    @State private var feeling = 3

    var body: some View {
        NavigationStack {
            Form {
                Section("Exercises") {
                    Button(action: { exercises.append(SessionExercise(exerciseName: "New Exercise", order: exercises.count)) }) {
                        Label("Add Exercise", systemImage: "plus.circle")
                    }

                    ForEach($exercises) { $exercise in
                        VStack {
                            TextField("Exercise name", text: $exercise.exerciseName)
                            Stepper("Sets: \(exercise.sets.count)", value: $exercise.restTime, step: 30)
                        }
                    }
                }

                Section("Details") {
                    Stepper("Duration: \(duration) min", value: $duration, step: 5)
                    Picker("Feeling", selection: $feeling) {
                        ForEach(1...5, id: \.self) { num in
                            Text("\(num)/5").tag(num)
                        }
                    }
                    TextField("Notes", text: $notes)
                }
            }
            .navigationTitle("Log Workout")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let session = WorkoutSession(date: Date())
                        session.duration = duration
                        session.notes = notes
                        session.feeling = feeling
                        session.exercises = exercises

                        modelContext.insert(session)
                        dismiss()
                    }
                    .disabled(exercises.isEmpty)
                }
            }
        }
    }
}

struct ProgressionView: View {
    @Query(sort: \ProgressionEntry.date, order: .reverse) var entries: [ProgressionEntry]
    @State private var selectedExercise: String?

    var uniqueExercises: [String] {
        Array(Set(entries.map { $0.exerciseName })).sorted()
    }

    var body: some View {
        NavigationStack {
            VStack {
                if entries.isEmpty {
                    VStack {
                        Text("No progression data yet")
                            .font(.headline)
                    }
                    .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(uniqueExercises, id: \.self) { exercise in
                                let exerciseEntries = entries.filter { $0.exerciseName == exercise }
                                if let latest = exerciseEntries.first {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(exercise)
                                            .font(.headline)

                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text("Current 1RM").font(.caption).foregroundColor(.secondary)
                                                Text("\(Int(latest.estimated1RM)) lbs").font(.title3).fontWeight(.bold)
                                            }

                                            Spacer()

                                            VStack(alignment: .trailing) {
                                                Text("Last: \(Int(latest.weight)) x \(latest.reps)").font(.caption).foregroundColor(.secondary)
                                                Text("Reps").font(.caption)
                                            }
                                        }
                                    }
                                    .padding()
                                    .background(Color(.systemBackground))
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Progression")
        }
    }
}

struct SettingsView: View {
    @AppStorage("shouldShowReminders") var shouldShowReminders = true
    @AppStorage("reminderTime") var reminderTime = 19.0

    var body: some View {
        NavigationStack {
            Form {
                Section("Notifications") {
                    Toggle("Workout Reminders", isOn: $shouldShowReminders)
                    if shouldShowReminders {
                        Stepper("Remind at \(Int(reminderTime)):00", value: $reminderTime, step: 1)
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Build", value: "1")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

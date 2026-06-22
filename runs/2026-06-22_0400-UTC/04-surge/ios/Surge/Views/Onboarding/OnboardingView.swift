import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var currentStep: Int = 0
    @State private var selectedRace: RaceType = .marathon
    @State private var goalHours: Int = 4
    @State private var goalMinutes: Int = 0
    @State private var trainingStartDate: Date = Date()
    @State private var useSuggestedPace: Bool = false
    @State private var isGeneratingPlan: Bool = false

    private var goalTimeSeconds: Int {
        (goalHours * 3600) + (goalMinutes * 60)
    }

    private var suggestedGoalTime: Int {
        switch selectedRace {
        case .marathon: return 14400    // 4:00:00
        case .halfMarathon: return 7200 // 2:00:00
        }
    }

    var body: some View {
        ZStack {
            Color.surgeBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header progress
                HStack(spacing: 8) {
                    ForEach(0..<3) { step in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(step <= currentStep ? Color.surgeAccent : Color.surgeDivider)
                            .frame(height: 3)
                            .animation(.easeInOut(duration: 0.3), value: currentStep)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)

                // Step content
                TabView(selection: $currentStep) {
                    StepOneView(selectedRace: $selectedRace)
                        .tag(0)
                    StepTwoView(
                        selectedRace: selectedRace,
                        goalHours: $goalHours,
                        goalMinutes: $goalMinutes,
                        useSuggestedPace: $useSuggestedPace,
                        suggestedGoalTime: suggestedGoalTime
                    )
                    .tag(1)
                    StepThreeView(
                        selectedRace: selectedRace,
                        trainingStartDate: $trainingStartDate
                    )
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentStep)

                // Navigation buttons
                VStack(spacing: 12) {
                    Button(action: handleNext) {
                        if isGeneratingPlan {
                            HStack(spacing: 10) {
                                ProgressView()
                                    .tint(.white)
                                Text("Building your plan...")
                            }
                        } else {
                            Text(currentStep == 2 ? "Start Training" : "Continue")
                        }
                    }
                    .surgeHighlightButton()
                    .disabled(isGeneratingPlan)

                    if currentStep > 0 {
                        Button("Back") {
                            withAnimation { currentStep -= 1 }
                        }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.surgeTextSecondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }

    private func handleNext() {
        if currentStep < 2 {
            withAnimation { currentStep += 1 }
        } else {
            completeOnboarding()
        }
    }

    private func completeOnboarding() {
        isGeneratingPlan = true
        let finalGoalTime = useSuggestedPace ? suggestedGoalTime : goalTimeSeconds
        let raceDate = Calendar.current.date(byAdding: .day, value: selectedRace.totalWeeks * 7, to: trainingStartDate)

        Task {
            let profile = RunnerProfile(
                goalRace: selectedRace.rawValue,
                goalTimeSeconds: finalGoalTime,
                trainingStartDate: trainingStartDate,
                raceDateTarget: raceDate,
                hasCompletedOnboarding: true
            )
            modelContext.insert(profile)

            let templates = PlanEngine.generatePlan(
                raceType: selectedRace,
                goalTimeSeconds: finalGoalTime,
                startDate: trainingStartDate
            )

            for template in templates {
                let plannedRun = PlannedRun(
                    weekNumber: template.weekNumber,
                    dayOfWeek: template.dayOfWeek,
                    runType: template.runType.rawValue,
                    distanceKm: template.distanceKm,
                    paceTargetSecondsPerKm: template.paceTargetSecondsPerKm,
                    notes: template.notes
                )
                modelContext.insert(plannedRun)
            }

            try? modelContext.save()

            await MainActor.run {
                isGeneratingPlan = false
            }
        }
    }
}

// MARK: - Step 1: Race Type

struct StepOneView: View {
    @Binding var selectedRace: RaceType

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            VStack(alignment: .leading, spacing: 12) {
                Text("What's your goal?")
                    .font(.surgeTitle)
                    .foregroundColor(.surgeTextPrimary)
                Text("Choose the race you're training for")
                    .font(.surgeBody)
                    .foregroundColor(.surgeTextSecondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)

            VStack(spacing: 12) {
                ForEach(RaceType.allCases, id: \.self) { race in
                    RaceOptionCard(race: race, isSelected: selectedRace == race) {
                        selectedRace = race
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }
}

struct RaceOptionCard: View {
    let race: RaceType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.surgeHighlight : Color.surgeSurface)
                        .frame(width: 44, height: 44)
                    Image(systemName: "figure.run")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(isSelected ? .white : .surgeTextSecondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(race.displayName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.surgeTextPrimary)
                    Text(String(format: "%.3g km • %d-week plan", race.distanceKm, race.totalWeeks))
                        .font(.surgeCaption)
                        .foregroundColor(.surgeTextSecondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.surgeHighlight)
                        .font(.system(size: 22))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? Color.surgeHighlight.opacity(0.1) : Color.surgeSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Color.surgeHighlight.opacity(0.5) : Color.surgeDivider, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Step 2: Goal Time

struct StepTwoView: View {
    let selectedRace: RaceType
    @Binding var goalHours: Int
    @Binding var goalMinutes: Int
    @Binding var useSuggestedPace: Bool
    let suggestedGoalTime: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Goal finish time")
                    .font(.surgeTitle)
                    .foregroundColor(.surgeTextPrimary)
                Text("Set your target time for the \(selectedRace.displayName)")
                    .font(.surgeBody)
                    .foregroundColor(.surgeTextSecondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)

            // Time picker
            VStack(spacing: 16) {
                if !useSuggestedPace {
                    HStack(spacing: 0) {
                        Picker("Hours", selection: $goalHours) {
                            ForEach(0..<24) { h in
                                Text("\(h)h").tag(h)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                        .clipped()

                        Text(":")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.surgeTextSecondary)

                        Picker("Minutes", selection: $goalMinutes) {
                            ForEach(stride(from: 0, through: 59, by: 5).map { $0 }, id: \.self) { m in
                                Text(String(format: "%02dm", m)).tag(m)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                        .clipped()
                    }
                    .frame(height: 150)
                    .surgeCard()
                } else {
                    let hours = suggestedGoalTime / 3600
                    let mins = (suggestedGoalTime % 3600) / 60
                    HStack {
                        Text("Suggested goal:")
                            .foregroundColor(.surgeTextSecondary)
                        Spacer()
                        Text(String(format: "%d:%02d:00", hours, mins))
                            .font(.surgeMonospace)
                            .foregroundColor(.surgeHighlight)
                    }
                    .padding(16)
                    .surgeCard()
                }

                Toggle(isOn: $useSuggestedPace) {
                    Text("Not sure? Use suggested pace")
                        .font(.surgeBody)
                        .foregroundColor(.surgeTextPrimary)
                }
                .tint(.surgeAccent)
                .padding(16)
                .surgeCard()
            }
            .padding(.horizontal, 24)

            // Pace preview
            if !useSuggestedPace {
                let time = (goalHours * 3600) + (goalMinutes * 60)
                if time > 0 {
                    let paces = PaceEngine.trainingPaces(goalRaceSeconds: time, raceType: selectedRace)
                    VStack(spacing: 8) {
                        Text("Your training paces")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.surgeTextSecondary)
                        HStack(spacing: 0) {
                            PacePreviewItem(label: "Easy", pace: PaceEngine.formatPace(paces.easyPace))
                            Divider().background(Color.surgeDivider)
                            PacePreviewItem(label: "Tempo", pace: PaceEngine.formatPace(paces.tempoPace))
                            Divider().background(Color.surgeDivider)
                            PacePreviewItem(label: "Race", pace: PaceEngine.formatPace(paces.racePace))
                        }
                        .frame(height: 60)
                    }
                    .surgeCard()
                    .padding(.horizontal, 24)
                }
            }

            Spacer()
        }
    }
}

struct PacePreviewItem: View {
    let label: String
    let pace: String

    var body: some View {
        VStack(spacing: 4) {
            Text(pace)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(.surgeTextPrimary)
            Text(label)
                .font(.surgeCaption)
                .foregroundColor(.surgeTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Step 3: Training Start

struct StepThreeView: View {
    let selectedRace: RaceType
    @Binding var trainingStartDate: Date

    private var raceDate: Date {
        Calendar.current.date(byAdding: .day, value: selectedRace.totalWeeks * 7, to: trainingStartDate) ?? trainingStartDate
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 12) {
                Text("When do you start?")
                    .font(.surgeTitle)
                    .foregroundColor(.surgeTextPrimary)
                Text("Pick your training start date")
                    .font(.surgeBody)
                    .foregroundColor(.surgeTextSecondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)

            VStack(spacing: 16) {
                DatePicker(
                    "Training starts",
                    selection: $trainingStartDate,
                    in: Date()...,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(.surgeAccent)
                .padding(8)
                .surgeCard()

                HStack {
                    Image(systemName: "flag.checkered")
                        .foregroundColor(.surgeHighlight)
                    Text("Estimated race date:")
                        .foregroundColor(.surgeTextSecondary)
                        .font(.surgeBody)
                    Spacer()
                    Text(raceDate, style: .date)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.surgeTextPrimary)
                }
                .padding(16)
                .surgeCard()
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }
}

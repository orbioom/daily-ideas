import SwiftUI

struct TimerSetupView: View {
    @State private var selectedType: TherapyType = .sauna
    @State private var durationMinutes: Double = 20
    @State private var temperatureCelsius: Double = 80
    @State private var rounds: Int = 1
    @State private var showTimer = false
    @AppStorage("mistUseFahrenheit") private var useFahrenheit = false

    var displayTemperature: Double {
        useFahrenheit ? temperatureCelsius * 9/5 + 32 : temperatureCelsius
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Color(red: 0.05, green: 0.18, blue: 0.22), Color(red: 0.02, green: 0.08, blue: 0.12)],
                              startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        Text("New Session")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 20)

                        // Type selector
                        VStack(alignment: .leading, spacing: 12) {
                            sectionLabel("Session Type")
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(TherapyType.allCases) { t in
                                    typeButton(t)
                                }
                            }
                        }

                        // Duration
                        VStack(alignment: .leading, spacing: 12) {
                            sectionLabel("Duration")
                            HStack {
                                Text("\(Int(durationMinutes)) min")
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .frame(width: 80, alignment: .leading)
                                Slider(value: $durationMinutes, in: 1...60, step: 1)
                                    .tint(Color(red: 0.2, green: 0.85, blue: 0.85))
                            }
                            .padding(16)
                            .background(Color.white.opacity(0.07))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        // Temperature
                        VStack(alignment: .leading, spacing: 12) {
                            sectionLabel("Temperature")
                            HStack {
                                Text(tempDisplay)
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .frame(width: 80, alignment: .leading)
                                Slider(
                                    value: $temperatureCelsius,
                                    in: selectedType.isHot ? 40...120 : 0...25,
                                    step: 1
                                )
                                .tint(selectedType.isHot ? .orange : .cyan)
                            }
                            .padding(16)
                            .background(Color.white.opacity(0.07))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        // Rounds
                        VStack(alignment: .leading, spacing: 12) {
                            sectionLabel("Rounds")
                            HStack(spacing: 20) {
                                Button(action: { if rounds > 1 { rounds -= 1 } }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(rounds > 1 ? Color(red: 0.2, green: 0.85, blue: 0.85) : .white.opacity(0.25))
                                }
                                Text("\(rounds)")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .frame(width: 40, alignment: .center)
                                Button(action: { if rounds < 10 { rounds += 1 } }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(Color(red: 0.2, green: 0.85, blue: 0.85))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(Color.white.opacity(0.07))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        Button(action: { showTimer = true }) {
                            HStack {
                                Image(systemName: "timer")
                                Text("Start Session")
                            }
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(red: 0.15, green: 0.7, blue: 0.7))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .fullScreenCover(isPresented: $showTimer) {
                ActiveSessionView(
                    type: selectedType,
                    durationSeconds: Int(durationMinutes) * 60,
                    temperatureCelsius: temperatureCelsius,
                    rounds: rounds
                )
            }
        }
        .onChange(of: selectedType) { _, t in
            temperatureCelsius = t.defaultTempCelsius
            durationMinutes = Double(t.defaultDurationSeconds / 60)
        }
    }

    private var tempDisplay: String {
        if useFahrenheit { return String(format: "%.0f°F", temperatureCelsius * 9/5 + 32) }
        return String(format: "%.0f°C", temperatureCelsius)
    }

    private func typeButton(_ t: TherapyType) -> some View {
        Button(action: { selectedType = t }) {
            HStack {
                Image(systemName: t.symbol)
                    .foregroundStyle(t.isHot ? .orange : .cyan)
                Text(t.rawValue)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(selectedType == t ? Color.white.opacity(0.15) : Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selectedType == t ? Color(red: 0.2, green: 0.85, blue: 0.85).opacity(0.7) : Color.clear, lineWidth: 1.5)
            )
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(.white.opacity(0.4))
    }
}

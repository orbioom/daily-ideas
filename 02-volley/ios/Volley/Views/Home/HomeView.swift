import SwiftUI
import SwiftData

struct HomeView: View {
    @Query private var questions: [Question]
    @Query private var settingsQuery: [AppSettings]
    @State private var selectedMode: QuestionMode? = nil
    @State private var showSetupSheet = false
    @State private var showSettings = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var settings: AppSettings? { settingsQuery.first }

    private func questionCount(for mode: QuestionMode) -> Int {
        questions.filter { $0.mode == mode.rawValue && $0.isEnabled }.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Volley")
                                    .font(.largeTitle.bold())
                                    .foregroundStyle(VolleyTheme.text)
                                Text("Pick a mode and start playing")
                                    .font(.subheadline)
                                    .foregroundStyle(VolleyTheme.textSecondary)
                            }
                            Spacer()
                            Button {
                                showSettings = true
                            } label: {
                                Image(systemName: "gearshape.fill")
                                    .font(.title2)
                                    .foregroundStyle(VolleyTheme.textSecondary)
                            }
                            .accessibilityLabel("Settings")
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)

                        // Mode grid — 2 columns
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(QuestionMode.allCases) { mode in
                                ModeCard(
                                    mode: mode,
                                    questionCount: questionCount(for: mode)
                                ) {
                                    selectedMode = mode
                                    showSetupSheet = true
                                }
                            }
                        }
                        .padding(.horizontal)

                        // Quick stats
                        QuickStatsSection(questions: questions)
                            .padding(.horizontal)

                        Spacer(minLength: 32)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .sheet(isPresented: $showSetupSheet) {
                if let mode = selectedMode {
                    GameSetupSheet(mode: mode, questions: questions, settings: settings)
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }
}

struct ModeCard: View {
    let mode: QuestionMode
    let questionCount: Int
    let onTap: () -> Void

    @State private var isPressed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: onTap) {
            ZStack {
                LinearGradient(
                    colors: VolleyTheme.gradient(for: mode),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))

                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: VolleyTheme.icon(for: mode))
                        .font(.system(size: 28))
                        .foregroundStyle(.white)

                    Spacer()

                    VStack(alignment: .leading, spacing: 4) {
                        Text(mode.rawValue)
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("\(questionCount) questions")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
            }
        }
        .frame(height: 160)
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(reduceMotion ? .none : .spring(response: 0.25), value: isPressed)
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityLabel("\(mode.rawValue), \(questionCount) questions")
        .accessibilityHint("Double tap to set up a game")
    }
}

struct QuickStatsSection: View {
    let questions: [Question]

    private var totalEnabled: Int { questions.filter { $0.isEnabled }.count }
    private var customCount: Int { questions.filter { $0.isCustom }.count }

    var body: some View {
        HStack(spacing: 12) {
            MiniStat(value: "\(totalEnabled)", label: "Questions", color: VolleyTheme.accent)
            MiniStat(value: "\(QuestionMode.allCases.count)", label: "Modes", color: Color(hex: "7C3AED"))
            MiniStat(value: "\(customCount)", label: "Custom", color: Color(hex: "059669"))
        }
    }
}

struct MiniStat: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(VolleyTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(VolleyTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

import SwiftUI
import PencilKit

struct GuessPhaseView: View {
    @Bindable var engine: ScrawlGameEngine
    @FocusState private var isTextFieldFocused: Bool

    private var guessTeamName: String {
        guard engine.teams.count > 1 else { return "Your team" }
        let guessIndex = (engine.currentTeamIndex + 1) % engine.teams.count
        return engine.teams[guessIndex].name
    }

    var body: some View {
        ZStack {
            Color(red: 1.0, green: 254 / 255, blue: 245 / 255)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 6) {
                    Text("Guess the Drawing!")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(Color(red: 28 / 255, green: 28 / 255, blue: 30 / 255))

                    Text("\(guessTeamName) — what did they draw?")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(red: 100 / 255, green: 100 / 255, blue: 102 / 255))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .padding(.bottom, 16)

                // Drawing display
                DrawingCanvas(drawing: $engine.drawing, isEnabled: false)
                    .frame(maxWidth: .infinity)
                    .frame(height: 300)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 4)
                    .padding(.horizontal, 16)

                Spacer().frame(height: 24)

                // Guess input
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "text.cursor")
                            .foregroundStyle(Color(red: 74 / 255, green: 144 / 255, blue: 217 / 255))

                        TextField("Type your guess...", text: $engine.guessText)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .textFieldStyle(.plain)
                            .focused($isTextFieldFocused)
                            .submitLabel(.done)
                            .onSubmit {
                                if !engine.guessText.isEmpty {
                                    engine.submitGuess()
                                }
                            }
                            .accessibilityLabel("Type your guess here")

                        if !engine.guessText.isEmpty {
                            Button {
                                engine.guessText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(
                                        Color(red: 200 / 255, green: 199 / 255, blue: 204 / 255))
                            }
                            .accessibilityLabel("Clear guess")
                        }
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(14)
                    .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 2)
                    .padding(.horizontal, 20)

                    // Submit button
                    Button {
                        isTextFieldFocused = false
                        engine.submitGuess()
                    } label: {
                        Text("Submit Guess")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                engine.guessText.isEmpty
                                    ? Color(red: 200 / 255, green: 199 / 255, blue: 204 / 255)
                                    : Color(red: 74 / 255, green: 144 / 255, blue: 217 / 255)
                            )
                            .cornerRadius(16)
                            .shadow(
                                color: engine.guessText.isEmpty
                                    ? .clear
                                    : Color(red: 74 / 255, green: 144 / 255, blue: 217 / 255)
                                        .opacity(0.35),
                                radius: 8, x: 0, y: 4
                            )
                    }
                    .disabled(engine.guessText.isEmpty)
                    .padding(.horizontal, 20)
                    .accessibilityLabel("Submit your guess")
                }

                // OR divider
                HStack {
                    Rectangle()
                        .fill(Color(red: 200 / 255, green: 199 / 255, blue: 204 / 255))
                        .frame(height: 1)
                    Text("or said it aloud?")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(red: 100 / 255, green: 100 / 255, blue: 102 / 255))
                        .padding(.horizontal, 12)
                    Rectangle()
                        .fill(Color(red: 200 / 255, green: 199 / 255, blue: 204 / 255))
                        .frame(height: 1)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

                // Verbal guess buttons
                HStack(spacing: 12) {
                    Button {
                        engine.guessText = engine.currentWord
                        engine.submitGuess()
                    } label: {
                        VStack(spacing: 4) {
                            Text("✅")
                                .font(.system(size: 22))
                            Text("Correct!")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(Color(red: 52 / 255, green: 199 / 255, blue: 89 / 255))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            Color(red: 52 / 255, green: 199 / 255, blue: 89 / 255).opacity(0.15))
                        .cornerRadius(14)
                    }
                    .accessibilityLabel("We guessed correctly")

                    Button {
                        engine.guessText = "wrong"
                        engine.submitGuess()
                    } label: {
                        VStack(spacing: 4) {
                            Text("❌")
                                .font(.system(size: 22))
                            Text("Wrong")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(Color(red: 255 / 255, green: 107 / 255, blue: 107 / 255))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            Color(red: 255 / 255, green: 107 / 255, blue: 107 / 255).opacity(0.15))
                        .cornerRadius(14)
                    }
                    .accessibilityLabel("We guessed incorrectly")
                }
                .padding(.horizontal, 20)

                Spacer()
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
    }
}

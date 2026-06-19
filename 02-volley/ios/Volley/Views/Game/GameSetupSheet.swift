import SwiftUI

struct GameSetupSheet: View {
    let mode: QuestionMode
    let questions: [Question]
    let settings: AppSettings?

    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: QuestionCategory = .all
    @State private var questionCount = 10
    @State private var showGame = false

    private let countOptions = [5, 10, 15, 20, 30]

    private var availableCount: Int {
        questions.filter {
            $0.mode == mode.rawValue &&
            $0.isEnabled &&
            (selectedCategory == .all || $0.category == selectedCategory.rawValue)
        }.count
    }

    private var gradientColors: [Color] { VolleyTheme.gradient(for: mode) }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Gradient header
                LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .frame(height: 200)
                    .ignoresSafeArea(edges: .top)

                VStack(spacing: 0) {
                    // Mode header
                    VStack(spacing: 12) {
                        Image(systemName: VolleyTheme.icon(for: mode))
                            .font(.system(size: 36))
                            .foregroundStyle(.white)

                        Text(mode.rawValue)
                            .font(.title2.bold())
                            .foregroundStyle(.white)

                        Text("\(availableCount) questions available")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .frame(height: 180)
                    .frame(maxWidth: .infinity)

                    // Setup options
                    ScrollView {
                        VStack(spacing: 20) {
                            // Category picker
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Category")
                                    .font(.headline)
                                    .foregroundStyle(VolleyTheme.text)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(QuestionCategory.allCases) { category in
                                            if category != .party || settings?.hasPro == true || settings?.safeMode != true {
                                                CategoryChip(
                                                    category: category,
                                                    isSelected: selectedCategory == category,
                                                    gradientColors: gradientColors
                                                ) {
                                                    selectedCategory = category
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 2)
                                }
                            }
                            .padding()
                            .background(VolleyTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 16))

                            // Question count
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Number of Questions")
                                    .font(.headline)
                                    .foregroundStyle(VolleyTheme.text)

                                HStack(spacing: 8) {
                                    ForEach(countOptions, id: \.self) { count in
                                        Button {
                                            questionCount = count
                                        } label: {
                                            Text("\(count)")
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(questionCount == count ? .white : VolleyTheme.text)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 10)
                                                .background(
                                                    questionCount == count
                                                    ? LinearGradient(colors: gradientColors, startPoint: .leading, endPoint: .trailing)
                                                    : LinearGradient(colors: [VolleyTheme.surface, VolleyTheme.surface], startPoint: .leading, endPoint: .trailing)
                                                )
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .padding()
                            .background(VolleyTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 16))

                            // Start button
                            NavigationLink(destination: GameView(
                                mode: mode,
                                category: selectedCategory,
                                questions: questions,
                                questionCount: min(questionCount, max(availableCount, 1)),
                                settings: settings
                            )) {
                                Text("Let's Go!")
                                    .font(.headline.bold())
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        LinearGradient(colors: gradientColors, startPoint: .leading, endPoint: .trailing)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .disabled(availableCount == 0)

                            if availableCount == 0 {
                                Text("No questions available for this combination.")
                                    .font(.caption)
                                    .foregroundStyle(VolleyTheme.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.white)
                            .font(.title3)
                    }
                    .accessibilityLabel("Close")
                }
            }
        }
    }
}

struct CategoryChip: View {
    let category: QuestionCategory
    let isSelected: Bool
    let gradientColors: [Color]
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Text(category.emoji)
                    .font(.subheadline)
                Text(category.displayName)
                    .font(.subheadline.weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? .white : VolleyTheme.text)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                isSelected
                ? AnyView(LinearGradient(colors: gradientColors, startPoint: .leading, endPoint: .trailing))
                : AnyView(VolleyTheme.surface)
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(category.displayName) category\(isSelected ? ", selected" : "")")
    }
}

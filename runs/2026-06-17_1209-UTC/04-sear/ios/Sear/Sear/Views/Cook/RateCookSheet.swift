import SwiftUI
import SwiftData

/// Sheet to mark a cook done and rate it 1–5 with notes.
struct RateCookSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss
    @Bindable var cook: Cook

    @State private var rating: Int
    @State private var notes: String

    init(cook: Cook) {
        self.cook = cook
        _rating = State(initialValue: cook.clampedRating ?? 4)
        _notes = State(initialValue: cook.notes)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        Text("How did it turn out?")
                            .font(Theme.rounded(20, .bold))
                            .foregroundStyle(Theme.ink)

                        HStack(spacing: 10) {
                            ForEach(1...5, id: \.self) { i in
                                Button {
                                    rating = i
                                    Haptics.tap(settings.hapticsEnabled)
                                } label: {
                                    Image(systemName: i <= rating ? "star.fill" : "star")
                                        .font(.system(size: 30))
                                        .foregroundStyle(Theme.ember)
                                }
                                .accessibilityLabel("\(i) star\(i == 1 ? "" : "s")")
                                .accessibilityAddTraits(i == rating ? .isSelected : [])
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(Theme.rounded(14, .semibold))
                                .foregroundStyle(Theme.inkSoft)
                            TextEditor(text: $notes)
                                .frame(minHeight: 120)
                                .padding(8)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Theme.surface))
                                .scrollContentBackground(.hidden)
                        }

                        PrimaryButton(title: "Save & mark done", systemImage: "checkmark.seal.fill") {
                            save()
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Rate cook")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func save() {
        cook.resultRating = min(max(rating, 1), 5)
        cook.notes = notes
        cook.status = .done
        if cook.finishedDate == nil { cook.finishedDate = Date() }
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
        dismiss()
    }
}

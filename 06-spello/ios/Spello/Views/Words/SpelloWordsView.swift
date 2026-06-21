import SwiftUI
import SwiftData

struct SpelloWordsView: View {
    @Query private var profiles: [SpelloProfile]
    @Query private var prefs: [SpelloPrefs]
    @State private var selectedGrade: Int = 1

    private var activeProfile: SpelloProfile? {
        guard let id = prefs.first?.activeProfileId else { return profiles.first }
        return profiles.first(where: { $0.id == id }) ?? profiles.first
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                gradeSelector.padding()
                List(spelloWords[selectedGrade] ?? [], id: \.self) { word in
                    Text(word)
                        .font(.system(.body, design: .monospaced))
                }
            }
            .navigationTitle("Word List")
        }
        .onAppear { selectedGrade = activeProfile?.gradeLevel ?? 1 }
    }

    private var gradeSelector: some View {
        Picker("Grade", selection: $selectedGrade) {
            ForEach(1...5, id: \.self) { g in Text("Grade \(g)").tag(g) }
        }
        .pickerStyle(.segmented)
    }
}

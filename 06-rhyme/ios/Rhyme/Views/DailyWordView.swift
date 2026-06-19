import SwiftUI

struct DailyWordView: View {
    @State private var dailyWord: String = ""
    @State private var dailyHint: String = ""
    @State private var enteredRhyme = ""
    @State private var foundRhymes: [String] = []
    @State private var wrongGuess = false
    @State private var gameComplete = false

    let targetCount = 5

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Daily word card
                    VStack(spacing: 8) {
                        Text("Today's Word").font(.subheadline).foregroundStyle(.secondary)
                        Text(dailyWord)
                            .font(.system(size: 44, weight: .black, design: .rounded))
                            .foregroundStyle(.pink)
                        Text(dailyHint).font(.subheadline).foregroundStyle(.secondary)
                        HStack {
                            Image(systemName: "waveform").foregroundStyle(.pink)
                            Text("\(RhymeDatabase.syllableCount(for: dailyWord)) syllables")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .padding(28)
                    .frame(maxWidth: .infinity)
                    .background(Color.pink.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))

                    // Progress
                    HStack(spacing: 8) {
                        ForEach(0..<targetCount, id: \.self) { i in
                            Circle()
                                .fill(i < foundRhymes.count ? Color.pink : Color(.systemGray4))
                                .frame(width: 12, height: 12)
                        }
                        Text("\(foundRhymes.count)/\(targetCount)").font(.caption).foregroundStyle(.secondary)
                    }

                    if !gameComplete {
                        // Input
                        HStack {
                            TextField("Type a rhyme…", text: $enteredRhyme)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .padding(12)
                                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
                                .onSubmit { checkRhyme() }
                            Button("Check") { checkRhyme() }
                                .buttonStyle(.borderedProminent).tint(.pink)
                                .disabled(enteredRhyme.trimmingCharacters(in: .whitespaces).isEmpty)
                        }

                        if wrongGuess {
                            Label("Not a rhyme — try again!", systemImage: "xmark.circle")
                                .font(.caption).foregroundStyle(.red)
                        }
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "star.fill").font(.system(size: 48)).foregroundStyle(.yellow)
                            Text("Challenge Complete!").font(.title2.weight(.bold))
                            Text("Come back tomorrow for a new word!").foregroundStyle(.secondary)
                        }
                        .padding()
                    }

                    // Found rhymes
                    if !foundRhymes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Found Rhymes").font(.headline)
                            ForEach(foundRhymes, id: \.self) { r in
                                HStack {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                                    Text(r).fontWeight(.medium)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding()
            }
            .navigationTitle("Daily Challenge")
            .onAppear(perform: loadDailyWord)
        }
    }

    private func loadDailyWord() {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month, .day], from: Date())
        let seed = UInt64((comps.year ?? 2024) * 10000 + (comps.month ?? 1) * 100 + (comps.day ?? 1))
        var rng = SplitMix64(seed: seed)
        let allWords = RhymeDatabase.allWords()
        let idx = Int(rng.next() % UInt64(allWords.count))
        dailyWord = allWords[idx]
        dailyHint = "\(RhymeDatabase.perfectRhymes(for: dailyWord).count) known rhymes"
    }

    private func checkRhyme() {
        let guess = enteredRhyme.trimmingCharacters(in: .whitespaces).lowercased()
        enteredRhyme = ""
        guard !guess.isEmpty else { return }
        let rhymes = RhymeDatabase.perfectRhymes(for: dailyWord)
        if rhymes.map({ $0.lowercased() }).contains(guess) && !foundRhymes.contains(guess) {
            withAnimation { foundRhymes.append(guess) }
            wrongGuess = false
            if foundRhymes.count >= targetCount { gameComplete = true }
        } else {
            withAnimation { wrongGuess = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { wrongGuess = false }
        }
    }
}

struct SplitMix64 {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9e3779b97f4a7c15
        var z = state
        z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
        z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
        return z ^ (z >> 31)
    }
}

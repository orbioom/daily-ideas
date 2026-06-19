import SwiftUI

struct SolvedSheet: View {
    let entry: WordEntry
    let engine: MuddleEngine
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: "star.fill")
                .font(.system(size: 72))
                .foregroundStyle(.yellow)

            Text("Solved!")
                .font(.system(size: 40, weight: .black, design: .rounded))

            Text(entry.word)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(.purple)

            Text(entry.hint)
                .font(.headline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            HStack(spacing: 40) {
                VStack(spacing: 4) {
                    Text(engine.timeString()).font(.title.weight(.bold))
                    Text("Time").font(.caption).foregroundStyle(.secondary)
                }
                VStack(spacing: 4) {
                    Text("\(engine.hintsUsed)").font(.title.weight(.bold))
                    Text("Hints").font(.caption).foregroundStyle(.secondary)
                }
                VStack(spacing: 4) {
                    Text(entry.difficulty.label).font(.title.weight(.bold))
                    Text("Difficulty").font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding(24)
            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 20))

            Button(action: onDismiss) {
                Text("Continue")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.purple, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
    }
}

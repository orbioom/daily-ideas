import SwiftUI
import SwiftData

struct ArchiveView: View {
    @Query(sort: \DailyResult.timestamp, order: .reverse) private var results: [DailyResult]

    var body: some View {
        NavigationStack {
            Group {
                if results.isEmpty {
                    ContentUnavailableView("No History Yet", systemImage: "clock", description: Text("Solve your first daily puzzle to see it here."))
                } else {
                    List(results) { result in
                        ArchiveRow(result: result)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Archive")
        }
    }
}

struct ArchiveRow: View {
    let result: DailyResult
    private let dateFmt: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .none; return f
    }()

    var body: some View {
        HStack {
            Image(systemName: result.solved ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(result.solved ? .green : .red)
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text(result.word).fontWeight(.bold)
                Text(dateFmt.string(from: result.date)).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatTime(result.timeElapsed)).fontWeight(.medium)
                Text("\(result.hintsUsed) hints").font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatTime(_ t: TimeInterval) -> String {
        let m = Int(t)/60; let s = Int(t)%60
        return String(format: "%d:%02d", m, s)
    }
}

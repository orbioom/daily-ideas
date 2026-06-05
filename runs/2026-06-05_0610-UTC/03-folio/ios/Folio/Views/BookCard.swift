import SwiftUI

struct BookCard: View {
    let book: Book

    private static let dateFmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "EEE, MMM d"; return f
    }()

    var body: some View {
        HStack(spacing: 16) {
            ProgressArc(progress: book.progress)
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.system(.headline).weight(.semibold))
                    .foregroundStyle(Color.orbInk)
                    .lineLimit(2)
                Text(book.author)
                    .font(.caption)
                    .foregroundStyle(Color.orbText3)
                HStack(spacing: 10) {
                    label("p.\(book.currentPage)/\(book.totalPages)")
                    if let pace = book.pace {
                        label(String(format: "%.0f p/day", pace))
                    }
                }
                .padding(.top, 2)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                if book.isFinished {
                    Text("Finished")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.orbLive)
                } else if let finish = book.projectedFinish {
                    Text("FINISH").eyebrow()
                    Text(Self.dateFmt.string(from: finish))
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(Color.orbInk)
                    Text("~\(daysAway(finish))d left")
                        .font(.caption2).foregroundStyle(Color.orbText3)
                } else {
                    Text("Log a session\nto project")
                        .font(.caption2)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(Color.orbText3)
                }
            }
        }
        .padding(18)
        .glassCard()
    }

    private func label(_ s: String) -> some View {
        Text(s)
            .font(.system(.caption2, design: .monospaced))
            .foregroundStyle(Color.orbText2)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(Color.white.opacity(0.5), in: Capsule())
    }

    private func daysAway(_ d: Date) -> Int {
        max(0, Int(d.timeIntervalSinceNow / 86400) + 1)
    }
}

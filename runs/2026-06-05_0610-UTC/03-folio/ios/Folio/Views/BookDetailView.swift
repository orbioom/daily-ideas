import SwiftUI

struct BookDetailView: View {
    @ObservedObject var vm: LibraryViewModel
    let bookID: UUID
    @State private var page: Double = 0
    @Environment(\.dismiss) private var dismiss

    private var book: Book? { vm.books.first { $0.id == bookID } }

    var body: some View {
        ZStack {
            OrbMistBackground()
            if let book {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(book.author.uppercased()).eyebrow()
                            Text(book.title)
                                .font(.system(.largeTitle, design: .serif).weight(.semibold))
                                .foregroundStyle(Color.orbInk)
                        }
                        HStack(spacing: 20) {
                            ProgressArc(progress: book.progress, size: 92, lineWidth: 9)
                            VStack(alignment: .leading, spacing: 8) {
                                stat("On page", "\(book.currentPage) / \(book.totalPages)")
                                if let pace = book.pace {
                                    stat("Pace", String(format: "%.0f pages/day", pace))
                                }
                                if let finish = book.projectedFinish {
                                    stat("Projected finish", longDate(finish))
                                } else if book.isFinished {
                                    stat("Status", "Finished")
                                }
                            }
                            Spacer()
                        }
                        .padding(18).glassCard()

                        sessionsChart(book)

                        logCard(book)
                    }
                    .padding(20)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { page = Double(book?.currentPage ?? 0) }
    }

    private func stat(_ k: String, _ v: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(k.uppercased()).eyebrow()
            Text(v).font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(Color.orbInk)
        }
    }

    private func logCard(_ book: Book) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("LOG TODAY'S PAGE").eyebrow()
            HStack {
                Text("0").font(.caption2).foregroundStyle(Color.orbText3)
                Slider(value: $page, in: 0...Double(max(1, book.totalPages)), step: 1)
                    .tint(Color.orbLive)
                Text("\(book.totalPages)").font(.caption2).foregroundStyle(Color.orbText3)
            }
            HStack {
                Text("Page \(Int(page))")
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                    .foregroundStyle(Color.orbInk)
                Spacer()
                Button {
                    vm.logProgress(book, page: Int(page))
                } label: {
                    Text("Save progress")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18).padding(.vertical, 11)
                        .background(LinearGradient(colors: [Color(red:0.227,green:0.243,blue:0.298),
                                                            Color(red:0.137,green:0.149,blue:0.184)],
                                                   startPoint: .top, endPoint: .bottom),
                                    in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
        .padding(18).glassCard()
    }

    private func sessionsChart(_ book: Book) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PROGRESS").eyebrow()
            GeometryReader { geo in
                let s = book.sessions
                let w = geo.size.width, h = geo.size.height
                if s.count >= 2, let t0 = s.first?.date.timeIntervalSince1970,
                   let t1 = s.last?.date.timeIntervalSince1970, t1 > t0 {
                    let span = t1 - t0
                    let pts = s.map { sess -> CGPoint in
                        let x = CGFloat((sess.date.timeIntervalSince1970 - t0) / span) * w
                        let y = h - CGFloat(Double(sess.page) / Double(max(1, book.totalPages))) * h
                        return CGPoint(x: x, y: y)
                    }
                    ZStack {
                        Path { p in p.move(to: pts[0]); pts.dropFirst().forEach { p.addLine(to: $0) } }
                            .stroke(Color.orbInk, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        ForEach(pts.indices, id: \.self) { i in
                            Circle().fill(Color.orbLive).frame(width: 7, height: 7)
                                .position(pts[i])
                        }
                    }
                } else {
                    Text("Log two or more sessions to see your curve.")
                        .font(.caption).foregroundStyle(Color.orbText3)
                }
            }
            .frame(height: 110)
        }
        .padding(18).glassCard()
    }

    private func longDate(_ d: Date) -> String {
        let f = DateFormatter(); f.dateStyle = .medium; return f.string(from: d)
    }
}

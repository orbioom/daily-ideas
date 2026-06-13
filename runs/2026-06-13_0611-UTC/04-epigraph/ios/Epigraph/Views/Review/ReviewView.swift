import SwiftUI
import SwiftData

struct ReviewView: View {
    let batch: [Highlight]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var index = 0
    @State private var finished = false

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                if finished || batch.isEmpty {
                    finishView
                } else {
                    TabView(selection: $index) {
                        ForEach(batch.indices, id: \.self) { i in
                            cardView(batch[i]).tag(i).padding(.horizontal, 20)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    controls
                }
            }
        }
    }

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark").font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.ink).padding(10).background(Circle().fill(Theme.surface))
            }
            .accessibilityLabel("Close review")
            Spacer()
            if !batch.isEmpty && !finished {
                Text("\(index + 1) of \(batch.count)").font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.inkSoft).monospacedDigit()
            }
            Spacer()
            Image(systemName: "xmark").opacity(0).padding(10)
        }
        .padding(.horizontal, 16).padding(.top, 10)
    }

    private func cardView(_ h: Highlight) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Spacer(minLength: 20)
                QuoteView(text: h.text, size: 26)
                if let book = h.book {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(book.displayTitle).font(.system(size: 15, weight: .semibold, design: .serif))
                            .foregroundStyle(Theme.ink)
                        Text([book.author, h.location].filter { !$0.isEmpty }.joined(separator: " · "))
                            .font(.system(size: 13)).foregroundStyle(Theme.inkSoft)
                    }
                }
                if !h.note.isEmpty {
                    Text(h.note).font(.system(size: 15)).italic().foregroundStyle(Theme.inkSoft)
                        .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Theme.surfaceAlt))
                }
                if !h.tags.isEmpty {
                    FlowLayout(spacing: 6) {
                        ForEach(h.tags.sorted { $0.name < $1.name }) { ThemeChip(text: "#\($0.name)") }
                    }
                }
                Spacer(minLength: 20)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear { markSurfaced(h) }
    }

    private var controls: some View {
        HStack(spacing: 16) {
            Button {
                let h = batch[index]; h.isFavorite.toggle(); Haptics.tap()
            } label: {
                Image(systemName: batch[index].isFavorite ? "heart.fill" : "heart")
                    .font(.system(size: 22)).foregroundStyle(batch[index].isFavorite ? Theme.accent : Theme.inkSoft)
                    .frame(width: 60, height: 60).background(Circle().fill(Theme.surface))
            }
            .accessibilityLabel("Favorite this highlight")

            Button { advance() } label: {
                Text(index >= batch.count - 1 ? "Finish" : "Next")
                    .font(.system(size: 17, weight: .semibold)).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).frame(height: 60)
                    .background(RoundedRectangle(cornerRadius: 18).fill(Theme.accent))
            }
        }
        .padding(.horizontal, 20).padding(.bottom, 24).padding(.top, 8)
    }

    private var finishView: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "checkmark.seal.fill").font(.system(size: 60)).foregroundStyle(Theme.accent)
            Text("Review complete").font(Theme.serif(28, .bold)).foregroundStyle(Theme.ink)
            Text("You revisited \(batch.count) highlight\(batch.count == 1 ? "" : "s"). Streak: \(ReviewStreak.current) day\(ReviewStreak.current == 1 ? "" : "s").")
                .font(.system(size: 15)).foregroundStyle(Theme.inkSoft).multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            Spacer()
            Button { dismiss() } label: {
                Text("Done").font(.system(size: 17, weight: .semibold)).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Theme.accent))
            }.padding(.horizontal, 24).padding(.bottom, 24)
        }
    }

    private func advance() {
        if index >= batch.count - 1 {
            ReviewStreak.record()
            try? context.save()
            Haptics.success()
            withAnimation { finished = true }
        } else {
            withAnimation { index += 1 }
            Haptics.soft()
        }
    }

    private func markSurfaced(_ h: Highlight) {
        h.lastSurfaced = .now
        h.surfaceCount += 1
    }
}

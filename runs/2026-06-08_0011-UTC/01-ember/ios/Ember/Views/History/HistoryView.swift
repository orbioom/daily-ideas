import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Fast.start, order: .reverse) private var fasts: [Fast]

    private var completed: [Fast] { fasts.filter { $0.end != nil } }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if completed.isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "list.bullet.rectangle",
                                       title: "No fasts yet",
                                       message: "Finished fasts show up here with their stage, duration, and how they felt.")
                        Button("Load sample history") {
                            SampleData.loadFasts(into: context)
                            Haptics.success()
                        }
                        .buttonStyle(GlassButtonStyle())
                        .padding(.horizontal, 40)
                    }
                } else {
                    List {
                        ForEach(completed) { fast in
                            NavigationLink(value: fast.id) {
                                FastRow(fast: fast)
                            }
                            .listRowBackground(Color.clear)
                        }
                        .onDelete(perform: delete)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("History")
            .navigationDestination(for: UUID.self) { id in
                if let fast = fasts.first(where: { $0.id == id }) {
                    FastDetailView(fast: fast)
                } else {
                    EmptyStateView(icon: "questionmark", title: "Not found", message: "This fast no longer exists.")
                }
            }
        }
    }

    private func delete(_ offsets: IndexSet) {
        for i in offsets { context.delete(completed[i]) }
        try? context.save()
        Haptics.tap()
    }
}

struct FastRow: View {
    let fast: Fast
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(.ultraThinMaterial).frame(width: 46, height: 46)
                Image(systemName: fast.didReachGoal ? "flame.fill" : "flame")
                    .foregroundStyle(fast.didReachGoal ? Color(hex: 0xB5552F) : Brand.text3)
            }
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text("\(Format.hours(fast.elapsedSeconds / 3600)) h")
                        .font(Brand.mono(17, weight: .semibold))
                        .foregroundStyle(Brand.text)
                    Text(fast.planName)
                        .font(.caption)
                        .foregroundStyle(Brand.text3)
                }
                Text(Format.dayTime.string(from: fast.start))
                    .font(.footnote)
                    .foregroundStyle(Brand.text2)
            }
            Spacer()
            if fast.feeling > 0 {
                HStack(spacing: 1) {
                    ForEach(0..<fast.feeling, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(Color(hex: 0xE0884F))
                    }
                }
                .accessibilityLabel("\(fast.feeling) of 5")
            }
        }
        .padding(.vertical, 4)
    }
}

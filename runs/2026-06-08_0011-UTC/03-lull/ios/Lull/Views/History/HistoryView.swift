import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \BreathSession.date, order: .reverse) private var sessions: [BreathSession]

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if sessions.isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "clock.arrow.circlepath", title: "No sessions yet",
                                       message: "Your completed breathing sessions appear here.")
                        Button("Load sample sessions") {
                            SampleData.load(into: context); Haptics.success()
                        }
                        .buttonStyle(GlassButtonStyle()).padding(.horizontal, 40)
                    }
                } else {
                    List {
                        ForEach(sessions) { s in
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle().fill(.ultraThinMaterial).frame(width: 44, height: 44)
                                    Image(systemName: s.didFinish ? "checkmark" : "pause")
                                        .foregroundStyle(s.didFinish ? Brand.live : Brand.text3)
                                }
                                .accessibilityHidden(true)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(s.patternName).font(.headline).foregroundStyle(Brand.text)
                                    Text(Format.dayTime.string(from: s.date))
                                        .font(.footnote).foregroundStyle(Brand.text2)
                                }
                                Spacer()
                                Text(Format.minutes(s.minutes))
                                    .font(Brand.mono(15, weight: .semibold)).foregroundStyle(Brand.text)
                            }
                            .padding(.vertical, 4)
                            .listRowBackground(Color.clear)
                        }
                        .onDelete(perform: delete)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Sessions")
        }
    }

    private func delete(_ offsets: IndexSet) {
        for i in offsets { context.delete(sessions[i]) }
        try? context.save(); Haptics.tap()
    }
}

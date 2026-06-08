import SwiftUI

struct OnThisDayView: View {
    let entries: [JournalEntry]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if entries.isEmpty {
                    EmptyStateView(
                        icon: "clock.arrow.circlepath",
                        title: "Nothing yet",
                        message: "Entries from this date in past years will appear here as your journal grows."
                    )
                } else {
                    List {
                        ForEach(entries) { entry in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(entry.date, format: .dateTime.year())
                                        .font(Brand.mono(13, weight: .semibold))
                                        .foregroundStyle(Color.accentColor)
                                    Spacer()
                                    MoodGlyph(mood: entry.mood, size: 26)
                                }
                                Text(entry.displayTitle)
                                    .font(.headline)
                                    .foregroundStyle(Brand.text)
                                if !entry.preview.isEmpty {
                                    Text(entry.preview)
                                        .font(.subheadline)
                                        .foregroundStyle(Brand.text2)
                                        .lineLimit(4)
                                }
                            }
                            .padding(.vertical, 4)
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("On This Day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

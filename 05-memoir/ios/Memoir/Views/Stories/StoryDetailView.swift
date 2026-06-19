import SwiftUI
import SwiftData

struct StoryDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var entry: StoryEntry
    @State private var showEdit = false

    private static let bodyDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .none
        return f
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header badges
                HStack(spacing: 8) {
                    Label(entry.era.displayName, systemImage: "clock.arrow.circlepath")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(MemoirTheme.eraColor(entry.era).opacity(0.18))
                        .foregroundColor(MemoirTheme.eraColor(entry.era))
                        .clipShape(Capsule())

                    Label(entry.mood.displayName, systemImage: entry.mood.icon)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(MemoirTheme.moodColor(entry.mood).opacity(0.15))
                        .foregroundColor(MemoirTheme.moodColor(entry.mood))
                        .clipShape(Capsule())

                    Spacer()
                }

                // Title
                Text(entry.title)
                    .font(.system(.title2, design: .serif).weight(.bold))
                    .foregroundColor(MemoirTheme.inkBrown)
                    .fixedSize(horizontal: false, vertical: true)

                // Meta row
                HStack(spacing: 14) {
                    Label(Self.bodyDateFormatter.string(from: entry.createdDate), systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Label("\(entry.wordCount) words", systemImage: "text.word.spacing")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Inspiring prompt
                if !entry.promptText.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Writing Prompt")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(MemoirTheme.warmAmber)

                        HStack(alignment: .top, spacing: 12) {
                            Rectangle()
                                .fill(MemoirTheme.warmAmber)
                                .frame(width: 3)
                                .cornerRadius(2)

                            Text(entry.promptText)
                                .font(.system(.subheadline, design: .serif).italic())
                                .foregroundColor(MemoirTheme.inkBrown.opacity(0.8))
                                .fixedSize(horizontal: false, vertical: true)
                                .lineSpacing(3)
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(MemoirTheme.warmAmber.opacity(0.08))
                        )
                    }
                }

                Divider()
                    .background(MemoirTheme.warmAmber.opacity(0.3))

                // Body
                Text(entry.bodyText)
                    .font(.system(.body, design: .serif))
                    .foregroundColor(MemoirTheme.inkBrown)
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)

                // Tags
                if !entry.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(entry.tags, id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(MemoirTheme.inkBrown.opacity(0.08))
                                    .foregroundColor(MemoirTheme.inkBrown.opacity(0.7))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                // Modified date footer if different from created
                if !Calendar.current.isDate(entry.createdDate, inSameDayAs: entry.modifiedDate) {
                    Text("Last edited \(entry.modifiedDate.formatted(.dateTime.month(.abbreviated).day().year()))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(20)
        }
        .background(MemoirTheme.parchment.opacity(0.3).ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    entry.isFavorite.toggle()
                    try? modelContext.save()
                } label: {
                    Image(systemName: entry.isFavorite ? "star.fill" : "star")
                        .foregroundColor(MemoirTheme.warmAmber)
                }

                Button {
                    showEdit = true
                } label: {
                    Image(systemName: "pencil")
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            WriteEntryView(promptText: entry.promptText, existingEntry: entry)
        }
    }
}

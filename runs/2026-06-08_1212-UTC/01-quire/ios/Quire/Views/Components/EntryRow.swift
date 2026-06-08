import SwiftUI

struct EntryRow: View {
    let entry: JournalEntry

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            MoodGlyph(mood: entry.mood, size: 34)
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(entry.displayTitle)
                        .font(.headline)
                        .foregroundStyle(Brand.text)
                        .lineLimit(1)
                    if entry.pinned {
                        Image(systemName: "pin.fill")
                            .font(.caption2)
                            .foregroundStyle(Brand.text3)
                            .accessibilityHidden(true)
                    }
                    if entry.favorite {
                        Image(systemName: "heart.fill")
                            .font(.caption2)
                            .foregroundStyle(Color(hex: 0x9E5E7E))
                            .accessibilityHidden(true)
                    }
                }
                if !entry.preview.isEmpty {
                    Text(entry.preview)
                        .font(.subheadline)
                        .foregroundStyle(Brand.text2)
                        .lineLimit(2)
                }
                HStack(spacing: 8) {
                    Text(entry.date, format: .dateTime.hour().minute())
                        .font(Brand.mono(11))
                        .foregroundStyle(Brand.text3)
                    if !entry.tags.isEmpty {
                        ForEach(entry.tags.prefix(3).sorted(by: { $0.name < $1.name }), id: \.id) { t in
                            TagChip(name: t.name, colorHex: t.colorHex)
                        }
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        var parts = [entry.displayTitle]
        if let m = Mood(rawValue: entry.mood) { parts.append("mood \(m.label)") }
        parts.append(Format.shortDate.string(from: entry.date))
        if entry.pinned { parts.append("pinned") }
        return parts.joined(separator: ", ")
    }
}

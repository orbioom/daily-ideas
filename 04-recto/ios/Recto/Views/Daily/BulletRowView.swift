import SwiftUI

struct BulletRowView: View {
    let entry: BulletEntry
    let fontStyle: String
    let onToggleComplete: () -> Void
    let onToggleStar: () -> Void

    @State private var isPressed: Bool = false

    private var symbolColor: Color {
        switch entry.bulletTypeEnum {
        case .task: return RectoTheme.taskColor
        case .event: return RectoTheme.eventColor
        case .note: return RectoTheme.noteColor
        }
    }

    private var isStrikethrough: Bool {
        entry.statusEnum == .complete || entry.statusEnum == .irrelevant
    }

    private var isMigrated: Bool {
        entry.statusEnum == .migrated
    }

    private var textOpacity: Double {
        switch entry.statusEnum {
        case .complete, .irrelevant: return 0.45
        case .migrated: return 0.55
        case .open: return 1.0
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Bullet symbol tap area (tasks only)
            Button(action: {
                if entry.bulletTypeEnum == .task {
                    onToggleComplete()
                }
            }) {
                Text(entry.bulletSymbol)
                    .font(.system(size: 22, weight: .semibold, design: .serif))
                    .foregroundStyle(isStrikethrough ? symbolColor.opacity(0.4) : symbolColor)
                    .frame(width: 36, alignment: .leading)
                    .padding(.top, 1)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(entry.bulletTypeEnum != .task)

            // Entry text
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.text)
                    .font(.system(
                        size: 16,
                        weight: .regular,
                        design: fontStyle == "serif" ? .serif : .default
                    ))
                    .foregroundStyle(RectoTheme.inkPrimary.opacity(textOpacity))
                    .strikethrough(isStrikethrough, color: RectoTheme.inkSecondary.opacity(0.6))
                    .italic(isMigrated)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)

                if entry.isStarred {
                    Text("Starred")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(RectoTheme.starColor.opacity(0.8))
                }
            }
            .padding(.top, 2)

            Spacer(minLength: 8)

            // Star button
            Button(action: onToggleStar) {
                Image(systemName: entry.isStarred ? "star.fill" : "star")
                    .font(.system(size: 16))
                    .foregroundStyle(
                        entry.isStarred
                        ? RectoTheme.starColor
                        : Color(red: 0.75, green: 0.73, blue: 0.70)
                    )
                    .contentShape(Rectangle())
                    .padding(4)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            entry.isStarred
            ? RectoTheme.starColor.opacity(0.06)
            : Color.clear
        )
    }
}

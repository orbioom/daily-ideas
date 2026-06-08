import SwiftUI

struct CareTaskRow: View {
    let task: CareTask
    let onDone: () -> Void

    private var accentColor: Color {
        switch task.status {
        case .overdue:  return Brand.danger
        case .dueToday: return Brand.warn
        case .dueSoon:  return Brand.warn
        case .ok:       return Brand.live
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Plant symbol
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(hex: task.plant.colorHex).opacity(0.18))
                    .frame(width: 44, height: 44)
                Image(systemName: task.plant.symbol)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color(hex: task.plant.colorHex))
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(task.plant.nickname)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Brand.text)

                HStack(spacing: 6) {
                    Image(systemName: task.type.symbol)
                        .font(.caption2)
                        .foregroundStyle(task.type.color)
                        .accessibilityHidden(true)
                    Text(Format.relativeDue(from: task.due))
                        .font(.caption)
                        .foregroundStyle(accentColor)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(task.plant.nickname), \(task.type.actionLabel), \(Format.relativeDue(from: task.due))")

            Spacer()

            Button(action: onDone) {
                HStack(spacing: 4) {
                    Image(systemName: task.type.symbol)
                        .font(.caption.weight(.semibold))
                    Text("Done")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(accentColor, in: Capsule())
            }
            .accessibilityLabel("Mark \(task.plant.nickname) \(task.type.actionLabel) done")
            .accessibilityHint("Logs a care event and updates next due date")
        }
        .padding(.vertical, 4)
    }
}

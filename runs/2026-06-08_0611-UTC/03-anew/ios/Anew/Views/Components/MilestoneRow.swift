import SwiftUI

struct MilestoneRow: View {
    let status: MilestoneStatus
    var quitName: String? = nil

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(status.achieved ? Brand.live.opacity(0.18) : Brand.text3.opacity(0.1))
                    .frame(width: 44, height: 44)

                Image(systemName: status.milestone.symbol)
                    .font(.system(size: 20))
                    .foregroundStyle(status.achieved ? Brand.live : Brand.text3)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(status.milestone.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Brand.text)

                    if let name = quitName {
                        Text("· \(name)")
                            .font(.caption)
                            .foregroundStyle(Brand.text3)
                    }
                }

                Text("\(status.milestone.days) day\(status.milestone.days == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(Brand.text2)
            }

            Spacer()

            if status.achieved {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Brand.live)
                    .accessibilityHidden(true)
            } else {
                RingProgress(progress: status.progress, size: 32, lineWidth: 3)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(milestoneAccessibilityLabel)
        .accessibilityValue(status.achieved ? "Achieved" : "\(Int(status.progress * 100)) percent complete")
    }

    private var milestoneAccessibilityLabel: String {
        let base = status.milestone.title
        if let name = quitName {
            return "\(base) for \(name)"
        }
        return base
    }
}

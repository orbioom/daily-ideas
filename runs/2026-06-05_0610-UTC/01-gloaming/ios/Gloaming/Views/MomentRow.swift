import SwiftUI

struct MomentRow: View {
    let moment: SunMoment
    let isCurrent: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: moment.symbol)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(moment.tint)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 1) {
                Text(moment.name)
                    .font(.system(.subheadline).weight(.semibold))
                    .foregroundStyle(Color.orbInk)
                Text(moment.subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.orbText3)
            }
            Spacer()
            if isCurrent {
                Circle().fill(Color.orbLive)
                    .frame(width: 7, height: 7)
                    .shadow(color: Color.orbLive.opacity(0.6), radius: 4)
            }
            Text(moment.timeString)
                .font(.system(.callout, design: .monospaced).weight(.medium))
                .foregroundStyle(Color.orbText2)
        }
        .padding(.vertical, 9)
        .opacity(moment.date == nil ? 0.4 : 1)
    }
}

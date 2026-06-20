import SwiftUI

struct RunCard: View {
    let session: RunSession
    let useKm: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(PaceTheme.accent.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: session.activityType.systemImage)
                    .font(.title3)
                    .foregroundStyle(PaceTheme.accent)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(session.date, style: .date)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                HStack(spacing: 6) {
                    Text(session.distanceFormatted(useKm: useKm))
                    Text("·")
                        .foregroundStyle(.secondary)
                    Text(session.durationFormatted)
                    Text("·")
                        .foregroundStyle(.secondary)
                    Text("\(session.paceFormatted(useKm: useKm))/\(useKm ? "km" : "mi")")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

#Preview {
    let session = RunSession(activityType: .run)
    session.distanceMeters = 5200
    session.duration = 1620
    return RunCard(session: session, useKm: true)
        .padding()
}

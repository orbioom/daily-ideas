import SwiftUI

struct ApplicationRow: View {
    let application: Application

    var body: some View {
        HStack(spacing: 12) {
            // Company monogram
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(application.status.color.opacity(0.16))
                Text(monogram)
                    .font(Theme.rounded(18, .bold))
                    .foregroundStyle(application.status.color)
            }
            .frame(width: 46, height: 46)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(application.role)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                Text(application.company)
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Label(application.workMode.label, systemImage: application.workMode.symbol)
                        .font(Theme.rounded(11, .medium))
                        .foregroundStyle(Theme.inkFaint)
                    if application.priority == .high {
                        Label("High", systemImage: application.priority.symbol)
                            .font(Theme.rounded(11, .medium))
                            .foregroundStyle(application.priority.color)
                    }
                    if let salary = Format.salaryRange(min: application.salaryMin, max: application.salaryMax, currencyCode: application.currencyCode) {
                        Text(salary)
                            .font(Theme.rounded(11, .medium))
                            .foregroundStyle(Theme.inkFaint)
                            .lineLimit(1)
                    }
                }
            }
            Spacer(minLength: 6)
            VStack(alignment: .trailing, spacing: 6) {
                StatusBadge(status: application.status, compact: true)
                ExcitementStars(value: application.excitement)
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(application.role) at \(application.company)")
        .accessibilityValue("\(application.status.label), excitement \(application.excitement) of 5")
        .accessibilityHint("Opens details")
    }

    private var monogram: String {
        let trimmed = application.company.trimmingCharacters(in: .whitespaces)
        guard let first = trimmed.first else { return "?" }
        return String(first).uppercased()
    }
}

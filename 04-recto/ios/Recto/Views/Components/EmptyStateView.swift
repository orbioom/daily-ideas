import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 52, weight: .ultraLight))
                .foregroundStyle(Color(red: 0.70, green: 0.67, blue: 0.63))

            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                    .foregroundStyle(Color(red: 0.30, green: 0.28, blue: 0.26))

                Text(subtitle)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color(red: 0.55, green: 0.52, blue: 0.48))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 48)
                    .lineSpacing(3)
            }

            if let title = actionTitle, let action = action {
                Button(action: action) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Color(red: 0.20, green: 0.20, blue: 0.20))
                        .clipShape(Capsule())
                }
                .padding(.top, 4)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

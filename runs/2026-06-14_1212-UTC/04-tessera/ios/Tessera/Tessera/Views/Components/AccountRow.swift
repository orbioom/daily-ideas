import SwiftUI

/// One row in the Codes list. Renders the live code, a countdown ring (TOTP) or a
/// refresh button (HOTP), the favorite pin, and supports tap-to-copy.
struct AccountRow: View {
    let account: Account
    /// The "now" that drives this render (passed down from the list's TimelineView).
    let now: Date
    /// Whether codes are hidden until tapped (per settings) and this row is hidden.
    let masked: Bool
    let onCopy: () -> Void
    let onToggleFavorite: () -> Void
    let onAdvanceHOTP: () -> Void
    let onReveal: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: Derived OTP values

    private var code: String? {
        guard let secret = account.decodedSecret else { return nil }
        switch account.type {
        case .totp:
            return OTPGenerator.totp(secret: secret,
                                     digits: account.digits,
                                     period: account.period,
                                     algorithm: account.algorithm,
                                     at: now)
        case .hotp:
            return OTPGenerator.hotp(secret: secret,
                                     counter: account.counter,
                                     digits: account.digits,
                                     algorithm: account.algorithm)
        }
    }

    private var displayCode: String {
        guard let code else { return "Invalid" }
        if masked { return maskedString(length: code.count) }
        return OTPGenerator.grouped(code)
    }

    private func maskedString(length: Int) -> String {
        let n = max(length, 6)
        // Render "••• •••" style to echo the grouped layout.
        let dots = String(repeating: "•", count: n)
        return OTPGenerator.grouped(dots)
    }

    private var secondsRemaining: Int {
        OTPGenerator.secondsRemaining(unixTime: now.timeIntervalSince1970, period: account.period)
    }

    private var progress: Double {
        OTPGenerator.progress(unixTime: now.timeIntervalSince1970, period: account.period)
    }

    private var codeIsValid: Bool { code != nil }

    var body: some View {
        HStack(spacing: 12) {
            avatar
            VStack(alignment: .leading, spacing: 3) {
                Text(account.displayTitle)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                if !account.displaySubtitle.isEmpty {
                    Text(account.displaySubtitle)
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                        .lineLimit(1)
                }
                Text(displayCode)
                    .font(Theme.mono(24, .semibold))
                    .foregroundStyle(codeIsValid ? Theme.accent : Theme.bad)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .contentTransition(reduceMotion ? .identity : .numericText())
                    .animation(reduceMotion ? nil : .default, value: displayCode)
                    .padding(.top, 1)
            }
            Spacer(minLength: 6)
            trailingControl
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            if masked { onReveal() } else { onCopy() }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityHint(masked ? "Double tap to reveal" : "Double tap to copy the code")
    }

    private var avatar: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(Theme.accountColor(hue: account.colorHue).opacity(0.22))
            Text(account.monogram)
                .font(Theme.rounded(18, .bold))
                .foregroundStyle(Theme.accountColor(hue: account.colorHue))
        }
        .frame(width: 44, height: 44)
        .overlay(alignment: .topTrailing) {
            if account.favorite {
                Image(systemName: "star.fill")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Theme.warn)
                    .padding(3)
                    .background(Circle().fill(Theme.surface))
                    .offset(x: 4, y: -4)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var trailingControl: some View {
        VStack(spacing: 6) {
            Button(action: onToggleFavorite) {
                Image(systemName: account.favorite ? "star.fill" : "star")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(account.favorite ? Theme.warn : Theme.inkFaint)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(account.favorite ? "Unpin favorite" : "Pin as favorite")

            switch account.type {
            case .totp:
                CountdownRing(progress: progress, secondsRemaining: secondsRemaining)
            case .hotp:
                Button(action: onAdvanceHOTP) {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .font(.system(size: 30, weight: .regular))
                        .foregroundStyle(Theme.accent)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Generate next code")
            }
        }
    }

    private var accessibilityText: String {
        let title = account.displaySubtitle.isEmpty
            ? account.displayTitle
            : "\(account.displayTitle), \(account.displaySubtitle)"
        if masked { return "\(title), code hidden" }
        guard let code else { return "\(title), code unavailable, secret invalid" }
        let spelled = code.map { String($0) }.joined(separator: " ")
        if account.type == .totp {
            return "\(title), code \(spelled), refreshes in \(secondsRemaining) seconds"
        }
        return "\(title), code \(spelled), counter based"
    }
}

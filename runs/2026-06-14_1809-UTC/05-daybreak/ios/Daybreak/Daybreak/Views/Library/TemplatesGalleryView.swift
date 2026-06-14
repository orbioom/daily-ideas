import SwiftUI

/// Gallery of ready-made routine templates. Pro templates are marked with a crown.
struct TemplatesGalleryView: View {
    let onCreate: (RoutineTemplate) -> Void

    @Environment(\.dismiss) private var dismiss
    @AppStorage("isPro") private var isPro = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(RoutineTemplates.all) { template in
                        card(template)
                    }
                }
                .padding(18)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
            }
        }
    }

    private func card(_ template: RoutineTemplate) -> some View {
        let accent = Color(hex: parseHex(template.colorHex))
        let locked = template.isPro && !isPro
        return Button {
            onCreate(template)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .fill(accent.opacity(0.18))
                            .frame(width: 48, height: 48)
                        Image(systemName: template.iconName)
                            .font(.system(size: 21, weight: .semibold))
                            .foregroundStyle(accent)
                            .accessibilityHidden(true)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(template.name)
                                .font(Theme.rounded(17, .semibold))
                                .foregroundStyle(Theme.ink)
                            if template.isPro {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Theme.accent)
                                    .accessibilityLabel("Pro template")
                            }
                        }
                        Text("\(template.stepCount) steps · \(TimeFormat.minutesLabel(template.estimatedMinutes)) · \(template.timeOfDay.label)")
                            .font(Theme.rounded(12))
                            .foregroundStyle(Theme.inkSoft)
                    }
                    Spacer()
                    Image(systemName: locked ? "lock.fill" : "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(locked ? Theme.inkFaint : Theme.accent)
                        .accessibilityHidden(true)
                }
                Text(template.blurb)
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.surface))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint(locked ? "Pro template, unlocks with Daybreak Pro" : "Adds this routine")
    }
}

import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private let pages: [(icon: String, title: String, body: String)] = [
        ("tray.full.fill", "Your search, in one place",
         "Every application with its stage, contacts, interviews, and follow-ups. No spreadsheet, no $13-a-week web tool — a fast, native pipeline that lives on your phone."),
        ("calendar.badge.clock", "Never drop a thread",
         "Hired surfaces what's next: tomorrow's interviews, follow-ups coming due, and applications going quiet so you can nudge before they ghost."),
        ("chart.bar.fill", "Learn what's working",
         "A real funnel — applied → screening → interview → offer — plus response rate and time-to-reply, so you fix the step that's actually leaking."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { i in
                    VStack(spacing: 20) {
                        Image(systemName: pages[i].icon)
                            .font(.system(size: 60))
                            .foregroundStyle(Theme.blue)
                            .accessibilityHidden(true)
                        Text(pages[i].title)
                            .font(Theme.display(30))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Theme.ink(scheme))
                        Text(pages[i].body)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Theme.inkSoft(scheme))
                            .padding(.horizontal, 28)
                    }
                    .tag(i)
                    .padding(.bottom, 40)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button {
                if page < pages.count - 1 {
                    if reduceMotion { page += 1 }
                    else { withAnimation { page += 1 } }
                } else {
                    Haptics.success()
                    hasOnboarded = true
                }
            } label: {
                Text(page < pages.count - 1 ? "Continue" : "Start tracking")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.blue)
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
        .background(Theme.background(scheme))
    }
}

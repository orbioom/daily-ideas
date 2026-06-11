import SwiftUI

struct TermOnboardingView: View {
    @Binding var isComplete: Bool
    @State private var page = 0

    private let pages: [(image: String, title: String, body: String)] = [
        ("graduationcap.fill", "Welcome to Term", "Your all-in-one academic planner for grades, schedules, and assignments."),
        ("calendar.badge.clock", "Never Miss a Deadline", "Agenda view shows today's classes and every upcoming assignment at a glance."),
        ("chart.line.uptrend.xyaxis", "Track Your GPA", "Weighted grade calculations and a what-if GPA tool help you plan for success."),
        ("square.stack.3d.up.fill", "Organize by Term", "Add courses each semester, set grading weights, and keep every term archived.")
    ]

    var body: some View {
        ZStack {
            TermTheme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { i in
                        PageCard(item: pages[i]).tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxHeight: .infinity)

                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { i in
                        Capsule()
                            .fill(i == page ? TermTheme.accent : TermTheme.subtle.opacity(0.4))
                            .frame(width: i == page ? 20 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: page)
                    }
                }
                .padding(.bottom, 24)

                Button(action: advance) {
                    Text(page == pages.count - 1 ? "Get Started" : "Continue")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(TermTheme.accent, in: RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .accessibilityLabel(page == pages.count - 1 ? "Get started with Term" : "Continue to next page")
            }
        }
    }

    private func advance() {
        if page < pages.count - 1 {
            withAnimation { page += 1 }
        } else {
            isComplete = true
        }
    }
}

private struct PageCard: View {
    let item: (image: String, title: String, body: String)

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: item.image)
                .font(.system(size: 72, weight: .light))
                .foregroundStyle(TermTheme.accent)
                .accessibilityHidden(true)
            VStack(spacing: 12) {
                Text(item.title)
                    .font(.title.bold())
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                Text(item.body)
                    .font(.body)
                    .foregroundStyle(TermTheme.subtle)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            Spacer()
        }
        .padding()
    }
}

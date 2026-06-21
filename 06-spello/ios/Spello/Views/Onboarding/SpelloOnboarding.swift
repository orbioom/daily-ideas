import SwiftUI
import SwiftData

struct SpelloOnboarding: View {
    @Environment(\.modelContext) private var ctx
    @Query private var prefs: [SpelloPrefs]
    @State private var page = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.55, green: 0.22, blue: 0.05), Color(red: 0.35, green: 0.12, blue: 0.02)],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            TabView(selection: $page) {
                slide(icon: "abc", title: "Spello",
                      sub: "Kids Spelling Trainer",
                      body: "Fun, grade-level spelling practice for kids from Grade 1 to Grade 5. No internet needed!",
                      next: { withAnimation { page = 1 } }).tag(0)

                slide(icon: "speaker.wave.2.fill", title: "Three Modes",
                      sub: "Practice Your Way",
                      body: "Multiple Choice: Pick the right word.\nType It: Spell it yourself.\nListen & Spell: Hear it, then type it!",
                      next: { withAnimation { page = 2 } }).tag(1)

                slide(icon: "person.2.fill", title: "Multi-Child",
                      sub: "Up to 5 Profiles",
                      body: "Create a profile for each child. Track progress separately and celebrate every improvement!",
                      next: finish).tag(2)
            }
            .tabViewStyle(.page)
        }
    }

    private func slide(icon: String, title: String, sub: String, body: String, next: @escaping () -> Void) -> some View {
        let accent = Color(red: 0.95, green: 0.55, blue: 0.15)
        return VStack(spacing: 28) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 72))
                .foregroundStyle(accent)
                .shadow(color: accent.opacity(0.5), radius: 20)
            VStack(spacing: 8) {
                Text(title).font(.system(size: 40, weight: .black)).foregroundStyle(.white)
                Text(sub).font(.title3.weight(.semibold)).foregroundStyle(accent)
            }
            Text(body)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.white.opacity(0.85))
                .padding(.horizontal, 8)
            Spacer()
            Button(action: next) {
                Text(page == 2 ? "Start Learning!" : "Next")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 32)
            Spacer().frame(height: 40)
        }
        .padding(.horizontal, 32)
    }

    private func finish() {
        let p = prefs.first ?? SpelloPrefs()
        if prefs.isEmpty { ctx.insert(p) }
        p.onboardingDone = true
    }
}

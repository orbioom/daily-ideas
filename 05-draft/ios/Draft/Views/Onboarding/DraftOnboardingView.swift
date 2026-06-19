import SwiftUI

struct DraftOnboardingView: View {
    @AppStorage("draftHasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var page = 0

    private let pages: [(title: String, body: String, symbol: String)] = [
        ("Plan Your Story", "Organize your novel from idea to final draft. Create projects, track chapters, and build your world.", "books.vertical.fill"),
        ("Know Your Characters", "Build deep character profiles with roles, motivations, arcs, and personality traits.", "person.3.fill"),
        ("Structure Your Plot", "Choose from proven story templates — Three-Act, Hero's Journey, Save the Cat — or build your own.", "map.fill")
    ]

    var body: some View {
        ZStack {
            Color(red: 0.10, green: 0.07, blue: 0.03).ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        VStack(spacing: 32) {
                            Spacer()
                            Image(systemName: pages[i].symbol)
                                .font(.system(size: 76))
                                .foregroundStyle(Color(red: 0.9, green: 0.65, blue: 0.2))

                            VStack(spacing: 12) {
                                Text(pages[i].title)
                                    .font(.system(size: 28, weight: .bold, design: .serif))
                                    .foregroundStyle(.white)

                                Text(pages[i].body)
                                    .font(.system(size: 16, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 36)
                            }
                            Spacer()
                        }
                        .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(height: 460)

                Button(action: {
                    if page < pages.count - 1 { withAnimation { page += 1 } }
                    else { hasSeenOnboarding = true }
                }) {
                    Text(page < pages.count - 1 ? "Next" : "Start Writing")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(red: 0.85, green: 0.58, blue: 0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }
}

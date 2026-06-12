import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @State private var page = 0

    private let pages: [(icon: String, title: String, body: String)] = [
        (
            "doc.text.fill",
            "Vitae",
            "A resume builder that respects you: no account, no upload, and no $29.95-a-month 'trial' waiting to bite. Write on your iPhone; export a typeset PDF."
        ),
        (
            "square.grid.2x2.fill",
            "Three Honest Templates",
            "Classic serif, confident Banner, and a dense Compact for one-pagers. Swap templates and accent colors any time — your content never reflows into chaos."
        ),
        (
            "square.and.arrow.up.fill",
            "Real Multi-Page PDF",
            "US Letter or A4, paginated properly, named after you. Plus a built-in guide with the bullet-writing rules recruiters actually reward."
        ),
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.10, green: 0.16, blue: 0.32), Color(red: 0.05, green: 0.08, blue: 0.17)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        VStack(spacing: 20) {
                            Image(systemName: pages[index].icon)
                                .font(.system(size: 56))
                                .foregroundStyle(Color(red: 0.55, green: 0.72, blue: 1.0))
                                .accessibilityHidden(true)
                            Text(pages[index].title)
                                .font(.largeTitle.weight(.bold))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.white)
                            Text(pages[index].body)
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.white.opacity(0.82))
                                .padding(.horizontal, 30)
                        }
                        .tag(index)
                        .padding(.bottom, 40)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                Button {
                    Haptics.tap()
                    if page < pages.count - 1 {
                        withAnimation { page += 1 }
                    } else {
                        hasOnboarded = true
                    }
                } label: {
                    Text(page < pages.count - 1 ? "Continue" : "Build My Resume")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .tint(.white)
                .foregroundStyle(Color(red: 0.10, green: 0.16, blue: 0.32))
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
            }
        }
    }
}

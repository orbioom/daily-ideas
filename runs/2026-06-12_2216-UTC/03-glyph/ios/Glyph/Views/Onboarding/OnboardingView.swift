import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @State private var page = 0

    private let pages: [(icon: String, title: String, body: String)] = [
        (
            "qrcode",
            "Glyph",
            "Create and scan QR codes on your iPhone — with no subscription, no expiring links, and no server in the middle. A QR code is just data; you shouldn't rent it weekly."
        ),
        (
            "paintpalette.fill",
            "Codes Worth Printing",
            "Links, Wi-Fi logins, contact cards, email, SMS, phone numbers. Pick module and background colors, set the error-correction level, and export a crisp 1024-pixel PNG."
        ),
        (
            "lock.shield.fill",
            "Private by Construction",
            "Generation and scanning run entirely on-device with CoreImage and Vision. Your library and history live in local storage. Nothing is uploaded — there is nothing to upload to."
        ),
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.09, green: 0.10, blue: 0.13), Color(red: 0.04, green: 0.05, blue: 0.06)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        VStack(spacing: 20) {
                            Image(systemName: pages[index].icon)
                                .font(.system(size: 56))
                                .foregroundStyle(GlyphTheme.mint)
                                .accessibilityHidden(true)
                            Text(pages[index].title)
                                .font(.largeTitle.weight(.bold))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.white)
                            Text(pages[index].body)
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.white.opacity(0.8))
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
                    Text(page < pages.count - 1 ? "Continue" : "Start Creating")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .tint(GlyphTheme.mint)
                .foregroundStyle(.black)
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
            }
        }
    }
}

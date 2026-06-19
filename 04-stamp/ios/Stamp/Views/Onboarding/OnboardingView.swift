import SwiftUI
import SwiftData

struct StampOnboardingView: View {
    @Environment(\.modelContext) private var context
    @Query private var allPrefs: [StampPrefs]
    @State private var page = 0

    private var prefs: StampPrefs {
        if let p = allPrefs.first { return p }
        let p = StampPrefs(); context.insert(p); return p
    }

    var body: some View {
        TabView(selection: $page) {
            StampOnboardingPage(icon: "photo.badge.plus", color: .purple, title: "Import Any Photo", body: "Pick any image from your library to turn into a sticker with one tap.")
                .tag(0)
            StampOnboardingPage(icon: "wand.and.stars", color: .pink, title: "Auto Background Removal", body: "Stamp automatically removes the background so your subject pops out cleanly.")
                .tag(1)
            StampOnboardingPage(icon: "square.and.arrow.up", color: .blue, title: "Export & Share", body: "Save your sticker to Photos or share it anywhere — Messages, Instagram, WhatsApp.")
                .tag(2)
            VStack(spacing: 32) {
                Image(systemName: "star.fill").font(.system(size: 64)).foregroundStyle(.yellow)
                VStack(spacing: 12) {
                    Text("Make Your First Sticker").font(.title.bold())
                    Text("Customize the border, shadow, and background to make it uniquely yours.").font(.body).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal, 32)
                }
                Button {
                    prefs.hasSeenOnboarding = true
                } label: {
                    Text("Let's Go!")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal, 32)
                }
            }
            .tag(3)
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }
}

private struct StampOnboardingPage: View {
    let icon: String; let color: Color; let title: String; let body: String
    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: icon).font(.system(size: 64)).foregroundStyle(color)
            VStack(spacing: 12) {
                Text(title).font(.title.bold())
                Text(body).font(.body).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal, 32)
            }
        }.padding()
    }
}

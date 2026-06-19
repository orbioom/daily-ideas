import SwiftUI
import SwiftData

struct SpriteOnboardingView: View {
    @Environment(\.modelContext) private var context
    @Query private var allPrefs: [SpritePrefs]
    @State private var page = 0

    private var prefs: SpritePrefs {
        if let p = allPrefs.first { return p }
        let p = SpritePrefs(); context.insert(p); return p
    }

    var body: some View {
        TabView(selection: $page) {
            SpriteOnboardingPage(icon: "grid", color: .indigo, title: "Pixel Art Studio", body: "Create retro-style pixel art on a 16×16 or 32×32 grid. Perfect for icons, characters, and game assets.")
                .tag(0)
            SpriteOnboardingPage(icon: "paintbrush.fill", color: .orange, title: "Powerful Tools", body: "Draw, erase, flood-fill, and eyedrop colors. Unlimited undo/redo keeps your creative flow moving.")
                .tag(1)
            SpriteOnboardingPage(icon: "square.and.arrow.up", color: .green, title: "Export Anywhere", body: "Export your art as a crisp PNG — scaled up to any size for sharing on social media or use in projects.")
                .tag(2)
            VStack(spacing: 32) {
                Image(systemName: "sparkles").font(.system(size: 64)).foregroundStyle(.yellow)
                VStack(spacing: 12) {
                    Text("Start Creating!").font(.title.bold())
                    Text("Your artwork is saved automatically as you draw.").font(.body).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal, 32)
                }
                Button { prefs.hasSeenOnboarding = true } label: {
                    Text("Open Studio")
                        .font(.headline).frame(maxWidth: .infinity).padding()
                        .background(Color.indigo).foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14)).padding(.horizontal, 32)
                }
            }
            .tag(3)
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }
}

private struct SpriteOnboardingPage: View {
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

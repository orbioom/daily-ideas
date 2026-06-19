import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Query private var prefs: [StipplePrefs]
    @Environment(\.modelContext) private var ctx
    @State private var page = 0

    var body: some View {
        ZStack {
            Color("CanvasBG").ignoresSafeArea()
            VStack {
                TabView(selection: $page) {
                    ob0.tag(0)
                    ob1.tag(1)
                    ob2.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(i == page ? Color("StippleAccent") : Color(.systemGray4))
                            .frame(width: 8, height: 8)
                            .animation(.spring(), value: page)
                    }
                }

                Button(page < 2 ? "Next" : "Start Coloring") {
                    if page < 2 { withAnimation { page += 1 } } else { finish() }
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color("StippleAccent"))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
            }
        }
    }

    private var ob0: some View {
        VStack(spacing: 20) {
            Text("🎨").font(.system(size: 72))
            Text("Stipple").font(.system(size: 38, weight: .bold))
            Text("Color by Number").font(.title2).foregroundStyle(.secondary)
            Text("Relaxing pixel art coloring with zero energy limits, zero ads, and zero timers.")
                .font(.body).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal, 32)
        }
    }

    private var ob1: some View {
        VStack(spacing: 20) {
            Text("How to Color").font(.title2.bold())
            VStack(alignment: .leading, spacing: 14) {
                obStep("1", "Pick a color from the palette at the bottom")
                obStep("2", "Tap any cell to fill it with that color")
                obStep("3", "Pinch to zoom in on small details")
                obStep("4", "Turn on Auto-Fill to flood entire regions")
            }
            .padding(.horizontal, 28)
        }
    }

    private var ob2: some View {
        VStack(spacing: 20) {
            Text("✨").font(.system(size: 72))
            Text("No Limits").font(.title2.bold())
            Text("15 unique scenes spanning nature, animals, food, and holidays. More with Stipple Pro. No energy. No timers. Just pure coloring.")
                .font(.body).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal, 32)
        }
    }

    private func obStep(_ n: String, _ label: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(n)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Color("StippleAccent"))
                .clipShape(Circle())
            Text(label).font(.body)
        }
    }

    private func finish() {
        if let p = prefs.first { p.hasSeenOnboarding = true }
        else { let p = StipplePrefs(); p.hasSeenOnboarding = true; ctx.insert(p) }
    }
}

import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("sprout.onboarded") private var onboarded = false
    @State private var page = 0

    private let pages: [(icon: String, title: String, body: String)] = [
        ("sprout", "Chores that actually get done",
         "Sprout gives each child a clear daily board they can check off themselves — and you approve."),
        ("dollarsign.circle.fill", "Allowance, the easy way",
         "Attach a reward to any chore, set a weekly allowance, and Sprout keeps every child's balance straight."),
        ("hand.raised.fill", "Private by design",
         "No debit cards, no bank logins, no ads. Everything stays on your family's device.")
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { i in
                    VStack(spacing: 22) {
                        Spacer()
                        Image(systemName: pages[i].icon == "sprout" ? "leaf.fill" : pages[i].icon)
                            .font(.system(size: 66, weight: .light))
                            .foregroundStyle(Brand.magic).accessibilityHidden(true)
                        Text(pages[i].title).font(.title.weight(.bold))
                            .foregroundStyle(Brand.text).multilineTextAlignment(.center)
                        Text(pages[i].body).font(.body)
                            .foregroundStyle(Brand.text2).multilineTextAlignment(.center)
                            .padding(.horizontal, 12)
                        Spacer()
                    }
                    .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            VStack(spacing: 12) {
                Button(page == pages.count - 1 ? "Set up my family" : "Continue") {
                    if page == pages.count - 1 { Haptics.success(); onboarded = true }
                    else { withAnimation(Brand.ease()) { page += 1 } }
                }
                .buttonStyle(InkButtonStyle())
                if page == pages.count - 1 {
                    Button("Explore with a sample family") {
                        SeedData.loadSample(context); Haptics.success(); onboarded = true
                    }
                    .buttonStyle(GlassButtonStyle())
                }
                HStack(spacing: 7) {
                    ForEach(pages.indices, id: \.self) { i in
                        Circle().fill(i == page ? Brand.text : Brand.text3.opacity(0.4))
                            .frame(width: 7, height: 7)
                    }
                }
                .accessibilityHidden(true)
            }
        }
        .padding(24)
    }
}

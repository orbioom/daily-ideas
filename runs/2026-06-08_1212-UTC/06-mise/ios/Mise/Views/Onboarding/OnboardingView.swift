import SwiftUI
import SwiftData

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var page = 0
    @State private var includeSample = true
    @State private var bob = false

    private let pages: [(symbol: String, title: String, body: String)] = [
        ("book.pages.fill", "Your recipes, your way",
         "Keep every recipe with ingredients and steps. Scale servings up or down and the amounts adjust instantly."),
        ("calendar", "Plan the week",
         "Drop recipes onto days and meals. A calm weekly view of what you're actually cooking."),
        ("cart.fill", "One tap to a shopping list",
         "Generate a grocery list straight from your plan — same ingredients across recipes are added up for you. Unlike the others, here they actually talk."),
    ]

    var body: some View {
        ZStack {
            Brand.pageBackground
            VStack(spacing: 0) {
                Spacer()
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { i in
                        VStack(spacing: 24) {
                            ZStack {
                                Circle().fill(.ultraThinMaterial).frame(width: 150, height: 150)
                                    .overlay(Circle().strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: 1))
                                Image(systemName: pages[i].symbol)
                                    .font(.system(size: 52, weight: .light))
                                    .foregroundStyle(Color.accentColor)
                                    .offset(y: bob && !reduceMotion ? -5 : 5)
                                    .accessibilityHidden(true)
                            }
                            VStack(spacing: 12) {
                                Text(pages[i].title).font(.title.weight(.bold))
                                    .foregroundStyle(Brand.text).multilineTextAlignment(.center)
                                Text(pages[i].body).font(.body).foregroundStyle(Brand.text2)
                                    .multilineTextAlignment(.center).padding(.horizontal, 32)
                            }
                        }.padding().tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(height: 420)
                Spacer()
                VStack(spacing: 16) {
                    if page == pages.count - 1 {
                        Toggle(isOn: $includeSample) {
                            Text("Add a few starter recipes").font(.subheadline).foregroundStyle(Brand.text2)
                        }.tint(Color.accentColor)
                    }
                    Button(page == pages.count - 1 ? "Start cooking" : "Continue") {
                        Haptics.tap()
                        if page < pages.count - 1 {
                            withAnimation(Brand.ease()) { page += 1 }
                        } else {
                            if includeSample { SeedData.populate(context) }
                            withAnimation(Brand.ease()) { hasOnboarded = true }
                        }
                    }.buttonStyle(InkButtonStyle())
                }
                .padding(.horizontal, 24).padding(.bottom, 32)
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) { bob = true }
        }
    }
}

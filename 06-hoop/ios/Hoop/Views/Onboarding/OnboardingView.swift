import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 0
    
    private let pages: [(title: String, subtitle: String, icon: String)] = [
        ("Scoreboard in\nYour Pocket", "Keep track of every point, foul, and timeout during pickup games and youth leagues.", "basketball.fill"),
        ("Track Every Player", "Record individual stats — 2-pointers, 3-pointers, free throws, and personal fouls per player.", "person.3.fill"),
        ("Full Game History", "Every game is saved with quarter scores and player stats so you can review any match.", "chart.bar.fill")
    ]
    
    var body: some View {
        ZStack {
            HoopTheme.darkBg.ignoresSafeArea()
            
            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        OnboardingPage(
                            title: pages[index].title,
                            subtitle: pages[index].subtitle,
                            icon: pages[index].icon
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                
                VStack(spacing: 16) {
                    if currentPage < pages.count - 1 {
                        Button {
                            withAnimation { currentPage += 1 }
                        } label: {
                            Text("Next")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(HoopTheme.orange)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    } else {
                        Button {
                            hasSeenOnboarding = true
                        } label: {
                            Text("Start Keeping Score")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(HoopTheme.orange)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

struct OnboardingPage: View {
    let title: String
    let subtitle: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 80))
                .foregroundStyle(HoopTheme.orange)
                .shadow(color: HoopTheme.orange.opacity(0.4), radius: 20)
            
            VStack(spacing: 12) {
                Text(title)
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                
                Text(subtitle)
                    .font(.body)
                    .foregroundStyle(HoopTheme.subtleText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            Spacer()
        }
    }
}

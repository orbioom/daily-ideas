import SwiftUI
import SwiftData

struct CampOnboardingView: View {
    @Environment(\.modelContext) private var context
    @Query private var settingsQ: [CampSettings]
    @State private var step = 0

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red:0.05,green:0.18,blue:0.10), Color(red:0.10,green:0.25,blue:0.15)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    ForEach(0..<2) { i in
                        Circle().fill(i == step ? CampfireTheme.accent : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.spring(), value: step)
                    }
                }
                .padding(.top, 60)
                .accessibilityLabel("Step \(step+1) of 2")
                Spacer()
                Group {
                    if step == 0 { welcomeStep } else { readyStep }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                .animation(.spring(response: 0.4), value: step)
                Spacer()
                Button(action: advance) {
                    Text(step == 0 ? "Let's Go" : "Start Planning")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 14).fill(CampfireTheme.accent))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
                .accessibilityLabel(step == 0 ? "Let's Go" : "Start Planning")
            }
        }
    }

    private var welcomeStep: some View {
        VStack(spacing: 20) {
            Text("🔥").font(.system(size: 80)).accessibilityHidden(true)
            Text("Welcome to Campfire")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.white)
            Text("Plan camping trips, pack your gear,\nlog your nature sightings, and journal every adventure.")
                .font(.body)
                .foregroundColor(.white.opacity(0.75))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
    }

    private var readyStep: some View {
        VStack(spacing: 20) {
            Text("⛺️").font(.system(size: 80)).accessibilityHidden(true)
            Text("You're Set!")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.white)
            Text("Add your first trip — give it a name, campsite, and dates.\nWe'll help you pack, plan meals, and remember everything.")
                .font(.body)
                .foregroundColor(.white.opacity(0.75))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
    }

    private func advance() {
        if step == 0 { step = 1 } else { complete() }
    }

    private func complete() {
        let s = settingsQ.first ?? { let ns = CampSettings(); context.insert(ns); return ns }()
        s.onboardingComplete = true
        try? context.save()
    }
}

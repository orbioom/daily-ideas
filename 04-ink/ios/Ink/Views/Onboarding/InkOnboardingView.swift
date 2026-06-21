import SwiftUI
import SwiftData

struct InkOnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsList: [InkSettings]
    @State private var page = 0

    private var settings: InkSettings {
        if let s = settingsList.first { return s }
        let s = InkSettings(); modelContext.insert(s); return s
    }

    var body: some View {
        ZStack {
            InkTheme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()
                Group {
                    if page == 0 { page0 }
                    else if page == 1 { page1 }
                    else { page2 }
                }
                .padding(.horizontal, 28)
                .transition(.opacity)
                Spacer()
                controls.padding(.bottom, 36)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: page)
    }

    var page0: some View {
        VStack(spacing: 20) {
            Text("🖋️")
                .font(.system(size: 80))
            Text("Ink")
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(InkTheme.textPrimary)
            Text("Plan your next tattoo.\nCollect ideas, track artists, book appointments.")
                .font(.system(size: 17))
                .foregroundStyle(InkTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    var page1: some View {
        VStack(spacing: 20) {
            Image(systemName: "paintbrush.fill")
                .font(.system(size: 56))
                .foregroundStyle(InkTheme.accent)
            Text("Organize Everything")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(InkTheme.textPrimary)
            VStack(alignment: .leading, spacing: 14) {
                featureRow("sparkles", "Ideas — collect concepts with style, placement, notes")
                featureRow("person.crop.rectangle.fill", "Artists — save artists with ratings and specialties")
                featureRow("calendar", "Appointments — track upcoming sessions and deposits")
                featureRow("tag.fill", "Status tracking from wishlist to done")
            }
        }
    }

    var page2: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 56))
                .foregroundStyle(InkTheme.accent)
            Text("Your Private Planner")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(InkTheme.textPrimary)
            Text("Everything stays on your device. No account, no cloud sync, no ads. Just your tattoo planning notebook.")
                .font(.system(size: 15))
                .foregroundStyle(InkTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    func featureRow(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(InkTheme.accent)
                .frame(width: 24)
            Text(text)
                .font(.system(size: 15))
                .foregroundStyle(InkTheme.textPrimary)
            Spacer()
        }
    }

    var controls: some View {
        HStack {
            if page > 0 {
                Button("Back") { page -= 1 }
                    .foregroundStyle(InkTheme.textSecondary)
            }
            Spacer()
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(i == page ? InkTheme.accent : InkTheme.textSecondary.opacity(0.4))
                        .frame(width: 7, height: 7)
                }
            }
            Spacer()
            Button(page < 2 ? "Next" : "Get Started") {
                if page < 2 { page += 1 }
                else { settings.hasCompletedOnboarding = true }
            }
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(InkTheme.accent)
        }
        .padding(.horizontal, 24)
    }
}

import SwiftUI

struct OnboardingView: View {
    let settings: RectoSettings
    @State private var currentPage: Int = 0

    var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.94, blue: 0.91)
                .ignoresSafeArea()

            TabView(selection: $currentPage) {
                OnboardingPageOne()
                    .tag(0)
                OnboardingPageTwo()
                    .tag(1)
                OnboardingPageThree(onGetStarted: {
                    settings.hasCompletedOnboarding = true
                })
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
    }
}

// MARK: - Page One: Rapid Logging
private struct OnboardingPageOne: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                Image(systemName: "pencil.and.list.clipboard")
                    .font(.system(size: 64, weight: .light))
                    .foregroundStyle(Color(red: 0.20, green: 0.20, blue: 0.20))
                    .padding(.bottom, 8)

                Text("Rapid Logging")
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .foregroundStyle(Color(red: 0.10, green: 0.10, blue: 0.10))

                Text("Capture your thoughts instantly using\nthree simple bullet types.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(Color(red: 0.40, green: 0.38, blue: 0.35))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)

            Spacer().frame(height: 48)

            VStack(spacing: 0) {
                BulletExplainerRow(
                    symbol: "•",
                    symbolColor: Color(red: 0.15, green: 0.15, blue: 0.55),
                    title: "Tasks",
                    description: "Action items you need to complete. Tap to mark done, migrate, or dismiss."
                )
                Divider().padding(.horizontal, 24)
                BulletExplainerRow(
                    symbol: "○",
                    symbolColor: Color(red: 0.10, green: 0.45, blue: 0.20),
                    title: "Events",
                    description: "Things that happen — appointments, meetings, milestones worth noting."
                )
                Divider().padding(.horizontal, 24)
                BulletExplainerRow(
                    symbol: "–",
                    symbolColor: Color(red: 0.45, green: 0.30, blue: 0.10),
                    title: "Notes",
                    description: "Ideas, observations, and thoughts you want to remember."
                )
            }
            .background(Color.white.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 24)

            Spacer()
        }
    }
}

private struct BulletExplainerRow: View {
    let symbol: String
    let symbolColor: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Text(symbol)
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundStyle(symbolColor)
                .frame(width: 36)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(red: 0.10, green: 0.10, blue: 0.10))
                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color(red: 0.40, green: 0.38, blue: 0.35))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

// MARK: - Page Two: Daily Logs & Collections
private struct OnboardingPageTwo: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                Image(systemName: "books.vertical")
                    .font(.system(size: 64, weight: .light))
                    .foregroundStyle(Color(red: 0.20, green: 0.20, blue: 0.20))
                    .padding(.bottom, 8)

                Text("Logs & Collections")
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .foregroundStyle(Color(red: 0.10, green: 0.10, blue: 0.10))

                Text("Organize your days and group\nrelated entries into Collections.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(Color(red: 0.40, green: 0.38, blue: 0.35))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)

            Spacer().frame(height: 48)

            VStack(spacing: 16) {
                FeatureCard(
                    icon: "book.fill",
                    iconColor: Color(red: 0.15, green: 0.15, blue: 0.55),
                    title: "Daily Log",
                    body: "Each day gets its own page. Navigate forward and backward to review any date, and migrate unfinished tasks to the future."
                )
                FeatureCard(
                    icon: "folder.fill",
                    iconColor: Color(red: 0.10, green: 0.45, blue: 0.20),
                    title: "Collections",
                    body: "Create named lists for projects, habits, reading lists, or any topic. Each Collection is its own focused space."
                )
                FeatureCard(
                    icon: "calendar",
                    iconColor: Color(red: 0.45, green: 0.30, blue: 0.10),
                    title: "Index",
                    body: "A bird's-eye view of your month. See which days have entries and quickly jump between dates."
                )
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }
}

private struct FeatureCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let body: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(iconColor)
                .frame(width: 32)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(red: 0.10, green: 0.10, blue: 0.10))
                Text(body)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color(red: 0.40, green: 0.38, blue: 0.35))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
            }

            Spacer()
        }
        .padding(16)
        .background(Color.white.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Page Three: Get Started
private struct OnboardingPageThree: View {
    let onGetStarted: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 32) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.90, green: 0.87, blue: 0.82))
                        .frame(width: 120, height: 120)

                    Image(systemName: "book.pages")
                        .font(.system(size: 56, weight: .light))
                        .foregroundStyle(Color(red: 0.20, green: 0.20, blue: 0.20))
                }

                VStack(spacing: 12) {
                    Text("Your Journal Awaits")
                        .font(.system(size: 34, weight: .bold, design: .serif))
                        .foregroundStyle(Color(red: 0.10, green: 0.10, blue: 0.10))
                        .multilineTextAlignment(.center)

                    Text("Start capturing your thoughts,\ntasks, and ideas — one bullet at a time.")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(Color(red: 0.40, green: 0.38, blue: 0.35))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }

                VStack(spacing: 12) {
                    QuickTip(text: "Swipe left on any entry to delete it")
                    QuickTip(text: "Swipe right on a task to migrate it to today")
                    QuickTip(text: "Star important entries to highlight them")
                }
                .padding(.horizontal, 32)
            }
            .padding(.horizontal, 24)

            Spacer()

            Button(action: onGetStarted) {
                Text("Get Started")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(red: 0.20, green: 0.20, blue: 0.20))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 60)
        }
    }
}

private struct QuickTip: View {
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(Color(red: 0.15, green: 0.15, blue: 0.55))
            Text(text)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(Color(red: 0.30, green: 0.28, blue: 0.26))
            Spacer()
        }
    }
}

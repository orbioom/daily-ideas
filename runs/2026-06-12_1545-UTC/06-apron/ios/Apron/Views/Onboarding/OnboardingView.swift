import SwiftUI
import SwiftData

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(\.modelContext) private var context
    @State private var page = 0
    @State private var jobName = ""
    @State private var role: JobRole = .server
    @State private var wage = ""

    private let pages: [(symbol: String, title: String, body: String)] = [
        ("dollarsign.circle.fill", "See your real take-home",
         "Apron tracks your tips, hours and wages shift by shift, so you always know exactly what you actually earned."),
        ("chart.bar.fill", "Find your best shifts",
         "Discover which days and sections pay best, your true hourly rate, and a forecast of where the month is heading."),
        ("lock.shield", "Private by default",
         "Your income stays on your iPhone — never uploaded to a server, never tied to an account. Just you and your money.")
    ]

    var body: some View {
        ZStack {
            Theme.bgPrimary.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { i in
                        VStack(spacing: 22) {
                            Spacer()
                            Image(systemName: pages[i].symbol)
                                .font(.system(size: 74)).foregroundStyle(Theme.heroGradient)
                                .accessibilityHidden(true)
                            Text(pages[i].title)
                                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                                .multilineTextAlignment(.center).foregroundStyle(Theme.textPrimary)
                            Text(pages[i].body)
                                .font(.body).multilineTextAlignment(.center)
                                .foregroundStyle(Theme.textSecondary).padding(.horizontal, 32)
                            Spacer()
                        }
                        .tag(i)
                    }
                    setupPage.tag(pages.count)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                Button {
                    Haptics.success()
                    if page < pages.count { withAnimation { page += 1 } } else { finish() }
                } label: {
                    Text(page < pages.count ? "Continue" : "Start tracking")
                        .font(.headline).frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent).tint(Theme.accent).controlSize(.large)
                .padding(.horizontal).padding(.bottom, 30)
            }
        }
    }

    private var setupPage: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "briefcase.fill").font(.system(size: 56)).foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text("Add your first job").font(.title.weight(.bold)).foregroundStyle(Theme.textPrimary)
            Text("You can add more later, or skip and do it in the app.")
                .font(.subheadline).foregroundStyle(Theme.textSecondary).multilineTextAlignment(.center)
            VStack(spacing: 12) {
                TextField("Job name (e.g. The Oyster Bar)", text: $jobName)
                    .textFieldStyle(.roundedBorder)
                Picker("Role", selection: $role) {
                    ForEach(JobRole.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.menu)
                HStack {
                    Text("Hourly wage").foregroundStyle(Theme.textSecondary)
                    Spacer()
                    Text(Currency.code).font(.caption).foregroundStyle(Theme.textSecondary)
                    TextField("0", text: $wage).keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing).frame(maxWidth: 90)
                }
                .padding(12).background(Theme.bgElevated, in: RoundedRectangle(cornerRadius: 10))
            }
            .padding(.horizontal, 24)
            Spacer()
        }
    }

    private func finish() {
        let name = jobName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !name.isEmpty {
            let w = Double(wage.replacingOccurrences(of: ",", with: ".").filter { "0123456789.".contains($0) }) ?? 0
            context.insert(Job(name: name, role: role, hourlyWage: max(w, 0)))
            try? context.save()
        }
        hasOnboarded = true
    }
}

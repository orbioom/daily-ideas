import SwiftUI
import SwiftData

/// Create or edit the single life profile. Used from the grid toolbar and onboarding.
struct ProfileEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    let profile: LifeProfile?

    @State private var name: String
    @State private var birthDate: Date
    @State private var expectancy: Double
    @State private var weekStartsMonday: Bool

    init(profile: LifeProfile?) {
        self.profile = profile
        _name = State(initialValue: profile?.name ?? "")
        _birthDate = State(initialValue: profile?.birthDate ?? Self.defaultBirthDate)
        _expectancy = State(initialValue: Double(profile?.lifeExpectancyYears ?? 90))
        _weekStartsMonday = State(initialValue: profile?.weekStartsMonday ?? true)
    }

    private static var defaultBirthDate: Date {
        var c = DateComponents(); c.year = 1995; c.month = 6; c.day = 21
        return Calendar(identifier: .gregorian).date(from: c) ?? Date()
    }

    private var birthInFuture: Bool { birthDate > Date() }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name (optional)", text: $name)
                    DatePicker("Birth date", selection: $birthDate,
                               in: ...Date(), displayedComponents: .date)
                } header: {
                    Text("About you")
                } footer: {
                    if birthInFuture {
                        Text("Birth date can't be in the future.")
                            .foregroundStyle(Theme.bad)
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Life expectancy")
                            Spacer()
                            Text("\(Int(expectancy)) years")
                                .font(Theme.rounded(15, .semibold))
                                .foregroundStyle(Theme.accent)
                        }
                        Slider(value: $expectancy,
                               in: Double(SpanEngine.minExpectancy)...Double(SpanEngine.maxExpectancy),
                               step: 1)
                        .accessibilityValue("\(Int(expectancy)) years")
                    }
                } header: {
                    Text("Your span")
                } footer: {
                    Text("This sets how many rows your life calendar has — one row per year. You can change it anytime.")
                }

                Section {
                    Toggle("Weeks start on Monday", isOn: $weekStartsMonday)
                } footer: {
                    Text("Affects how each week's start date is calculated.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(profile == nil ? "Set Up Your Life" : "Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(birthInFuture)
                }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let years = SpanEngine.clampExpectancy(Int(expectancy))
        let safeBirth = min(birthDate, Date())
        if let profile {
            profile.name = trimmed.isEmpty ? nil : trimmed
            profile.birthDate = safeBirth
            profile.lifeExpectancyYears = years
            profile.weekStartsMonday = weekStartsMonday
        } else {
            let new = LifeProfile(name: trimmed.isEmpty ? nil : trimmed,
                                  birthDate: safeBirth,
                                  lifeExpectancyYears: years,
                                  weekStartsMonday: weekStartsMonday)
            context.insert(new)
        }
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
        dismiss()
    }
}

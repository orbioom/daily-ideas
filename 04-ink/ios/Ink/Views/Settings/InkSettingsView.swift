import SwiftUI
import SwiftData

struct InkSettingsView: View {
    @Query private var settingsList: [InkSettings]
    @Environment(\.modelContext) private var modelContext
    @Query private var ideas: [TattooIdea]
    @Query private var artists: [TattooArtist]
    @Query private var appointments: [TattooAppointment]

    private var settings: InkSettings {
        if let s = settingsList.first { return s }
        let s = InkSettings(); modelContext.insert(s); return s
    }

    var body: some View {
        ZStack {
            InkTheme.background.ignoresSafeArea()
            List {
                prefsSection
                statsSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .listStyle(.insetGrouped)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(InkTheme.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    var prefsSection: some View {
        Section {
            Toggle("Show Cost Estimates", isOn: Binding(
                get: { settings.showEstimates },
                set: { settings.showEstimates = $0 }
            ))
            .foregroundStyle(InkTheme.textPrimary)
            .tint(InkTheme.accent)

            Picker("Default Style", selection: Binding(
                get: { settings.defaultStyle },
                set: { settings.defaultStyle = $0 }
            )) {
                ForEach(TattooStyle.allCases, id: \.self) { s in
                    Text(s.rawValue).tag(s.rawValue)
                }
            }
            .foregroundStyle(InkTheme.textPrimary)

            Picker("Currency", selection: Binding(
                get: { settings.currency },
                set: { settings.currency = $0 }
            )) {
                Text("USD ($)").tag("USD")
                Text("EUR (€)").tag("EUR")
                Text("GBP (£)").tag("GBP")
                Text("AUD (A$)").tag("AUD")
                Text("CAD (C$)").tag("CAD")
            }
            .foregroundStyle(InkTheme.textPrimary)
        } header: {
            Text("Preferences").foregroundStyle(InkTheme.textSecondary)
        }
        .listRowBackground(InkTheme.surface)
    }

    var statsSection: some View {
        let done = ideas.filter { $0.status == IdeaStatus.done.rawValue }.count
        let totalCost = appointments.reduce(0) { $0 + $1.totalCost }
        return Section {
            statRow("Ideas", "\(ideas.count)")
            statRow("Artists Saved", "\(artists.count)")
            statRow("Sessions Booked", "\(appointments.count)")
            statRow("Tattoos Completed", "\(done)")
            statRow("Total Spent", "$\(Int(totalCost))")
        } header: {
            Text("Your Ink Journey").foregroundStyle(InkTheme.textSecondary)
        }
        .listRowBackground(InkTheme.surface)
    }

    func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(InkTheme.textSecondary)
            Spacer()
            Text(value).foregroundStyle(InkTheme.textPrimary)
        }
    }

    var aboutSection: some View {
        Section {
            statRow("Version", "1.0")
            statRow("Storage", "Local only, no cloud")
        } header: {
            Text("About Ink").foregroundStyle(InkTheme.textSecondary)
        }
        .listRowBackground(InkTheme.surface)
    }
}

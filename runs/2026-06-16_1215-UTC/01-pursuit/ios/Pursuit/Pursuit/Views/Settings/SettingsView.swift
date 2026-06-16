import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var pro: ProStore

    @Query private var applications: [Application]

    @State private var showingPaywall = false
    @State private var showingArchived = false

    private var archivedCount: Int { applications.filter { $0.isArchived }.count }

    var body: some View {
        NavigationStack {
            Form {
                proSection

                Section("Appearance") {
                    Picker("Theme", selection: appearanceBinding) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Label(mode.rawValue, systemImage: mode.symbol).tag(mode)
                        }
                    }
                }

                Section("Job search") {
                    Stepper(value: $settings.weeklyGoal, in: 1...50) {
                        HStack {
                            Label("Weekly application goal", systemImage: "target")
                            Spacer()
                            Text("\(settings.weeklyGoal)").foregroundStyle(Theme.inkSoft)
                        }
                    }
                    Stepper(value: $settings.staleAfterDays, in: 3...60) {
                        HStack {
                            Label("Mark stale after", systemImage: "clock.badge.exclamationmark")
                            Spacer()
                            Text("\(settings.staleAfterDays) days").foregroundStyle(Theme.inkSoft)
                        }
                    }
                    Stepper(value: $settings.followUpDays, in: 1...30) {
                        HStack {
                            Label("Default follow-up in", systemImage: "bell.badge")
                            Spacer()
                            Text("\(settings.followUpDays) days").foregroundStyle(Theme.inkSoft)
                        }
                    }
                    Picker(selection: $settings.defaultCurrency) {
                        ForEach(AppSettings.currencyOptions, id: \.self) { Text($0).tag($0) }
                    } label: {
                        Label("Default currency", systemImage: "dollarsign.circle")
                    }
                }

                Section("Preferences") {
                    Toggle(isOn: $settings.hapticsEnabled) {
                        Label("Haptics", systemImage: "hand.tap")
                    }
                    .tint(Theme.accent)
                }

                Section("Organize") {
                    NavigationLink {
                        TagManagerView()
                    } label: {
                        Label("Manage tags", systemImage: "tag")
                    }
                    Button {
                        showingArchived = true
                    } label: {
                        HStack {
                            Label("Archived applications", systemImage: "archivebox")
                            Spacer()
                            Text("\(archivedCount)").foregroundStyle(Theme.inkSoft)
                        }
                    }
                    .foregroundStyle(Theme.ink)
                    if pro.isPro {
                        CSVShareLink(applications: applications) {
                            Label("Export CSV", systemImage: "square.and.arrow.up")
                        }
                        .foregroundStyle(Theme.ink)
                    } else {
                        Button {
                            showingPaywall = true
                        } label: {
                            Label("Export CSV (Pro)", systemImage: "lock.fill")
                        }
                        .foregroundStyle(Theme.ink)
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Made for", value: "Job seekers")
                    Text("Pursuit keeps your entire job search — applications, interviews, contacts and insights — in one private, native app. No account, no subscription, no data leaving your device.")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
            .navigationTitle("Settings")
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .sheet(isPresented: $showingPaywall) { PaywallView() }
            .sheet(isPresented: $showingArchived) { ArchivedView() }
        }
    }

    private var proSection: some View {
        Section {
            if pro.isPro {
                HStack(spacing: 12) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Theme.accent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Pursuit Pro").font(Theme.rounded(16, .bold)).foregroundStyle(Theme.ink)
                        Text("All features unlocked. Thank you!")
                            .font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
                    }
                    Spacer()
                    Image(systemName: "checkmark.seal.fill").foregroundStyle(Theme.good)
                }
                .padding(.vertical, 4)
            } else {
                Button {
                    showingPaywall = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "crown.fill").font(.system(size: 22)).foregroundStyle(Theme.accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Unlock Pursuit Pro").font(Theme.rounded(16, .bold)).foregroundStyle(Theme.ink)
                            Text("Unlimited applications, full insights & export — \(ProStore.priceText)")
                                .font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(Theme.inkFaint)
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
                Button("Restore purchase") {
                    let restored = pro.restore()
                    if restored { Haptics.notify(.success, enabled: settings.hapticsEnabled) }
                }
                .foregroundStyle(Theme.accent)
            }
        }
    }

    private var appearanceBinding: Binding<AppearanceMode> {
        Binding(
            get: { settings.appearance },
            set: { settings.appearance = $0; Haptics.selection(enabled: settings.hapticsEnabled) }
        )
    }

}

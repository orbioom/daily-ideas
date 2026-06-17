import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.modelContext) private var modelContext
    @Query private var subscriptions: [Subscription]

    @AppStorage(PrefKey.isPro) private var isPro: Bool = false
    @AppStorage(PrefKey.currencyCode) private var currencyCode: String = PrefDefault.currencyCode
    @AppStorage(PrefKey.defaultCycle) private var defaultCycleToken: String = PrefDefault.defaultCycle
    @AppStorage(PrefKey.renewalLeadDays) private var renewalLead: Int = PrefDefault.renewalLeadDays
    @AppStorage(PrefKey.trialLeadDays) private var trialLead: Int = PrefDefault.trialLeadDays
    @AppStorage(PrefKey.includeTrialsInTotal) private var includeTrials: Bool = false
    @AppStorage(PrefKey.hideAmounts) private var hideAmounts: Bool = false
    @AppStorage(PrefKey.firstWeekday) private var firstWeekday: Int = PrefDefault.firstWeekday
    @AppStorage(PrefKey.hapticsEnabled) private var haptics: Bool = true
    @AppStorage(PrefKey.notificationsEnabled) private var notificationsEnabled: Bool = false

    @State private var showPaywall = false
    @State private var showAbout = false
    @State private var showShare = false
    @State private var shareURL: URL?
    @State private var notifDenied = false

    private let leadOptions = [0, 1, 2, 3, 5, 7]

    var body: some View {
        NavigationStack {
            ZStack {
                RecurTheme.appBackground(scheme).ignoresSafeArea()
                Form {
                    proSection
                    generalSection
                    remindersSection
                    privacySection
                    dataSection
                    aboutSection
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showAbout) { AboutView() }
            .sheet(isPresented: $showShare) {
                if let url = shareURL {
                    #if canImport(UIKit)
                    ShareSheet(items: [url])
                    #else
                    Text("Export ready at \(url.lastPathComponent)")
                    #endif
                }
            }
            .alert("Notifications are off", isPresented: $notifDenied) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Enable notifications for Recur in iOS Settings to receive renewal and trial reminders.")
            }
        }
    }

    // MARK: - Pro

    private var proSection: some View {
        Section {
            Button { showPaywall = true } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(RecurTheme.violet.opacity(0.15))
                            .frame(width: 46, height: 46)
                        Image(systemName: isPro ? "checkmark.seal.fill" : "crown.fill")
                            .font(.title3)
                            .foregroundStyle(RecurTheme.violet)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(isPro ? "Recur Pro active" : "Unlock Recur Pro")
                            .font(.headline)
                            .foregroundStyle(RecurTheme.primaryText(scheme))
                        Text(isPro ? "Thank you for your support." : "$3.99 one-time · unlimited & reminders")
                            .font(.caption)
                            .foregroundStyle(RecurTheme.secondaryText(scheme))
                    }
                    Spacer()
                    if !isPro {
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(RecurTheme.secondaryText(scheme))
                    }
                }
            }
            if isPro {
                Button("Reset Pro (demo)") {
                    isPro = false
                    notificationsEnabled = false
                    NotificationManager.cancelAll()
                    Haptics.light()
                }
                .foregroundStyle(RecurTheme.coral)
            }
        }
    }

    // MARK: - General

    private var generalSection: some View {
        Section("General") {
            Picker("Currency", selection: $currencyCode) {
                ForEach(MoneyFormatter.currencyOptions, id: \.code) { opt in
                    Text("\(opt.symbol)  \(opt.code)").tag(opt.code)
                }
            }
            Picker("Default billing cycle", selection: $defaultCycleToken) {
                ForEach(BillingCycle.standardCases) { c in
                    Text(c.label).tag(c.token)
                }
            }
            Picker("First day of week", selection: $firstWeekday) {
                ForEach(WeekStart.allCases) { w in
                    Text(w.label).tag(w.rawValue)
                }
            }
            Toggle("Haptics", isOn: $haptics)
                .tint(RecurTheme.violet)
        }
    }

    // MARK: - Reminders

    private var remindersSection: some View {
        Section {
            HStack {
                Toggle("Renewal & trial reminders", isOn: Binding(
                    get: { notificationsEnabled },
                    set: { handleNotificationsToggle($0) }))
                    .tint(RecurTheme.violet)
                    .disabled(!isPro)
            }
            if !isPro {
                HStack {
                    Text("Requires Recur Pro").font(.caption).foregroundStyle(RecurTheme.secondaryText(scheme))
                    Spacer()
                    ProBadge()
                }
            }
            Picker("Renewal reminder", selection: $renewalLead) {
                ForEach(leadOptions, id: \.self) { d in
                    Text(leadLabel(d)).tag(d)
                }
            }
            .onChange(of: renewalLead) { _, _ in refreshNotificationsIfOn() }
            Picker("Trial reminder", selection: $trialLead) {
                ForEach(leadOptions, id: \.self) { d in
                    Text(leadLabel(d)).tag(d)
                }
            }
            .onChange(of: trialLead) { _, _ in refreshNotificationsIfOn() }
        } header: {
            Text("Reminders")
        } footer: {
            Text("Reminders are scheduled on-device. Nothing is sent to any server.")
        }
    }

    private func leadLabel(_ d: Int) -> String {
        switch d {
        case 0: return "On the day"
        case 1: return "1 day before"
        default: return "\(d) days before"
        }
    }

    // MARK: - Privacy

    private var privacySection: some View {
        Section("Display & privacy") {
            Toggle("Include trials in total", isOn: $includeTrials)
                .tint(RecurTheme.violet)
            Toggle("Hide amounts", isOn: $hideAmounts)
                .tint(RecurTheme.violet)
        }
    }

    // MARK: - Data

    private var dataSection: some View {
        Section("Data") {
            Button {
                if isPro { exportCSV() } else { showPaywall = true }
            } label: {
                HStack {
                    Label("Export to CSV", systemImage: "square.and.arrow.up")
                        .foregroundStyle(RecurTheme.primaryText(scheme))
                    Spacer()
                    if !isPro { ProBadge() }
                }
            }
            .disabled(subscriptions.isEmpty)
            Text("\(subscriptions.count) subscriptions tracked")
                .font(.caption)
                .foregroundStyle(RecurTheme.secondaryText(scheme))
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section {
            Button("About Recur") { showAbout = true }
                .foregroundStyle(RecurTheme.primaryText(scheme))
            HStack {
                Text("Version").foregroundStyle(RecurTheme.primaryText(scheme))
                Spacer()
                Text("1.0").foregroundStyle(RecurTheme.secondaryText(scheme))
            }
        }
    }

    // MARK: - Actions

    private func handleNotificationsToggle(_ on: Bool) {
        guard isPro else { showPaywall = true; return }
        if on {
            NotificationManager.requestAuthorization { granted in
                if granted {
                    notificationsEnabled = true
                    refreshNotifications()
                } else {
                    notificationsEnabled = false
                    notifDenied = true
                }
            }
        } else {
            notificationsEnabled = false
            NotificationManager.cancelAll()
        }
    }

    private func refreshNotificationsIfOn() {
        if notificationsEnabled && isPro { refreshNotifications() }
    }

    private func refreshNotifications() {
        NotificationManager.reschedule(subscriptions: subscriptions,
                                       renewalLead: renewalLead,
                                       trialLead: trialLead)
    }

    private func exportCSV() {
        let csv = CSVExporter.makeCSV(from: subscriptions)
        if let url = CSVExporter.writeTempFile(csv) {
            shareURL = url
            showShare = true
            Haptics.success()
        }
    }
}

// MARK: - About

struct AboutView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                RecurTheme.appBackground(scheme).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(RecurTheme.violet.opacity(0.14))
                                .frame(width: 96, height: 96)
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 42))
                                .foregroundStyle(RecurTheme.violet)
                        }
                        .accessibilityHidden(true)
                        Text("Recur")
                            .font(.title.weight(.bold))
                            .foregroundStyle(RecurTheme.primaryText(scheme))
                        Text("A private, on-device subscription & recurring-payment tracker. See what you pay, when it renews, and what to cancel — without sending a single byte to the cloud.")
                            .font(.subheadline)
                            .foregroundStyle(RecurTheme.secondaryText(scheme))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                        RecurCard {
                            VStack(alignment: .leading, spacing: 10) {
                                aboutRow("lock.shield", "100% on-device — no account, no cloud, no tracking.")
                                aboutRow("dollarsign.circle", "A one-time purchase, not another subscription.")
                                aboutRow("bell.badge", "Catches free trials before they bill you.")
                            }
                        }
                        .padding(.horizontal, 4)
                        Text("Version 1.0")
                            .font(.caption)
                            .foregroundStyle(RecurTheme.secondaryText(scheme))
                    }
                    .padding(20)
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func aboutRow(_ symbol: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(RecurTheme.violet)
                .frame(width: 24)
                .accessibilityHidden(true)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(RecurTheme.primaryText(scheme))
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(ProStore.self) private var pro
    @Environment(\.modelContext) private var context
    @Query private var bills: [Bill]
    @Query private var payments: [Payment]

    @AppStorage("haptics") private var haptics = true
    @AppStorage("currencyCode") private var currencyCode = "USD"
    @AppStorage("defaultDueSoonDays") private var defaultDueSoonDays = 3
    @AppStorage("defaultRecurrence") private var defaultRecurrenceRaw = Recurrence.monthly.rawValue
    @AppStorage("weekStartsMonday") private var weekStartsMonday = false
    @AppStorage("remindersOn") private var remindersOn = false
    @AppStorage("reminderLeadDays") private var reminderLeadDays = 3

    @State private var showPaywall = false
    @State private var confirmReset = false
    @State private var deniedAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                Form {
                    if !pro.isPro {
                        Section {
                            Button { showPaywall = true } label: { proBanner }
                                .buttonStyle(.plain)
                        }
                        .listRowBackground(Color.clear)
                    }

                    Section("Formatting") {
                        Picker("Currency", selection: $currencyCode) {
                            ForEach(CurrencyOption.all) { Text($0.label).tag($0.code) }
                        }
                    }

                    Section("Defaults") {
                        Stepper(value: $defaultDueSoonDays, in: 0...30) {
                            HStack {
                                Text("Due-soon window")
                                Spacer()
                                Text("\(defaultDueSoonDays) day\(defaultDueSoonDays == 1 ? "" : "s")")
                                    .foregroundStyle(Theme.inkSoft)
                            }
                        }
                        Picker("Default recurrence", selection: $defaultRecurrenceRaw) {
                            ForEach(Recurrence.allCases) { Text($0.label).tag($0.rawValue) }
                        }
                        Toggle("Week starts Monday", isOn: $weekStartsMonday)
                    }

                    Section {
                        Toggle("Payment reminders", isOn: $remindersOn)
                            .onChange(of: remindersOn) { _, on in handleRemindersToggle(on) }
                        if remindersOn {
                            Stepper(value: $reminderLeadDays, in: 0...14) {
                                HStack {
                                    Text("Remind me")
                                    Spacer()
                                    Text(reminderLeadDays == 0 ? "On due day" : "\(reminderLeadDays) day\(reminderLeadDays == 1 ? "" : "s") before")
                                        .foregroundStyle(Theme.inkSoft)
                                }
                            }
                            .onChange(of: reminderLeadDays) { _, _ in
                                Reminders.reschedule(for: bills, leadDays: reminderLeadDays)
                            }
                        }
                    } header: {
                        Text("Reminders")
                    } footer: {
                        Text(pro.isPro ? "Local notifications before each bill is due. Nothing leaves your device."
                                       : "Reminders are part of Remit Pro.")
                    }

                    Section("Feedback") {
                        Toggle("Haptics", isOn: $haptics)
                    }

                    Section("Pro") {
                        if pro.isPro {
                            Label("Remit Pro unlocked", systemImage: "checkmark.seal.fill")
                                .foregroundStyle(Theme.good)
                        } else {
                            Button("Unlock Remit Pro") { showPaywall = true }
                                .foregroundStyle(Theme.accent)
                        }
                        Button("Restore purchase") { pro.restore() }
                            .foregroundStyle(Theme.inkSoft)
                    }

                    Section("Data") {
                        HStack {
                            Text("Bills"); Spacer()
                            Text("\(bills.count)").foregroundStyle(Theme.inkSoft)
                        }
                        HStack {
                            Text("Logged payments"); Spacer()
                            Text("\(payments.count)").foregroundStyle(Theme.inkSoft)
                        }
                        Button("Delete all bills", role: .destructive) { confirmReset = true }
                    }

                    Section {
                        HStack { Text("Version"); Spacer(); Text("1.0").foregroundStyle(Theme.inkSoft) }
                    } footer: {
                        Text("Remit keeps everything on your device. No bank login, no account, no tracking, no subscription.")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .alert("Delete all bills?", isPresented: $confirmReset) {
                Button("Delete everything", role: .destructive) { resetAll() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This permanently removes every bill and its payment history, and cancels reminders. This cannot be undone.")
            }
            .alert("Notifications are off", isPresented: $deniedAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Enable notifications for Remit in the Settings app to get payment reminders.")
            }
        }
    }

    private var proBanner: some View {
        HStack(spacing: 14) {
            Image(systemName: "star.circle.fill").font(.system(size: 34)).foregroundStyle(.white)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("Remit Pro").font(Theme.rounded(17, .bold)).foregroundStyle(.white)
                Text("Unlimited bills, reminders & more").font(Theme.rounded(13, .regular))
                    .foregroundStyle(.white.opacity(0.9))
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.white.opacity(0.9))
                .accessibilityHidden(true)
        }
        .padding(16)
        .background(LinearGradient(colors: [Theme.accent, Theme.accent.opacity(0.78)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func handleRemindersToggle(_ on: Bool) {
        guard on else {
            Reminders.cancelAll()
            return
        }
        if !pro.isPro {
            remindersOn = false
            showPaywall = true
            Haptics.warning()
            return
        }
        Reminders.requestAuthorization { granted in
            if granted {
                Reminders.reschedule(for: bills, leadDays: reminderLeadDays)
            } else {
                remindersOn = false
                deniedAlert = true
            }
        }
    }

    private func resetAll() {
        for p in payments { context.delete(p) }
        for b in bills { context.delete(b) }
        try? context.save()
        Reminders.cancelAll()
        Haptics.success()
    }
}

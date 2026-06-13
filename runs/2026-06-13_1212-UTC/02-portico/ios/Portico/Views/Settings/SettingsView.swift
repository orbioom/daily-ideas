import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(ProStore.self) private var pro
    @Environment(\.modelContext) private var context
    @Query private var reflections: [Reflection]
    @Query private var saved: [SavedQuote]

    @AppStorage("haptics") private var haptics = true
    @AppStorage("showSource") private var showSource = true
    @AppStorage("morningReminderOn") private var morningOn = false
    /// Reminder times stored as minutes-from-midnight (07:00 and 21:30).
    @AppStorage("morningReminder") private var morningReminder = 7 * 60
    @AppStorage("eveningReminderOn") private var eveningOn = false
    @AppStorage("eveningReminder") private var eveningReminder = 21 * 60 + 30

    @State private var showPaywall = false
    @State private var confirmReset = false

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

                    Section("Reminders") {
                        Toggle("Morning preparation", isOn: $morningOn)
                        if morningOn {
                            timePicker("Time", minutes: $morningReminder)
                        }
                        Toggle("Evening reflection", isOn: $eveningOn)
                        if eveningOn {
                            timePicker("Time", minutes: $eveningReminder)
                        }
                    }

                    Section("Reading") {
                        Toggle("Show source & work", isOn: $showSource)
                    }

                    Section("Feedback") {
                        Toggle("Haptics", isOn: $haptics)
                    }

                    Section("Pro") {
                        if pro.isPro {
                            Label("Portico Pro unlocked", systemImage: "checkmark.seal.fill")
                                .foregroundStyle(Theme.good)
                        } else {
                            Button("Unlock Portico Pro") { showPaywall = true }
                                .foregroundStyle(Theme.accent)
                        }
                        Button("Restore purchase") { pro.restore() }
                            .foregroundStyle(Theme.inkSoft)
                    }

                    Section("Data") {
                        HStack {
                            Text("Reflections"); Spacer()
                            Text("\(reflections.count)").foregroundStyle(Theme.inkSoft)
                        }
                        HStack {
                            Text("Saved quotes"); Spacer()
                            Text("\(saved.count)").foregroundStyle(Theme.inkSoft)
                        }
                        Button("Reset history", role: .destructive) { confirmReset = true }
                    }

                    Section {
                        HStack { Text("Version"); Spacer(); Text("1.0").foregroundStyle(Theme.inkSoft) }
                    } footer: {
                        Text("Portico keeps everything on your device. No account, no tracking, no subscription.")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .alert("Reset history?", isPresented: $confirmReset) {
                Button("Delete everything", role: .destructive) { resetHistory() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This permanently removes every reflection and saved quote. Your settings stay.")
            }
            .onChange(of: morningOn) { _, on in if on { requestThenSync() } else { syncReminders() } }
            .onChange(of: eveningOn) { _, on in if on { requestThenSync() } else { syncReminders() } }
            .onChange(of: morningReminder) { _, _ in syncReminders() }
            .onChange(of: eveningReminder) { _, _ in syncReminders() }
        }
    }

    private func timePicker(_ label: String, minutes: Binding<Int>) -> some View {
        DatePicker(label,
                   selection: Binding(
                    get: { dateFrom(minutes.wrappedValue) },
                    set: { minutes.wrappedValue = minutesFrom($0) }),
                   displayedComponents: .hourAndMinute)
    }

    private var proBanner: some View {
        HStack(spacing: 14) {
            Image(systemName: "laurel.leading").font(.system(size: 30)).foregroundStyle(.white)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("Portico Pro").font(Theme.rounded(17, .bold)).foregroundStyle(.white)
                Text("The full quote library & deeper reflections").font(Theme.rounded(13, .regular))
                    .foregroundStyle(.white.opacity(0.9))
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.white.opacity(0.9))
        }
        .padding(16)
        .background(LinearGradient(colors: [Theme.accent, Theme.accent.opacity(0.78)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: Time helpers

    private func dateFrom(_ minutes: Int) -> Date {
        let m = min(max(0, minutes), 24 * 60 - 1)
        var comps = DateComponents()
        comps.hour = m / 60
        comps.minute = m % 60
        return Calendar.current.date(from: comps) ?? Date()
    }
    private func minutesFrom(_ date: Date) -> Int {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }

    // MARK: Reminders

    private func requestThenSync() {
        Reminders.requestAuthorization { _ in syncReminders() }
    }
    private func syncReminders() {
        Reminders.sync(morningOn: morningOn,
                       morningHour: morningReminder / 60, morningMinute: morningReminder % 60,
                       eveningOn: eveningOn,
                       eveningHour: eveningReminder / 60, eveningMinute: eveningReminder % 60)
    }

    private func resetHistory() {
        for r in reflections { context.delete(r) }
        for s in saved { context.delete(s) }
        try? context.save()
        Haptics.success()
    }
}

struct PaywallView: View {
    @Environment(ProStore.self) private var pro
    @Environment(\.dismiss) private var dismiss

    private let perks = [
        ("books.vertical.fill", "The full library", "All \(QuoteLibrary.all.count) public-domain quotes from Marcus Aurelius, Epictetus and Seneca — beyond the free daily set."),
        ("square.and.pencil", "Deeper reflections", "Pro templates: premeditation of adversity and the view-from-above evening review."),
        ("infinity", "One price, forever", "A single purchase — no monthly fee, no ads, ever.")
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 22) {
                        Image(systemName: "laurel.leading")
                            .font(.system(size: 64)).foregroundStyle(Theme.accent)
                            .padding(.top, 28).accessibilityHidden(true)
                        Text("Portico Pro").font(Theme.serif(30, .bold)).foregroundStyle(Theme.ink)
                        Text("The daily practice is free forever. Pro opens the whole library and the deeper reflections.")
                            .font(Theme.rounded(16, .regular)).foregroundStyle(Theme.inkSoft)
                            .multilineTextAlignment(.center).padding(.horizontal, 28)
                        VStack(spacing: 14) {
                            ForEach(perks, id: \.0) { perk in
                                HStack(spacing: 14) {
                                    Image(systemName: perk.0).font(.system(size: 24))
                                        .foregroundStyle(Theme.accent).frame(width: 36)
                                        .accessibilityHidden(true)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(perk.1).font(Theme.rounded(16, .bold)).foregroundStyle(Theme.ink)
                                        Text(perk.2).font(Theme.rounded(13, .regular)).foregroundStyle(Theme.inkSoft)
                                    }
                                    Spacer()
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                VStack(spacing: 10) {
                    Button {
                        pro.unlock(); Haptics.success(); dismiss()
                    } label: {
                        Text("Unlock for $6.99").font(Theme.rounded(18, .bold))
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .foregroundStyle(.white)
                    }
                    Button("Maybe later") { dismiss() }
                        .font(Theme.rounded(15, .medium)).foregroundStyle(Theme.inkSoft)
                }
                .padding(.horizontal, 20).padding(.bottom, 20)
            }
        }
    }
}

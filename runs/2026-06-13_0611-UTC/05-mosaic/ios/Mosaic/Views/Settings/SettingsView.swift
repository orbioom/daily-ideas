import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("appearance") private var appearance = AppearanceMode.system.rawValue
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("reminderEnabled") private var reminderEnabled = false
    @AppStorage("reminderTime") private var reminderTime = 21.0   // hours since midnight (21:00)
    @AppStorage("isPro") private var isPro = false

    @Environment(\.modelContext) private var context
    @Query private var entries: [DayEntry]
    @State private var showPaywall = false
    @State private var showErase = false
    @State private var time = Date()

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                Form {
                    if !isPro {
                        Section {
                            Button { showPaywall = true } label: { proBanner }.buttonStyle(.plain)
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    }
                    Section("Daily reminder") {
                        Toggle("Remind me to capture", isOn: $reminderEnabled)
                            .onChange(of: reminderEnabled) { _, on in
                                if on { applyReminder() } else { Reminders.cancel() }
                            }
                        if reminderEnabled {
                            DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                                .onChange(of: time) { _, _ in applyReminder() }
                        }
                    }
                    Section("Look & feel") {
                        Picker("Theme", selection: $appearance) {
                            ForEach(AppearanceMode.allCases) { Text($0.label).tag($0.rawValue) }
                        }
                        Toggle("Haptic feedback", isOn: $hapticsEnabled)
                            .onChange(of: hapticsEnabled) { _, v in Haptics.enabled = v }
                    }
                    Section("Your mosaic") {
                        LabeledContent("Days kept", value: "\(entries.count)")
                        LabeledContent("Longest streak", value: "\(MosaicStats.longestStreak(entries)) days")
                        LabeledContent("With photos", value: "\(entries.filter { $0.hasPhoto }.count)")
                        Button("Erase all days", role: .destructive) { showErase = true }
                    }
                    Section {
                        if isPro {
                            Label("Mosaic Pro unlocked", systemImage: "checkmark.seal.fill")
                                .foregroundStyle(Theme.accent)
                        }
                        LabeledContent("Version", value: "1.0")
                    } header: { Text("About") } footer: {
                        Text("Your photos and days are stored only on this device. Nothing is uploaded.")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .onAppear {
                Haptics.enabled = hapticsEnabled
                let h = Int(reminderTime); let m = Int((reminderTime - Double(h)) * 60)
                time = Calendar.current.date(bySettingHour: h, minute: m, second: 0, of: .now) ?? .now
            }
            .sheet(isPresented: $showPaywall) { PaywallView(isPro: $isPro) }
            .alert("Erase all days?", isPresented: $showErase) {
                Button("Cancel", role: .cancel) {}
                Button("Erase", role: .destructive) { erase() }
            } message: {
                Text("This permanently deletes every day and its photo. This cannot be undone.")
            }
        }
    }

    private func applyReminder() {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: time)
        let hour = comps.hour ?? 21, minute = comps.minute ?? 0
        reminderTime = Double(hour) + Double(minute) / 60
        Reminders.enable(hour: hour, minute: minute)
    }

    private func erase() {
        for e in entries { ImageStore.delete(e.photoFileName); context.delete(e) }
        try? context.save()
    }

    private var proBanner: some View {
        HStack(spacing: 14) {
            Image(systemName: "wand.and.stars").font(.system(size: 26)).foregroundStyle(Theme.accent)
            VStack(alignment: .leading, spacing: 3) {
                Text("Mosaic Pro").font(Theme.rounded(19)).foregroundStyle(Theme.ink)
                Text("Multiple photos a day, video clips, and a printable year poster.")
                    .font(.system(size: 13)).foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(Theme.inkFaint)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Theme.accent.opacity(0.14)))
    }
}

struct PaywallView: View {
    @Binding var isPro: Bool
    @Environment(\.dismiss) private var dismiss
    private let perks: [(String, String)] = [
        ("photo.on.rectangle.angled", "Several photos in a single day"),
        ("video", "Add short video clips"),
        ("printer", "Export a printable year-in-pixels poster"),
        ("lock.shield", "Always private, always on-device")
    ]
    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 22) {
                Spacer()
                Image(systemName: "wand.and.stars").font(.system(size: 52)).foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                Text("Mosaic Pro").font(Theme.rounded(32)).foregroundStyle(Theme.ink)
                Text("One payment. No subscription.").font(.system(size: 16)).foregroundStyle(Theme.inkSoft)
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(perks, id: \.0) { p in
                        HStack(spacing: 12) {
                            Image(systemName: p.0).foregroundStyle(Theme.accent).frame(width: 26)
                            Text(p.1).font(.system(size: 15)).foregroundStyle(Theme.ink)
                        }
                    }
                }.padding(.horizontal, 34)
                Spacer()
                Button { isPro = true; Haptics.success(); dismiss() } label: {
                    Text("Unlock for $7.99").font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Theme.accent))
                        .foregroundStyle(.white)
                }.padding(.horizontal, 24)
                Button("Maybe later") { dismiss() }
                    .font(.system(size: 15)).foregroundStyle(Theme.inkFaint).padding(.bottom, 24)
            }
        }
    }
}

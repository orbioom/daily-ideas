import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(ProStore.self) private var pro
    @Environment(\.modelContext) private var context
    @Query private var passages: [Passage]

    @AppStorage("haptics") private var haptics = true
    @AppStorage("passageFontSize") private var fontSizeRaw = PassageFontSize.medium.rawValue
    @AppStorage("startingCategory") private var startingCategoryRaw = PassageCategory.poem.rawValue
    @AppStorage("maskFraction") private var maskFractionRaw = MaskFractionPref.half.rawValue
    @AppStorage("revealHaptics") private var revealHaptics = true
    @AppStorage("reminderOn") private var reminderOn = false
    @AppStorage("reminderTime") private var reminderTimeStamp = Self.defaultReminderStamp

    @State private var showPaywall = false
    @State private var confirmReset = false

    private static var defaultReminderStamp: Double {
        let comps = DateComponents(hour: 19, minute: 0)
        let date = Calendar.current.date(from: comps) ?? .now
        return date.timeIntervalSince1970
    }

    private var reminderTime: Binding<Date> {
        Binding(
            get: { Date(timeIntervalSince1970: reminderTimeStamp) },
            set: { reminderTimeStamp = $0.timeIntervalSince1970 }
        )
    }

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

                    Section("Reading") {
                        Picker("Passage text size", selection: $fontSizeRaw) {
                            ForEach(PassageFontSize.allCases) { Text($0.displayName).tag($0.rawValue) }
                        }
                    }

                    Section("Study defaults") {
                        Picker("New passage category", selection: $startingCategoryRaw) {
                            ForEach(PassageCategory.allCases) { Text($0.displayName).tag($0.rawValue) }
                        }
                        Picker("Default blank density", selection: $maskFractionRaw) {
                            ForEach(MaskFractionPref.allCases) { Text($0.displayName).tag($0.rawValue) }
                        }
                    }

                    Section("Reminders") {
                        Toggle("Daily review reminder", isOn: $reminderOn)
                            .onChange(of: reminderOn) { _, on in
                                if on { ReminderManager.schedule(at: reminderTime.wrappedValue) }
                                else { ReminderManager.cancel() }
                            }
                        if reminderOn {
                            DatePicker("Time", selection: reminderTime, displayedComponents: .hourAndMinute)
                                .onChange(of: reminderTimeStamp) { _, _ in
                                    ReminderManager.schedule(at: reminderTime.wrappedValue)
                                }
                        }
                    }

                    Section("Feedback") {
                        Toggle("Haptics", isOn: $haptics)
                        Toggle("Reveal taps buzz", isOn: $revealHaptics)
                            .disabled(!haptics)
                    }

                    Section("Pro") {
                        if pro.isPro {
                            Label("Verbatim Pro unlocked", systemImage: "checkmark.seal.fill")
                                .foregroundStyle(Theme.good)
                        } else {
                            Button("Unlock Verbatim Pro") { showPaywall = true }
                                .foregroundStyle(Theme.accent)
                        }
                        Button("Restore purchase") { pro.restore() }
                            .foregroundStyle(Theme.inkSoft)
                    }

                    Section("Data") {
                        HStack {
                            Text("Passages"); Spacer()
                            Text("\(passages.count)").foregroundStyle(Theme.inkSoft)
                        }
                        Button("Delete all passages", role: .destructive) { confirmReset = true }
                    }

                    Section {
                        HStack { Text("Version"); Spacer(); Text("1.0").foregroundStyle(Theme.inkSoft) }
                    } footer: {
                        Text("Verbatim keeps every passage on your device. No account, no tracking, no subscription.")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .alert("Delete all passages?", isPresented: $confirmReset) {
                Button("Delete everything", role: .destructive) { resetLibrary() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This permanently removes every passage and its review history. Your settings stay.")
            }
        }
    }

    private var proBanner: some View {
        HStack(spacing: 14) {
            Image(systemName: "star.circle.fill").font(.system(size: 34)).foregroundStyle(.white)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("Verbatim Pro").font(Theme.rounded(17, .bold)).foregroundStyle(.white)
                Text("Unlimited passages, export & share").font(Theme.rounded(13, .regular))
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

    private func resetLibrary() {
        for p in passages { context.delete(p) }
        try? context.save()
        Haptics.success()
    }
}

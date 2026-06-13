import SwiftUI
import UIKit
import SwiftData

struct SettingsView: View {
    @Environment(ProStore.self) private var pro
    @Environment(\.modelContext) private var context
    @Query private var meds: [Medication]
    @Query private var logs: [DoseLog]

    @AppStorage("remindersEnabled") private var remindersEnabled = false
    @AppStorage("haptics") private var haptics = true
    @AppStorage("defaultRefillThreshold") private var defaultRefill = 7

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
                            Button { showPaywall = true } label: { proBanner }.buttonStyle(.plain)
                        }.listRowBackground(Color.clear)
                    }

                    Section("Reminders") {
                        Toggle("Dose reminders", isOn: $remindersEnabled)
                            .onChange(of: remindersEnabled) { _, on in handleReminderToggle(on) }
                    } footer: {
                        Text("On-device only. Cadence schedules a quiet local notification at each dose time.")
                    }

                    Section("Defaults") {
                        Stepper("Warn me with \(defaultRefill) left", value: $defaultRefill, in: 1...60)
                    }

                    Section("Feedback") {
                        Toggle("Haptics", isOn: $haptics)
                    }

                    Section("Cadence Pro") {
                        if pro.isPro {
                            Label("Cadence Pro unlocked", systemImage: "checkmark.seal.fill").foregroundStyle(Theme.good)
                        } else {
                            Button("Unlock Cadence Pro") { showPaywall = true }.foregroundStyle(Theme.accent)
                        }
                        Button("Restore purchase") { pro.restore() }.foregroundStyle(Theme.inkSoft)
                    }

                    Section("Data") {
                        HStack { Text("Medications"); Spacer(); Text("\(meds.count)").foregroundStyle(Theme.inkSoft) }
                        HStack { Text("Logged doses"); Spacer(); Text("\(logs.count)").foregroundStyle(Theme.inkSoft) }
                        Button("Erase all data", role: .destructive) { confirmReset = true }
                    }

                    Section {
                        HStack { Text("Version"); Spacer(); Text("1.0").foregroundStyle(Theme.inkSoft) }
                    } footer: {
                        Text("Cadence is not a substitute for medical advice. Everything stays on your device — no account, no cloud.")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .alert("Notifications are off", isPresented: $deniedAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                }
                Button("OK", role: .cancel) { }
            } message: {
                Text("Allow notifications for Cadence in iOS Settings to get dose reminders.")
            }
            .alert("Erase everything?", isPresented: $confirmReset) {
                Button("Erase", role: .destructive) { reset() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This permanently deletes every medication and dose log. This can’t be undone.")
            }
        }
    }

    private func handleReminderToggle(_ on: Bool) {
        let snapshot = meds
        Task {
            if on {
                let granted = await NotificationScheduler.requestAuthorization()
                if !granted {
                    await MainActor.run { remindersEnabled = false; deniedAlert = true }
                    return
                }
            }
            await NotificationScheduler.reschedule(meds: snapshot, enabled: on)
        }
    }

    private var proBanner: some View {
        HStack(spacing: 14) {
            Image(systemName: "heart.text.square.fill").font(.system(size: 34)).foregroundStyle(.white)
            VStack(alignment: .leading, spacing: 2) {
                Text("Cadence Pro").font(Theme.rounded(17, .bold)).foregroundStyle(.white)
                Text("Unlimited meds, export & more").font(Theme.rounded(13, .regular)).foregroundStyle(.white.opacity(0.9))
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.white.opacity(0.9))
        }
        .padding(16)
        .background(LinearGradient(colors: [Theme.accent, Theme.accent.opacity(0.78)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func reset() {
        for m in meds { context.delete(m) }
        for l in logs { context.delete(l) }
        try? context.save()
        Task { await NotificationScheduler.reschedule(meds: [], enabled: remindersEnabled) }
        Haptics.warning()
    }
}

struct PaywallView: View {
    @Environment(ProStore.self) private var pro
    @Environment(\.dismiss) private var dismiss

    private let perks = [
        ("infinity", "Unlimited medications", "Track your whole regimen — the free plan covers five."),
        ("square.and.arrow.up", "Export adherence reports", "Share a clean dose history with your doctor or caregiver."),
        ("paintpalette.fill", "More colors & forms", "Personalize every medication, with one price and no subscription.")
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 22) {
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 64)).foregroundStyle(Theme.accent)
                            .padding(.top, 28).accessibilityHidden(true)
                        Text("Cadence Pro").font(Theme.serif(30, .bold)).foregroundStyle(Theme.ink)
                        Text("All your reminders are free. Pro adds the extras.")
                            .font(Theme.rounded(16, .regular)).foregroundStyle(Theme.inkSoft)
                            .multilineTextAlignment(.center).padding(.horizontal, 28)
                        VStack(spacing: 14) {
                            ForEach(perks, id: \.0) { perk in
                                HStack(spacing: 14) {
                                    Image(systemName: perk.0).font(.system(size: 24))
                                        .foregroundStyle(Theme.accent).frame(width: 36)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(perk.1).font(Theme.rounded(16, .bold)).foregroundStyle(Theme.ink)
                                        Text(perk.2).font(Theme.rounded(13, .regular)).foregroundStyle(Theme.inkSoft)
                                    }
                                    Spacer()
                                }
                            }
                        }.padding(.horizontal, 20)
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

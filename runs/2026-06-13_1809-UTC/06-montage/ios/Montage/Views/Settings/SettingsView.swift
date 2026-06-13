import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(ProStore.self) private var pro
    @Environment(\.modelContext) private var context
    @Query private var creations: [Creation]

    @AppStorage("haptics") private var haptics = true
    @AppStorage("defaultStoryBackground") private var defaultStoryBg = "sunset"
    @AppStorage("addCaptionByDefault") private var addCaption = true

    @State private var showPaywall = false
    @State private var confirmReset = false

    private let storyBackgrounds = ["sunset", "white", "ink", "blush", "peachy", "cream"]

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

                    Section("Defaults") {
                        Picker("Default story background", selection: $defaultStoryBg) {
                            ForEach(storyBackgrounds, id: \.self) { id in Text(BackgroundLibrary.byID(id).name).tag(id) }
                        }
                        Toggle("Start with a caption", isOn: $addCaption)
                    }

                    Section("Feedback") {
                        Toggle("Haptics", isOn: $haptics)
                    }

                    Section("Montage Pro") {
                        if pro.isPro {
                            Label("Montage Pro unlocked", systemImage: "checkmark.seal.fill").foregroundStyle(Theme.good)
                        } else {
                            Button("Unlock Montage Pro") { showPaywall = true }.foregroundStyle(Theme.accent)
                        }
                        Button("Restore purchase") { pro.restore() }.foregroundStyle(Theme.inkSoft)
                    }

                    Section("Data") {
                        HStack { Text("Saved creations"); Spacer(); Text("\(creations.count)").foregroundStyle(Theme.inkSoft) }
                        HStack { Text("Templates"); Spacer(); Text("\(TemplateLibrary.all.count)").foregroundStyle(Theme.inkSoft) }
                        Button("Clear creations", role: .destructive) { confirmReset = true }
                    }

                    Section {
                        HStack { Text("Version"); Spacer(); Text("1.0").foregroundStyle(Theme.inkSoft) }
                    } footer: {
                        Text("Montage composes everything on your device. No watermark, no account, no tracking.")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .alert("Clear all creations?", isPresented: $confirmReset) {
                Button("Clear", role: .destructive) { reset() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This removes your saved creations from Montage. Exported images stay in your Photos.")
            }
        }
    }

    private var proBanner: some View {
        HStack(spacing: 14) {
            Image(systemName: "sparkles").font(.system(size: 30)).foregroundStyle(.white)
            VStack(alignment: .leading, spacing: 2) {
                Text("Montage Pro").font(Theme.rounded(17, .bold)).foregroundStyle(.white)
                Text("All gradients, premium looks & more").font(Theme.rounded(13, .regular)).foregroundStyle(.white.opacity(0.9))
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.white.opacity(0.9))
        }
        .padding(16)
        .background(LinearGradient(colors: [Theme.accent, Theme.accent.opacity(0.74)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func reset() {
        for c in creations { context.delete(c) }
        try? context.save()
        Haptics.warning()
    }
}

struct PaywallView: View {
    @Environment(ProStore.self) private var pro
    @Environment(\.dismiss) private var dismiss

    private let perks = [
        ("paintpalette.fill", "Every background", "Unlock all premium gradients and palettes."),
        ("rectangle.split.2x2.fill", "All templates & no watermark", "Use every layout and export clean, watermark-free images."),
        ("infinity", "One price, forever", "A single purchase — no subscription, ever.")
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 22) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 58)).foregroundStyle(Theme.accent)
                            .padding(.top, 28).accessibilityHidden(true)
                        Text("Montage Pro").font(Theme.serif(30, .bold)).foregroundStyle(Theme.ink)
                        Text("The studio is free and never adds a watermark. Pro unlocks the extras.")
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
                        Text("Unlock for $5.99").font(Theme.rounded(18, .bold))
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

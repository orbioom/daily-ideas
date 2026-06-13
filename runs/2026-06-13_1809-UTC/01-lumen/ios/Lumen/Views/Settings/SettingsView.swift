import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(ProStore.self) private var pro
    @Environment(\.modelContext) private var context
    @Query private var recipes: [Recipe]
    @Query private var edits: [EditRecord]

    @AppStorage("haptics") private var haptics = true
    @AppStorage("highQualityExport") private var highQuality = true
    @AppStorage("autoSaveRecipeOnExport") private var autoSaveRecipe = false

    @State private var showPaywall = false
    @State private var confirmReset = false

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

                    Section("Export") {
                        Toggle("Full-resolution export", isOn: $highQuality)
                        Toggle("Offer to save recipe after export", isOn: $autoSaveRecipe)
                    } footer: {
                        Text("Lumen always processes your photo at full size before saving to your library.")
                    }

                    Section("Feedback") {
                        Toggle("Haptics", isOn: $haptics)
                    }

                    Section("Lumen Pro") {
                        if pro.isPro {
                            Label("Lumen Pro unlocked", systemImage: "checkmark.seal.fill").foregroundStyle(Theme.good)
                        } else {
                            Button("Unlock Lumen Pro") { showPaywall = true }.foregroundStyle(Theme.accent)
                        }
                        Button("Restore purchase") { pro.restore() }.foregroundStyle(Theme.inkSoft)
                    }

                    Section("Data") {
                        HStack { Text("Saved recipes"); Spacer(); Text("\(recipes.count)").foregroundStyle(Theme.inkSoft) }
                        HStack { Text("Gallery edits"); Spacer(); Text("\(edits.count)").foregroundStyle(Theme.inkSoft) }
                        Button("Clear recipes & gallery", role: .destructive) { confirmReset = true }
                    }

                    Section {
                        HStack { Text("Version"); Spacer(); Text("1.0").foregroundStyle(Theme.inkSoft) }
                    } footer: {
                        Text("Every edit is processed on your device with Core Image. No uploads, no watermark, no tracking.")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .alert("Clear saved data?", isPresented: $confirmReset) {
                Button("Clear", role: .destructive) { reset() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This removes your recipes and gallery edits. Photos in your library are untouched.")
            }
        }
    }

    private var proBanner: some View {
        HStack(spacing: 14) {
            Image(systemName: "camera.aperture").font(.system(size: 30)).foregroundStyle(.white)
            VStack(alignment: .leading, spacing: 2) {
                Text("Lumen Pro").font(Theme.rounded(17, .bold)).foregroundStyle(.white)
                Text("All presets, custom recipes & more").font(Theme.rounded(13, .regular)).foregroundStyle(.white.opacity(0.9))
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
        for r in recipes { context.delete(r) }
        for e in edits { context.delete(e) }
        try? context.save()
        Haptics.warning()
    }
}

struct PaywallView: View {
    @Environment(ProStore.self) private var pro
    @Environment(\.dismiss) private var dismiss

    private let perks = [
        ("camera.filters", "All 16 film looks", "Unlock the full preset library — Cinematic, Vintage, Moody and more."),
        ("wand.and.stars", "Custom recipes", "Save your own signature looks and apply them to any photo."),
        ("infinity", "One price, forever", "No subscription, no watermark, no ads — just a single purchase.")
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 22) {
                        Image(systemName: "camera.aperture")
                            .font(.system(size: 60)).foregroundStyle(Theme.accent)
                            .padding(.top, 28).accessibilityHidden(true)
                        Text("Lumen Pro").font(Theme.serif(30, .bold)).foregroundStyle(Theme.ink)
                        Text("The core editor and six looks are free. Pro unlocks the rest.")
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
                        Text("Unlock for $7.99").font(Theme.rounded(18, .bold))
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

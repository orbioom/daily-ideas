import SwiftUI
import SwiftData

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var scheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("appearance") private var appearance = AppearanceMode.system.rawValue
    @AppStorage("defaultSort") private var defaultSort = "Last edited"
    @AppStorage("isPro") private var isPro = false

    @Query private var notes: [Note]
    @State private var showPaywall = false
    @State private var showRestore = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                Form {
                    if !isPro {
                        Section {
                            Button { showPaywall = true } label: { proBanner }
                                .buttonStyle(.plain)
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    }

                    Section("Appearance") {
                        Picker("Theme", selection: $appearance) {
                            ForEach(AppearanceMode.allCases) { Text($0.label).tag($0.rawValue) }
                        }
                    }

                    Section("Library") {
                        Picker("Default sort", selection: $defaultSort) {
                            ForEach(LibraryView.SortMode.allCases) { Text($0.rawValue).tag($0.rawValue) }
                        }
                        Toggle("Haptic feedback", isOn: $hapticsEnabled)
                            .onChange(of: hapticsEnabled) { _, v in Haptics.enabled = v }
                    }

                    Section("Your library") {
                        LabeledContent("Notes", value: "\(notes.filter { !$0.isArchived }.count)")
                        LabeledContent("Words written",
                                       value: "\(notes.reduce(0) { $0 + $1.wordCount })")
                        Button("Restore sample notes") { showRestore = true }
                    }

                    Section {
                        if isPro {
                            Label("Verso Pro unlocked", systemImage: "checkmark.seal.fill")
                                .foregroundStyle(Theme.accent)
                        }
                        LabeledContent("Version", value: "1.0")
                    } header: { Text("About") } footer: {
                        Text("Verso keeps every note on your device as plain Markdown. No account, no tracking, no monthly fee to read your own words.")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) { PaywallView(isPro: $isPro) }
            .alert("Restore sample notes?", isPresented: $showRestore) {
                Button("Cancel", role: .cancel) {}
                Button("Restore") { SeedData.populate(context); Haptics.success() }
            } message: {
                Text("This adds the original example notes back to your library. Your own notes are untouched.")
            }
            .onAppear { Haptics.enabled = hapticsEnabled }
        }
    }

    private var proBanner: some View {
        HStack(spacing: 14) {
            Image(systemName: "seal.fill")
                .font(.system(size: 30))
                .foregroundStyle(Theme.amber)
            VStack(alignment: .leading, spacing: 3) {
                Text("Verso Pro").font(Theme.serifTitle(19)).foregroundStyle(Theme.ink)
                Text("Unlimited notes, export, and themes — one payment, yours for good.")
                    .font(.system(size: 13)).foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(Theme.inkFaint)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Theme.accentSoft))
    }
}

struct PaywallView: View {
    @Binding var isPro: Bool
    @Environment(\.dismiss) private var dismiss

    private let perks: [(String, String)] = [
        ("infinity", "Unlimited notes & folders"),
        ("square.and.arrow.up", "Export to Markdown & PDF"),
        ("paintpalette", "Extra accent themes"),
        ("lock.shield", "Stays on your device — always")
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 22) {
                Spacer()
                Image(systemName: "seal.fill").font(.system(size: 56)).foregroundStyle(Theme.amber)
                    .accessibilityHidden(true)
                Text("Verso Pro").font(Theme.serifTitle(32)).foregroundStyle(Theme.ink)
                Text("One payment. No subscription. Ever.")
                    .font(.system(size: 16)).foregroundStyle(Theme.inkSoft)
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(perks, id: \.0) { perk in
                        HStack(spacing: 12) {
                            Image(systemName: perk.0).foregroundStyle(Theme.accent).frame(width: 26)
                            Text(perk.1).font(.system(size: 16)).foregroundStyle(Theme.ink)
                        }
                    }
                }
                .padding(.horizontal, 40).padding(.vertical, 6)
                Spacer()
                Button {
                    isPro = true; Haptics.success(); dismiss()
                } label: {
                    Text("Unlock for $7.99")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Theme.accent))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 24)
                Button("Maybe later") { dismiss() }
                    .font(.system(size: 15)).foregroundStyle(Theme.inkFaint)
                    .padding(.bottom, 24)
            }
        }
    }
}

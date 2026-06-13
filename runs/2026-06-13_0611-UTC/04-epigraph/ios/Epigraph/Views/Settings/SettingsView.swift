import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("reviewSize") private var reviewSize = 8
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("appearance") private var appearance = AppearanceMode.system.rawValue
    @AppStorage("isPro") private var isPro = false

    @Environment(\.modelContext) private var context
    @Query private var highlights: [Highlight]
    @Query private var books: [Book]
    @State private var showPaywall = false
    @State private var showRestore = false

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
                    Section("Daily review") {
                        Picker("Cards per review", selection: $reviewSize) {
                            ForEach([3, 5, 8, 12, 20], id: \.self) { Text("\($0)").tag($0) }
                        }
                    }
                    Section("Look & feel") {
                        Picker("Theme", selection: $appearance) {
                            ForEach(AppearanceMode.allCases) { Text($0.label).tag($0.rawValue) }
                        }
                        Toggle("Haptic feedback", isOn: $hapticsEnabled)
                            .onChange(of: hapticsEnabled) { _, v in Haptics.enabled = v }
                    }
                    Section("Your commonplace book") {
                        LabeledContent("Books", value: "\(books.count)")
                        LabeledContent("Highlights", value: "\(highlights.count)")
                        LabeledContent("Favorites", value: "\(highlights.filter { $0.isFavorite }.count)")
                        Button("Restore sample library") { showRestore = true }
                    }
                    Section {
                        if isPro {
                            Label("Epigraph Pro unlocked", systemImage: "checkmark.seal.fill")
                                .foregroundStyle(Theme.accent)
                        }
                        LabeledContent("Version", value: "1.0")
                    } header: { Text("About") } footer: {
                        Text("Every highlight stays on your device. No account, no monthly fee to revisit your own reading.")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) { PaywallView(isPro: $isPro) }
            .alert("Restore sample library?", isPresented: $showRestore) {
                Button("Cancel", role: .cancel) {}
                Button("Restore") { SeedData.populate(context); Haptics.success() }
            } message: {
                Text("Adds the original example books and highlights. Your own are untouched.")
            }
            .onAppear { Haptics.enabled = hapticsEnabled }
        }
    }

    private var proBanner: some View {
        HStack(spacing: 14) {
            Image(systemName: "seal.fill").font(.system(size: 28)).foregroundStyle(Theme.accent)
            VStack(alignment: .leading, spacing: 3) {
                Text("Epigraph Pro").font(Theme.serif(19, .bold)).foregroundStyle(Theme.ink)
                Text("Unlimited books, bulk import, and export to Markdown — one payment.")
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
        ("infinity", "Unlimited books & highlights"),
        ("square.and.arrow.down", "Paste-import many highlights at once"),
        ("square.and.arrow.up", "Export to Markdown & plain text"),
        ("bell", "A daily resurfacing reminder")
    ]
    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 22) {
                Spacer()
                Image(systemName: "seal.fill").font(.system(size: 54)).foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                Text("Epigraph Pro").font(Theme.serif(32, .bold)).foregroundStyle(Theme.ink)
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
                    Text("Unlock for $6.99").font(.system(size: 17, weight: .semibold))
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

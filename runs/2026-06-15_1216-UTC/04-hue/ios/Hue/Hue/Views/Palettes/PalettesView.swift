import SwiftUI
import SwiftData

struct PalettesView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var context
    @AppStorage("isPro") private var isPro = false
    @Query(sort: \CustomPalette.createdAt, order: .reverse) private var customPalettes: [CustomPalette]

    @State private var editor: PaletteEditorTarget?
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    intro
                    customSection
                    builtInSection
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Palettes")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if Pro.canCreateCustomPalette(isPro: isPro) {
                            editor = .new
                        } else {
                            showPaywall = true
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Create custom palette")
                }
            }
            .sheet(item: $editor) { target in
                PaletteEditorView(target: target)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(reason: .customPalette)
            }
        }
    }

    private var intro: some View {
        Text("Set a default palette for new pages, or craft your own with Hue Pro.")
            .font(Theme.rounded(14))
            .foregroundStyle(Theme.inkSoft)
    }

    // MARK: - Custom

    private var customSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            header("Your palettes", systemImage: "wand.and.stars")
            if customPalettes.isEmpty {
                emptyCustom
            } else {
                ForEach(customPalettes) { cp in
                    let palette = cp.asPalette()
                    paletteCard(palette,
                                isDefault: settings.defaultPaletteId == palette.id,
                                onSetDefault: { settings.defaultPaletteId = palette.id },
                                onEdit: { editor = .existing(cp.persistentModelID) },
                                onDelete: { delete(cp) })
                }
            }
        }
    }

    private var emptyCustom: some View {
        VStack(spacing: 10) {
            Image(systemName: "swatchpalette")
                .font(.system(size: 30))
                .foregroundStyle(Theme.inkFaint)
            Text(isPro ? "No custom palettes yet. Tap + to create one."
                       : "Create custom palettes with Hue Pro.")
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
            if !isPro {
                Button("See Hue Pro") { showPaywall = true }
                    .font(Theme.rounded(14, .semibold))
                    .foregroundStyle(Theme.accent)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .cardSurface()
    }

    // MARK: - Built-in

    private var builtInSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            header("Built-in", systemImage: "paintpalette")
            ForEach(PaletteLibrary.all) { palette in
                paletteCard(palette,
                            isDefault: settings.defaultPaletteId == palette.id,
                            onSetDefault: { settings.defaultPaletteId = palette.id },
                            onEdit: nil,
                            onDelete: nil)
            }
        }
    }

    // MARK: - Card

    private func paletteCard(_ palette: Palette, isDefault: Bool,
                             onSetDefault: @escaping () -> Void,
                             onEdit: (() -> Void)?,
                             onDelete: (() -> Void)?) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(palette.name)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                if isDefault {
                    Text("Default")
                        .font(Theme.rounded(11, .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Capsule().fill(Theme.accent))
                }
                Spacer()
                if let onEdit {
                    Button { onEdit() } label: { Image(systemName: "pencil") }
                        .accessibilityLabel("Edit \(palette.name)")
                }
                if let onDelete {
                    Button(role: .destructive) { onDelete() } label: { Image(systemName: "trash") }
                        .accessibilityLabel("Delete \(palette.name)")
                }
            }
            swatches(palette)
            Button(action: onSetDefault) {
                Text(isDefault ? "Current default" : "Set as default")
                    .font(Theme.rounded(13, .medium))
                    .foregroundStyle(isDefault ? Theme.inkFaint : Theme.accent)
            }
            .disabled(isDefault)
        }
        .cardSurface()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(palette.name) palette, \(palette.colorHexes.count) colors\(isDefault ? ", current default" : "")")
    }

    private func swatches(_ palette: Palette) -> some View {
        let cols = [GridItem(.adaptive(minimum: 26), spacing: 6)]
        return LazyVGrid(columns: cols, spacing: 6) {
            ForEach(Array(palette.colors.enumerated()), id: \.offset) { _, color in
                RoundedRectangle(cornerRadius: 6)
                    .fill(color)
                    .frame(height: 26)
                    .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Theme.hairline, lineWidth: 0.5))
            }
        }
        .accessibilityHidden(true)
    }

    private func header(_ title: String, systemImage: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage).foregroundStyle(Theme.accent)
            Text(title).font(Theme.rounded(20, .bold)).foregroundStyle(Theme.ink)
        }
        .accessibilityAddTraits(.isHeader)
    }

    private func delete(_ cp: CustomPalette) {
        // If this was the default, fall back to the built-in default.
        if settings.defaultPaletteId == cp.paletteId {
            settings.defaultPaletteId = PaletteLibrary.default.id
        }
        context.delete(cp)
        try? context.save()
    }
}

enum PaletteEditorTarget: Identifiable {
    case new
    case existing(PersistentIdentifier)

    var id: String {
        switch self {
        case .new: return "new"
        case .existing(let id): return "\(id.hashValue)"
        }
    }
}

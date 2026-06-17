import SwiftUI
import SwiftData

struct PalettesView: View {
    @Binding var selectedTab: Int
    @Environment(StudioModel.self) private var studio
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    @Query(sort: \CustomPalette.createdAt, order: .reverse) private var customPalettes: [CustomPalette]

    @State private var editorPalette: CustomPalette?
    @State private var showEditor = false
    @State private var showPaywall = false
    @State private var toast: Toast?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    customSection
                    ForEach(BuiltInPalettes.grouped(), id: \.group.id) { entry in
                        builtInSection(title: entry.group.rawValue, palettes: entry.palettes)
                    }
                }
                .padding(18)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Palettes")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        startNewPalette()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Create palette")
                }
            }
            .toast($toast)
            .sheet(isPresented: $showEditor) {
                PaletteEditorView(existing: editorPalette) { result in
                    handleEditorResult(result)
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    // MARK: - Sections

    private var customSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(PaletteGroup.custom.rawValue)
            if customPalettes.isEmpty {
                emptyCustom
            } else {
                ForEach(customPalettes) { palette in
                    paletteCard(palette.asPalette, custom: palette)
                }
            }
        }
    }

    private var emptyCustom: some View {
        VStack(spacing: 10) {
            Image(systemName: "paintpalette")
                .font(.system(size: 28))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text("No custom palettes yet")
                .font(Theme.rounded(15, .semibold))
                .foregroundStyle(Theme.ink)
            Text("Tap + to mix your own colors.")
                .font(Theme.rounded(13))
                .foregroundStyle(Theme.inkSoft)
            Button("Create one") { startNewPalette() }
                .font(Theme.rounded(14, .semibold))
                .foregroundStyle(Theme.accent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous).strokeBorder(Theme.hairline, lineWidth: 1))
    }

    private func builtInSection(title: String, palettes: [Palette]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title)
            ForEach(palettes) { palette in
                paletteCard(palette, custom: nil)
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(Theme.rounded(18, .bold))
            .foregroundStyle(Theme.ink)
    }

    private func paletteCard(_ palette: Palette, custom: CustomPalette?) -> some View {
        let isActive = studio.spec.paletteName == palette.name && studio.spec.paletteHexes == palette.hexes
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(palette.name)
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                if isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.accent)
                        .accessibilityHidden(true)
                }
                if custom != nil {
                    Menu {
                        Button { editorPalette = custom; showEditor = true } label: { Label("Edit", systemImage: "pencil") }
                        Button(role: .destructive) { deleteCustom(custom) } label: { Label("Delete", systemImage: "trash") }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundStyle(Theme.inkSoft)
                    }
                    .accessibilityLabel("Palette options")
                }
            }
            SwatchRow(colors: palette.colors, height: 34)
            Button {
                applyPalette(palette)
            } label: {
                Text(isActive ? "Active in Studio" : "Use in Studio")
                    .font(Theme.rounded(14, .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(isActive ? AnyShapeStyle(Theme.surfaceRaised) : AnyShapeStyle(Theme.subtleCardGradient), in: RoundedRectangle(cornerRadius: Theme.radiusSmall, style: .continuous))
                    .foregroundStyle(isActive ? Theme.inkSoft : Theme.accent)
            }
            .disabled(isActive)
        }
        .padding(14)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous).strokeBorder(isActive ? Theme.accent.opacity(0.5) : Theme.hairline, lineWidth: 1))
        .accessibilityElement(children: .contain)
    }

    // MARK: - Actions

    private func applyPalette(_ palette: Palette) {
        studio.applyPalette(palette)
        Haptics.success(enabled: settings.hapticsEnabled)
        toast = Toast(kind: .success, message: "“\(palette.name)” set as active palette")
    }

    private func startNewPalette() {
        if !isPro && customPalettes.count >= Pro.freeCustomPaletteLimit {
            Haptics.warning(enabled: settings.hapticsEnabled)
            showPaywall = true
            return
        }
        editorPalette = nil
        showEditor = true
    }

    private func deleteCustom(_ palette: CustomPalette?) {
        guard let palette else { return }
        modelContext.delete(palette)
        try? modelContext.save()
        Haptics.warning(enabled: settings.hapticsEnabled)
        toast = Toast(kind: .info, message: "Palette deleted")
    }

    private func handleEditorResult(_ result: PaletteEditorResult?) {
        showEditor = false
        guard let result else { return }
        if let existing = editorPalette {
            existing.name = result.name
            existing.hexes = result.hexes
            try? modelContext.save()
            toast = Toast(kind: .success, message: "Palette updated")
        } else {
            if !isPro && customPalettes.count >= Pro.freeCustomPaletteLimit {
                showPaywall = true
                return
            }
            let model = CustomPalette(name: result.name, hexes: result.hexes)
            modelContext.insert(model)
            try? modelContext.save()
            toast = Toast(kind: .success, message: "Palette created")
        }
        Haptics.success(enabled: settings.hapticsEnabled)
        editorPalette = nil
    }
}

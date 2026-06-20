import SwiftUI
import SwiftData

struct HomeView: View {
    var engine: BinauralEngine
    var onSelectPreset: (HaloPreset) -> Void

    @Environment(\.modelContext) private var modelContext
    @Query private var settingsQuery: [HaloSettings]

    @State private var selectedCategory: BrainwaveCategory? = nil
    @State private var selectedPreset: HaloPreset? = nil
    @State private var showDetail = false

    private var settings: HaloSettings {
        settingsQuery.first ?? HaloSettings()
    }

    private var filteredPresets: [HaloPreset] {
        if let cat = selectedCategory {
            return HaloPreset.presets.filter { $0.category == cat }
        }
        return HaloPreset.presets
    }

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                HaloTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: HaloTheme.spacingM) {
                        headerSection
                        categoryFilterSection
                        presetsGrid
                    }
                    .padding(.horizontal, HaloTheme.spacingM)
                    .padding(.bottom, engine.isPlaying ? 120 : 32)
                }
            }
            .navigationTitle("Halo")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(HaloTheme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .sheet(isPresented: $showDetail) {
            if let preset = selectedPreset {
                PresetDetailView(
                    preset: preset,
                    engine: engine,
                    settings: settings,
                    onBegin: { timerMinutes, moodBefore in
                        showDetail = false
                        engine.isNoiseEnabled = settings.ambientNoiseEnabled
                        engine.noiseLevel = settings.ambientNoiseLevel
                        if timerMinutes > 0 {
                            engine.setTimer(duration: TimeInterval(timerMinutes * 60))
                        } else {
                            engine.setTimer(duration: 0)
                        }
                        onSelectPreset(preset)
                        engine.start(preset: preset)
                    }
                )
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Tune your mind.")
                .font(HaloTheme.captionFont)
                .foregroundColor(HaloTheme.accent)
                .textCase(.uppercase)
                .tracking(1.5)
        }
        .padding(.top, 8)
    }

    private var categoryFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: HaloTheme.spacingS) {
                CategoryChip(
                    title: "All",
                    isSelected: selectedCategory == nil,
                    color: HaloTheme.primary
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedCategory = nil
                    }
                }
                ForEach(BrainwaveCategory.allCases) { category in
                    CategoryChip(
                        title: category.rawValue,
                        isSelected: selectedCategory == category,
                        color: category.color
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = (selectedCategory == category) ? nil : category
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var presetsGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(filteredPresets) { preset in
                PresetCard(
                    preset: preset,
                    isLocked: preset.isPro && !settings.hasPro,
                    isActive: engine.isPlaying && engine.sessionPreset?.id == preset.id
                ) {
                    selectedPreset = preset
                    showDetail = true
                }
            }
        }
    }
}

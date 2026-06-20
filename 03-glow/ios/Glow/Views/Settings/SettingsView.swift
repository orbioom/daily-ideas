import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsArray: [GlowSettings]
    @Query private var products: [SavedProduct]

    @State private var selectedSkinTypes: Set<SkinType> = []
    @State private var selectedConcerns: Set<String> = []
    @State private var showingProAlert = false
    @State private var showingExportAlert = false

    private let skinConcerns = [
        "Acne", "Anti-aging", "Sensitivity", "Hyperpigmentation",
        "Dryness", "Oiliness", "Rosacea", "Eczema"
    ]

    private var settings: GlowSettings? { settingsArray.first }

    var body: some View {
        NavigationStack {
            Form {
                skinTypeSection
                skinConcernsSection
                proSection
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .onAppear { loadSettings() }
            .onChange(of: selectedSkinTypes) { _, _ in saveSettings() }
            .onChange(of: selectedConcerns) { _, _ in saveSettings() }
            .alert("Glow Pro", isPresented: $showingProAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Unlock for $3.99") {}
            } message: {
                Text("One-time purchase. Unlock unlimited saved products, skin-type-filtered search results, ingredient watchlist, and CSV export of your product library.")
            }
            .alert("Export Coming Soon", isPresented: $showingExportAlert) {
                Button("OK") {}
            } message: {
                Text("CSV export of your saved products will be available in a future update with Glow Pro.")
            }
        }
    }

    // MARK: - Sections

    private var skinTypeSection: some View {
        Section {
            VStack(alignment: .leading, spacing: GlowTheme.mediumSpacing) {
                Text("Select all that apply to you. Glow uses this to flag ingredients to avoid.")
                    .font(GlowTheme.captionFont)
                    .foregroundStyle(.secondary)

                SkinTypeSelectionGrid(selectedTypes: $selectedSkinTypes)
                    .padding(.vertical, 4)
            }
        } header: {
            Text("Your Skin Type")
        }
    }

    private var skinConcernsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: GlowTheme.mediumSpacing) {
                Text("Select your primary skin concerns for personalized guidance.")
                    .font(GlowTheme.captionFont)
                    .foregroundStyle(.secondary)

                FlowLayout(spacing: 8) {
                    ForEach(skinConcerns, id: \.self) { concern in
                        ConcernChip(
                            label: concern,
                            isSelected: selectedConcerns.contains(concern),
                            onTap: {
                                if selectedConcerns.contains(concern) {
                                    selectedConcerns.remove(concern)
                                } else {
                                    selectedConcerns.insert(concern)
                                }
                            }
                        )
                    }
                }
                .padding(.vertical, 4)
            }
        } header: {
            Text("Skin Concerns")
        }
    }

    private var proSection: some View {
        Section {
            if settings?.hasPro == true {
                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(.orange)
                    Text("Glow Pro Active")
                        .font(.system(.callout, design: .rounded, weight: .semibold))
                    Spacer()
                    Text("Unlimited")
                        .font(GlowTheme.captionFont)
                        .foregroundStyle(.secondary)
                }

                Button(action: { showingExportAlert = true }) {
                    Label("Export Library as CSV", systemImage: "square.and.arrow.up")
                        .font(GlowTheme.bodyFont)
                }
            } else {
                proUpsellCard
            }

            HStack {
                Text("Saved Products")
                    .font(GlowTheme.bodyFont)
                Spacer()
                Text("\(products.count) / \(settings?.hasPro == true ? "∞" : "5")")
                    .font(GlowTheme.captionFont)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Glow Pro")
        }
    }

    private var proUpsellCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "crown.fill")
                    .foregroundStyle(.orange)
                Text("Unlock Glow Pro")
                    .font(.system(.callout, design: .rounded, weight: .bold))
                    .foregroundStyle(GlowTheme.textPrimary)
            }

            VStack(alignment: .leading, spacing: 6) {
                proFeatureRow(icon: "infinity", text: "Unlimited saved products")
                proFeatureRow(icon: "person.fill.checkmark", text: "Skin-type filtered search results")
                proFeatureRow(icon: "star.fill", text: "Ingredient watchlist & allergen alerts")
                proFeatureRow(icon: "square.and.arrow.up", text: "CSV export of your library")
            }

            Button(action: { showingProAlert = true }) {
                Text("Unlock for $3.99 — One Time")
                    .font(.system(.callout, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(GlowTheme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 4)
    }

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Database Version")
                Spacer()
                Text("v1.0 — \(IngredientDatabase.all.count) ingredients")
                    .foregroundStyle(.secondary)
                    .font(GlowTheme.captionFont)
            }

            HStack {
                Text("App Version")
                Spacer()
                Text("1.0.0")
                    .foregroundStyle(.secondary)
                    .font(GlowTheme.captionFont)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Data Sources")
                    .font(GlowTheme.bodyFont)
                Text("EWG Skin Deep, CosIng (EU), ECHA, published peer-reviewed literature. For informational use only — not medical advice.")
                    .font(GlowTheme.captionFont)
                    .foregroundStyle(.secondary)
            }

            Link(destination: URL(string: "https://www.ewg.org/skindeep/")!) {
                Label("EWG Skin Deep Database", systemImage: "safari")
                    .font(GlowTheme.bodyFont)
            }
        } header: {
            Text("About")
        }
    }

    // MARK: - Supporting Views

    private func proFeatureRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(GlowTheme.accent)
                .frame(width: 18)
            Text(text)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(GlowTheme.textPrimary)
        }
    }

    // MARK: - Data

    private func loadSettings() {
        guard let s = settings else { return }
        selectedSkinTypes = Set(s.userSkinTypes)
        selectedConcerns = Set(s.savedSkinConcerns)
    }

    private func saveSettings() {
        if let existing = settings {
            existing.userSkinTypes = Array(selectedSkinTypes)
            existing.savedSkinConcerns = Array(selectedConcerns)
        } else {
            let newSettings = GlowSettings(
                hasCompletedOnboarding: true,
                skinTypesRaw: selectedSkinTypes.map(\.rawValue).joined(separator: ","),
                skinConcernsRaw: selectedConcerns.joined(separator: ",")
            )
            modelContext.insert(newSettings)
        }
    }
}

struct ConcernChip: View {
    let label: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundStyle(isSelected ? .white : .secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: GlowTheme.chipCornerRadius)
                        .fill(isSelected ? GlowTheme.primary : Color(.systemFill))
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [SavedProduct.self, GlowSettings.self], inMemory: true)
}

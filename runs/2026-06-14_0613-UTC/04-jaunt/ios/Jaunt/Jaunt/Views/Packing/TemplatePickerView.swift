import SwiftUI
import SwiftData

/// Pick a starter packing template. Free users may use their default template;
/// all templates unlock with Pro.
struct TemplatePickerView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Bindable var trip: Trip

    @State private var paywallReason: PaywallReason?
    @State private var confirmTemplate: PackingEngine.Template?

    private func isLocked(_ template: PackingEngine.Template) -> Bool {
        !isPro && template != settings.defaultPackingTemplate
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    Text("Add a curated set of items to your packing list. You can edit or remove anything afterwards.")
                        .font(Theme.font(.subheadline))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(PackingEngine.Template.allCases) { template in
                        templateCard(template)
                    }
                }
                .padding(16)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Done") { dismiss() } }
            }
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
            .confirmationDialog("Add \(confirmTemplate?.rawValue ?? "") items?",
                                isPresented: Binding(get: { confirmTemplate != nil },
                                                     set: { if !$0 { confirmTemplate = nil } }),
                                titleVisibility: .visible) {
                if let template = confirmTemplate {
                    Button("Add \(PackingEngine.seeds(for: template).count) items") { apply(template) }
                    Button("Cancel", role: .cancel) { confirmTemplate = nil }
                }
            } message: {
                Text("Duplicates of items you already have will be skipped.")
            }
        }
    }

    private func templateCard(_ template: PackingEngine.Template) -> some View {
        let locked = isLocked(template)
        return Button {
            if locked {
                Haptics.warning()
                paywallReason = .templates
            } else {
                Haptics.tap()
                confirmTemplate = template
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous)
                        .fill(Theme.accent.opacity(0.14))
                        .frame(width: 48, height: 48)
                    Image(systemName: template.symbol)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                }
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(template.rawValue)
                            .font(Theme.font(.headline))
                            .foregroundStyle(Theme.textPrimary)
                        if template == settings.defaultPackingTemplate {
                            Text("Default")
                                .font(Theme.font(.caption2, weight: .bold))
                                .foregroundStyle(Theme.accent)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Capsule().fill(Theme.accent.opacity(0.14)))
                        }
                    }
                    Text(template.subtitle)
                        .font(Theme.font(.caption))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Image(systemName: locked ? "lock.fill" : "plus.circle")
                    .foregroundStyle(locked ? Theme.textSecondary : Theme.accent)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous).fill(Theme.surface))
            .overlay(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous).strokeBorder(Theme.separator, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(template.rawValue) template, \(template.subtitle)")
        .accessibilityHint(locked ? "Locked, requires Jaunt Pro" : "Adds items to your packing list")
    }

    private func apply(_ template: PackingEngine.Template) {
        let existingNames = Set(trip.packItems.map { $0.name.lowercased() })
        for seed in PackingEngine.seeds(for: template) where !existingNames.contains(seed.name.lowercased()) {
            context.insert(seed)
            seed.trip = trip
        }
        Haptics.success()
        confirmTemplate = nil
        dismiss()
    }
}

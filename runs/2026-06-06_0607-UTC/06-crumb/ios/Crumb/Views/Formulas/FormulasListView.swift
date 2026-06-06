import SwiftUI
import SwiftData

/// The formula library: every saved recipe, with a quick read on its baker's figures.
struct FormulasListView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var context
    @Query(sort: \Formula.createdAt, order: .reverse) private var formulas: [Formula]

    @State private var editingFormula: Formula?
    @State private var creating = false
    @State private var pendingDelete: Formula?

    var body: some View {
        NavigationStack {
            Group {
                if formulas.isEmpty {
                    EmptyStateView(
                        icon: "list.bullet.rectangle",
                        title: "No formulas yet",
                        message: "Add your first recipe in baker's percentages, then scale it to any dough weight.",
                        actionTitle: "New formula",
                        action: { creating = true }
                    )
                } else {
                    list
                }
            }
            .background(Brand.pageBackground)
            .navigationTitle("Formulas")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        creating = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("New formula")
                }
            }
            .navigationDestination(for: Formula.self) { formula in
                FormulaDetailView(formula: formula)
            }
        }
        .sheet(isPresented: $creating) {
            FormulaEditView(formula: nil)
        }
        .sheet(item: $editingFormula) { formula in
            FormulaEditView(formula: formula)
        }
        .alert("Delete formula?", isPresented: .constant(pendingDelete != nil), presenting: pendingDelete) { formula in
            Button("Delete", role: .destructive) { delete(formula) }
            Button("Cancel", role: .cancel) { pendingDelete = nil }
        } message: { formula in
            Text("\"\(formula.name)\" and its bakes will be removed. This can't be undone.")
        }
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(formulas) { formula in
                    NavigationLink(value: formula) {
                        FormulaRow(formula: formula)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button {
                            editingFormula = formula
                        } label: { Label("Edit", systemImage: "pencil") }
                        Button(role: .destructive) {
                            pendingDelete = formula
                        } label: { Label("Delete", systemImage: "trash") }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
    }

    private func delete(_ formula: Formula) {
        context.delete(formula)
        Haptics.warning(enabled: settings.hapticsEnabled)
        pendingDelete = nil
    }
}

/// A single formula card showing name, style, and a few solved headline figures
/// at the formula's nominal dough weight.
private struct FormulaRow: View {
    @Environment(SettingsStore.self) private var settings
    var formula: Formula

    private var result: BakersMath.Result {
        let rows = formula.orderedIngredients.map {
            BakersMath.Row(id: $0.id, name: $0.name, role: $0.role,
                           percent: $0.percent, levainHydration: $0.levainHydration)
        }
        return BakersMath.solve(rows: rows,
                                target: .totalDough(grams: settings.defaultDoughGrams))
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: formula.style.symbol)
                        .font(.title3)
                        .foregroundStyle(Brand.text)
                        .frame(width: 30)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(formula.name)
                            .font(.headline)
                            .foregroundStyle(Brand.text)
                            .lineLimit(1)
                        Text(formula.style.title)
                            .font(.caption)
                            .foregroundStyle(Brand.text3)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Brand.text3)
                        .accessibilityHidden(true)
                }

                if result.hasFlour {
                    HStack(spacing: 16) {
                        MetricTile(label: "Hydration",
                                   value: "\(BakersMath.displayPercent(result.hydrationPercent))%",
                                   accent: Brand.roleColor(.water))
                        MetricTile(label: "Levain",
                                   value: "\(BakersMath.displayPercent(result.levainPercent))%",
                                   accent: Brand.roleColor(.levain))
                        MetricTile(label: "Salt",
                                   value: "\(BakersMath.displayPercent(result.saltPercent))%",
                                   accent: Brand.roleColor(.salt))
                    }
                } else {
                    Text("Add a flour to see hydration")
                        .font(.caption)
                        .foregroundStyle(Brand.text3)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    let container = PreviewSupport.container()
    return FormulasListView()
        .environment(SettingsStore())
        .modelContainer(container)
}

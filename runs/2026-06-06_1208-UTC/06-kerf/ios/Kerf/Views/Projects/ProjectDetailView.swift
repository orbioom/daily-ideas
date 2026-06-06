import SwiftUI
import SwiftData

/// A project's parts and stock, with the entry point to the cut plan.
struct ProjectDetailView: View {
    @Bindable var project: Project
    @Environment(\.modelContext) private var context
    @AppStorage("lengthUnit") private var unitRaw = LengthUnit.mm.rawValue

    @State private var editingProject = false
    @State private var addingPart = false
    @State private var editingPart: Part?
    @State private var addingStock = false
    @State private var editingStock: StockBoard?
    @State private var showPlan = false

    private var unit: LengthUnit { LengthUnit(rawValue: unitRaw) ?? .mm }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                summary
                partsSection
                stockSection
                Button { showPlan = true } label: { Label("Optimize cut plan", systemImage: "wand.and.stars") }
                    .buttonStyle(InkButtonStyle())
                    .disabled(project.parts.isEmpty || project.stock.isEmpty)
                if project.parts.isEmpty || project.stock.isEmpty {
                    Text("Add at least one part and one stock board to optimize.")
                        .font(.caption).foregroundStyle(Brand.text3)
                }
            }
            .padding(.horizontal, 16).padding(.bottom, 32)
        }
        .background(Brand.pageBackground)
        .navigationTitle(project.name.isEmpty ? "Project" : project.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { editingProject = true } label: { Image(systemName: "pencil") }.accessibilityLabel("Edit project")
            }
        }
        .navigationDestination(isPresented: $showPlan) { CutPlanView(project: project) }
        .sheet(isPresented: $editingProject) { ProjectEditView(project: project, isNew: false) }
        .sheet(isPresented: $addingPart) { PartEditView(part: nil) { add($0) } }
        .sheet(item: $editingPart) { p in PartEditView(part: p) { _ in try? context.save() } }
        .sheet(isPresented: $addingStock) { StockEditView(stock: nil) { addStock($0) } }
        .sheet(item: $editingStock) { s in StockEditView(stock: s) { _ in try? context.save() } }
    }

    private var summary: some View {
        HStack(spacing: 10) {
            StatTile(value: "\(project.totalPieces)", label: "Pieces")
            StatTile(value: unit.string(project.totalRequiredLength), label: "Total length", tint: Brand.text)
            StatTile(value: unit.string(project.kerfMm), label: "Kerf")
        }
    }

    private var partsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Eyebrow(text: "Parts to cut")
                Spacer()
                Button { addingPart = true } label: { Image(systemName: "plus") }.accessibilityLabel("Add part")
            }
            if project.parts.isEmpty {
                EmptyStateView(icon: "ruler", title: "No parts", message: "Add the pieces you need to cut.")
                    .glassCard()
            } else {
                ForEach(project.orderedParts) { part in
                    Button { editingPart = part } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(part.label.isEmpty ? "Part" : part.label).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                                Text("\(part.quantity) × \(unit.string(part.lengthMm))").font(.caption).foregroundStyle(Brand.text3)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.footnote).foregroundStyle(Brand.text3)
                        }
                        .glassCard()
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) { delete(part) } label: { Label("Delete", systemImage: "trash") }
                    }
                }
            }
        }
    }

    private var stockSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Eyebrow(text: "Stock available")
                Spacer()
                Button { addingStock = true } label: { Image(systemName: "plus") }.accessibilityLabel("Add stock")
            }
            if project.stock.isEmpty {
                EmptyStateView(icon: "rectangle.split.3x1", title: "No stock", message: "Add the boards you'll cut from.")
                    .glassCard()
            } else {
                ForEach(project.orderedStock) { board in
                    Button { editingStock = board } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(board.label.isEmpty ? "Board" : board.label).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                                Text("\(unit.string(board.lengthMm)) · \(board.isUnlimited ? "unlimited" : "\(board.quantity) available")")
                                    .font(.caption).foregroundStyle(Brand.text3)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.footnote).foregroundStyle(Brand.text3)
                        }
                        .glassCard()
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) { deleteStock(board) } label: { Label("Delete", systemImage: "trash") }
                    }
                }
            }
        }
    }

    private func add(_ part: Part) { part.project = project; project.parts.append(part); touch() }
    private func addStock(_ s: StockBoard) { s.project = project; project.stock.append(s); touch() }
    private func delete(_ part: Part) { context.delete(part); touch(); Haptics.warning() }
    private func deleteStock(_ s: StockBoard) { context.delete(s); touch(); Haptics.warning() }
    private func touch() { project.updatedAt = Date(); try? context.save() }
}

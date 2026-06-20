import SwiftUI
import SwiftData

struct MaterialsShoppingView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Material.createdAt) private var allMaterials: [Material]

    @State private var showOnlyUnpurchased = true

    var displayed: [Material] {
        showOnlyUnpurchased ? allMaterials.filter { !$0.purchased } : allMaterials
    }

    var totalUnpurchased: Double { allMaterials.filter { !$0.purchased }.reduce(0) { $0 + $1.totalCost } }
    var totalPurchased: Double { allMaterials.filter { $0.purchased }.reduce(0) { $0 + $1.totalCost } }

    var groupedByProject: [(String, [Material])] {
        var groups: [String: [Material]] = [:]
        for mat in displayed {
            let key = mat.project?.name ?? "Unknown Project"
            groups[key, default: []].append(mat)
        }
        return groups.sorted { $0.key < $1.key }
    }

    var body: some View {
        NavigationStack {
            Group {
                if allMaterials.isEmpty {
                    emptyState
                } else {
                    List {
                        Section {
                            HStack(spacing: 20) {
                                statItem("To Buy", String(format: "$%.0f", totalUnpurchased), color: ScaffoldTheme.accent)
                                Divider()
                                statItem("Purchased", String(format: "$%.0f", totalPurchased), color: .green)
                                Divider()
                                statItem("Total", String(format: "$%.0f", totalUnpurchased + totalPurchased), color: ScaffoldTheme.secondaryLabel)
                            }
                            .frame(height: 56)
                        }

                        Section {
                            Toggle("Show only unpurchased", isOn: $showOnlyUnpurchased)
                                .accessibilityLabel("Show only unpurchased materials")
                        }

                        if displayed.isEmpty {
                            Section {
                                Text("All materials purchased! 🎉")
                                    .foregroundColor(ScaffoldTheme.secondaryLabel)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .accessibilityLabel("All materials purchased")
                            }
                        } else {
                            ForEach(groupedByProject, id: \.0) { projectName, materials in
                                Section(projectName) {
                                    ForEach(materials) { material in
                                        ShoppingMaterialRow(material: material)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Shopping List")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func statItem(_ label: String, _ value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(ScaffoldTheme.secondaryLabel)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "cart")
                .font(.system(size: 56))
                .foregroundColor(ScaffoldTheme.secondaryLabel)
                .accessibilityHidden(true)
            Text("No Materials Yet")
                .font(.title2.bold())
            Text("Add materials to your projects\nand they'll appear here.")
                .multilineTextAlignment(.center)
                .foregroundColor(ScaffoldTheme.secondaryLabel)
        }
        .padding()
    }
}

struct ShoppingMaterialRow: View {
    @Environment(\.modelContext) private var context
    @Bindable var material: Material

    var body: some View {
        HStack {
            Button(action: { material.purchased.toggle(); try? context.save() }) {
                Image(systemName: material.purchased ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(material.purchased ? .green : ScaffoldTheme.secondaryLabel)
                    .font(.title3)
            }
            .accessibilityLabel(material.purchased ? "Mark as not purchased" : "Mark as purchased")

            VStack(alignment: .leading, spacing: 2) {
                Text(material.name)
                    .strikethrough(material.purchased)
                    .foregroundColor(material.purchased ? ScaffoldTheme.secondaryLabel : ScaffoldTheme.label)
                if !material.vendor.isEmpty {
                    Text("@ \(material.vendor)")
                        .font(.caption)
                        .foregroundColor(ScaffoldTheme.secondaryLabel)
                }
            }
            Spacer()
            if material.unitCost > 0 {
                VStack(alignment: .trailing) {
                    Text(String(format: "$%.2f", material.totalCost))
                        .font(.subheadline.weight(.semibold))
                    Text("\(material.quantity) \(material.unit)")
                        .font(.caption2)
                        .foregroundColor(ScaffoldTheme.secondaryLabel)
                }
            } else {
                Text("\(material.quantity) \(material.unit)")
                    .font(.caption)
                    .foregroundColor(ScaffoldTheme.secondaryLabel)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(material.name)\(material.purchased ? ", purchased" : ", not purchased")")
    }
}

struct AddMaterialView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let project: Project

    @State private var name = ""
    @State private var quantity = "1"
    @State private var unit = "unit"
    @State private var unitCost = ""
    @State private var vendor = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Material") {
                    TextField("Name (e.g. Tiles, Paint)", text: $name)
                        .accessibilityLabel("Material name")
                    HStack {
                        TextField("Qty", text: $quantity)
                            .keyboardType(.numberPad)
                            .frame(width: 60)
                            .accessibilityLabel("Quantity")
                        TextField("Unit", text: $unit)
                            .accessibilityLabel("Unit of measurement")
                    }
                }
                Section("Cost") {
                    HStack {
                        Text("$")
                        TextField("Unit cost", text: $unitCost)
                            .keyboardType(.decimalPad)
                            .accessibilityLabel("Unit cost")
                    }
                    TextField("Vendor / Store", text: $vendor)
                        .accessibilityLabel("Vendor or store name")
                }
                Section("Notes") {
                    TextField("Notes", text: $notes)
                        .accessibilityLabel("Notes")
                }
            }
            .navigationTitle("Add Material")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let n = name.trimmingCharacters(in: .whitespaces)
        guard !n.isEmpty else { return }
        let qty = Int(quantity) ?? 1
        let cost = Double(unitCost.replacingOccurrences(of: ",", with: ".")) ?? 0
        let mat = Material(name: n, quantity: max(1, qty), unit: unit.isEmpty ? "unit" : unit, unitCost: cost, project: project)
        mat.vendor = vendor
        mat.notes = notes
        context.insert(mat)
        try? context.save()
        dismiss()
    }
}

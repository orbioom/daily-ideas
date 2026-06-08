import SwiftUI
import SwiftData

struct PlanEditView: View {
    var plan: Plan?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var allPlans: [Plan]

    @State private var name = ""
    @State private var fastHours = 16.0
    @State private var detail = ""

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && fastHours >= 1 && fastHours <= 48
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section("Name") {
                        TextField("e.g. 17:7", text: $name)
                    }
                    Section("Fasting window") {
                        Stepper(value: $fastHours, in: 1...48, step: 0.5) {
                            HStack {
                                Text("Fast")
                                Spacer()
                                Text("\(Format.hours(fastHours))h")
                                    .font(Brand.mono(15))
                                    .foregroundStyle(Brand.text2)
                            }
                        }
                        HStack {
                            Text("Eating window")
                            Spacer()
                            Text("\(Format.hours(max(0, 24 - fastHours)))h")
                                .font(Brand.mono(15))
                                .foregroundStyle(Brand.text3)
                        }
                    }
                    Section("Description") {
                        TextField("Optional note", text: $detail, axis: .vertical)
                            .lineLimit(1...3)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(plan == nil ? "New plan" : "Edit plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(!isValid)
                }
            }
            .onAppear {
                if let plan {
                    name = plan.name; fastHours = plan.fastHours; detail = plan.detail
                }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let text = detail.trimmingCharacters(in: .whitespaces)
        let finalDetail = text.isEmpty ? "Custom protocol" : text
        if let plan {
            plan.name = trimmed; plan.fastHours = fastHours; plan.detail = finalDetail
        } else {
            let order = (allPlans.map(\.order).max() ?? 0) + 1
            context.insert(Plan(name: trimmed, fastHours: fastHours, detail: finalDetail, isCustom: true, order: order))
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}

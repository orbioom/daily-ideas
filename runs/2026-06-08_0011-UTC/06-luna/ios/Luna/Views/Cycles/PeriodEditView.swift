import SwiftUI
import SwiftData

struct PeriodEditView: View {
    var period: Period?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var start = Calendar.current.startOfDay(for: .now)
    @State private var hasEnd = true
    @State private var end = Calendar.current.startOfDay(for: .now)

    private var isValid: Bool { !hasEnd || end >= start }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section("Start") {
                        DatePicker("Period started", selection: $start, in: ...Date(), displayedComponents: .date)
                    }
                    Section("End") {
                        Toggle("Has ended", isOn: $hasEnd)
                        if hasEnd {
                            DatePicker("Period ended", selection: $end, in: start...Date(), displayedComponents: .date)
                        }
                    }
                    if !isValid {
                        Text("End date must be on or after the start date.")
                            .font(.footnote).foregroundStyle(Brand.danger)
                    }
                    if period != nil {
                        Section {
                            Button(role: .destructive) {
                                if let p = period { context.delete(p); try? context.save(); Haptics.warning() }
                                dismiss()
                            } label: { Label("Delete this period", systemImage: "trash") }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(period == nil ? "Add period" : "Edit period")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(!isValid) }
            }
            .onAppear {
                if let p = period {
                    start = p.startDate
                    if let e = p.endDate { hasEnd = true; end = e } else { hasEnd = false; end = start }
                }
            }
        }
    }

    private func save() {
        let s = Calendar.current.startOfDay(for: start)
        let e = hasEnd ? Calendar.current.startOfDay(for: end) : nil
        if let p = period {
            p.startDate = s; p.endDate = e
        } else {
            context.insert(Period(startDate: s, endDate: e))
        }
        try? context.save(); Haptics.success(); dismiss()
    }
}

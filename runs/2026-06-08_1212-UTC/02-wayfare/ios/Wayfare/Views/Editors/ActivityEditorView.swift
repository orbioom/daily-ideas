import SwiftUI
import SwiftData

struct ActivityEditorView: View {
    @Bindable var activity: Activity
    let trip: Trip
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section {
                        TextField("Title", text: $activity.title)
                        Picker("Category", selection: Binding(
                            get: { activity.category },
                            set: { activity.category = $0 }
                        )) {
                            ForEach(ActivityCategory.allCases) { c in
                                Label(c.label, systemImage: c.symbol).tag(c)
                            }
                        }
                    }
                    Section("When") {
                        DatePicker("Day", selection: $activity.startTime, displayedComponents: .date)
                        Toggle("Set a time", isOn: $activity.hasTime)
                        if activity.hasTime {
                            DatePicker("Time", selection: $activity.startTime, displayedComponents: .hourAndMinute)
                        }
                    }
                    Section("Details") {
                        TextField("Location", text: $activity.location)
                        HStack {
                            Text("Cost")
                            Spacer()
                            TextField("0", value: $activity.cost, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 120)
                        }
                        Toggle("Booked / confirmed", isOn: $activity.booked)
                        TextField("Notes", text: $activity.notes, axis: .vertical)
                            .lineLimit(2...6)
                    }
                    Section {
                        Button(role: .destructive) {
                            context.delete(activity); Haptics.warning(); dismiss()
                        } label: {
                            Label("Delete plan", systemImage: "trash").frame(maxWidth: .infinity)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { cancelIfEmpty() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { save() }.fontWeight(.semibold)
                }
            }
        }
    }

    private func cancelIfEmpty() {
        if activity.title.trimmingCharacters(in: .whitespaces).isEmpty {
            context.delete(activity)
        }
        dismiss()
    }

    private func save() {
        if activity.title.trimmingCharacters(in: .whitespaces).isEmpty {
            activity.title = activity.category.label
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}

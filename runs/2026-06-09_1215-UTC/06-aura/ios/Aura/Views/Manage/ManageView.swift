import SwiftUI
import SwiftData

struct ManageView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        TriggersManageView()
                    } label: {
                        Label("Triggers", systemImage: "scope")
                    }
                    NavigationLink {
                        SymptomsManageView()
                    } label: {
                        Label("Symptoms", systemImage: "waveform.path.ecg")
                    }
                    NavigationLink {
                        MedicationsManageView()
                    } label: {
                        Label("Medications", systemImage: "pills")
                    }
                } footer: {
                    Text("Add or remove your own triggers, symptoms, and medications. Built-ins can't be deleted. Removing a custom item won't break past attacks — it's simply unlinked.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle("Manage")
        }
    }
}

// MARK: - Triggers

struct TriggersManageView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Trigger.name) private var triggers: [Trigger]
    @State private var showAdd = false
    @State private var name = ""
    @State private var category: TriggerCategory = .other

    var body: some View {
        List {
            ForEach(TriggerCategory.allCases) { cat in
                let items = triggers.filter { $0.category == cat }
                if !items.isEmpty {
                    Section(cat.label) {
                        ForEach(items) { trigger in
                            HStack {
                                Image(systemName: cat.symbol)
                                    .foregroundStyle(Brand.info)
                                    .accessibilityHidden(true)
                                Text(trigger.name).foregroundStyle(Brand.text)
                                Spacer()
                                if trigger.isBuiltIn {
                                    Text("Built-in").font(.caption).foregroundStyle(Brand.text3)
                                }
                            }
                        }
                        .onDelete { offsets in delete(items, offsets) }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Brand.pageBackground)
        .navigationTitle("Triggers")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showAdd) {
            NavigationStack {
                Form {
                    TextField("Name", text: $name)
                    Picker("Category", selection: $category) {
                        ForEach(TriggerCategory.allCases) { Text($0.label).tag($0) }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Brand.pageBackground)
                .navigationTitle("New Trigger")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { reset() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") { add() }
                            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
        }
    }

    private func add() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        context.insert(Trigger(name: trimmed, category: category, isBuiltIn: false))
        try? context.save()
        Haptics.success()
        reset()
    }

    private func reset() {
        name = ""; category = .other; showAdd = false
    }

    private func delete(_ items: [Trigger], _ offsets: IndexSet) {
        for index in offsets {
            let item = items[index]
            guard !item.isBuiltIn else { continue }
            context.delete(item)   // many-to-many: SwiftData unlinks from attacks safely
        }
        try? context.save()
        Haptics.warning()
    }
}

// MARK: - Symptoms

struct SymptomsManageView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Symptom.name) private var symptoms: [Symptom]
    @State private var showAdd = false
    @State private var name = ""

    var body: some View {
        List {
            Section {
                ForEach(symptoms) { symptom in
                    HStack {
                        Text(symptom.name).foregroundStyle(Brand.text)
                        Spacer()
                        if symptom.isBuiltIn {
                            Text("Built-in").font(.caption).foregroundStyle(Brand.text3)
                        }
                    }
                }
                .onDelete(perform: delete)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Brand.pageBackground)
        .navigationTitle("Symptoms")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .alert("New symptom", isPresented: $showAdd) {
            TextField("Name", text: $name)
            Button("Add") { add() }
            Button("Cancel", role: .cancel) { name = "" }
        }
    }

    private func add() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        name = ""
        guard !trimmed.isEmpty else { return }
        context.insert(Symptom(name: trimmed, isBuiltIn: false))
        try? context.save()
        Haptics.success()
    }

    private func delete(_ offsets: IndexSet) {
        for index in offsets {
            let item = symptoms[index]
            guard !item.isBuiltIn else { continue }
            context.delete(item)
        }
        try? context.save()
        Haptics.warning()
    }
}

// MARK: - Medications

struct MedicationsManageView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Medication.name) private var meds: [Medication]
    @State private var showAdd = false
    @State private var name = ""
    @State private var type: MedType = .acute
    @State private var dose = 0.0

    var body: some View {
        List {
            ForEach(MedType.allCases) { medType in
                let items = meds.filter { $0.type == medType }
                if !items.isEmpty {
                    Section(medType.label) {
                        ForEach(items) { med in
                            HStack {
                                Text(med.name).foregroundStyle(Brand.text)
                                Spacer()
                                Text(Format.dose(med.defaultDoseMg))
                                    .font(Brand.mono(13)).foregroundStyle(Brand.text2)
                                if med.isBuiltIn {
                                    Text("Built-in").font(.caption).foregroundStyle(Brand.text3)
                                }
                            }
                        }
                        .onDelete { offsets in delete(items, offsets) }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Brand.pageBackground)
        .navigationTitle("Medications")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showAdd) {
            NavigationStack {
                Form {
                    TextField("Name", text: $name)
                    Picker("Type", selection: $type) {
                        ForEach(MedType.allCases) { Text($0.label).tag($0) }
                    }
                    HStack {
                        Text("Default dose")
                        Spacer()
                        TextField("mg", value: $dose, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 90)
                        Text("mg").foregroundStyle(Brand.text3)
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Brand.pageBackground)
                .navigationTitle("New Medication")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { reset() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") { add() }
                            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
        }
    }

    private func add() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        context.insert(Medication(name: trimmed, type: type, defaultDoseMg: max(0, dose), isBuiltIn: false))
        try? context.save()
        Haptics.success()
        reset()
    }

    private func reset() {
        name = ""; type = .acute; dose = 0; showAdd = false
    }

    private func delete(_ items: [Medication], _ offsets: IndexSet) {
        // MedTaken snapshots name/isAcute, so deleting a catalog entry never
        // orphans past records — they keep their own copy of the data.
        for index in offsets {
            let item = items[index]
            guard !item.isBuiltIn else { continue }
            context.delete(item)
        }
        try? context.save()
        Haptics.warning()
    }
}

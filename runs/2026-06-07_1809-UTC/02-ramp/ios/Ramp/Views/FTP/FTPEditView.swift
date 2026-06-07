import SwiftUI
import SwiftData

/// Add or edit a single FTP entry. `entry == nil` creates a new one.
struct FTPEditView: View {
    let entry: FTPEntry?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @AppStorage("ramp.weightKg") private var weightKg = 72.0

    @State private var wattsText = ""
    @State private var date = Date()
    @State private var source: FTPSource = .test20min
    @State private var notes = ""
    @State private var showDeleteConfirm = false

    private var isEditing: Bool { entry != nil }
    private var watts: Int { Int(wattsText) ?? 0 }
    private var wattsValid: Bool { watts > 0 }
    private var wkg: Double { LoadEngine.wattsPerKg(ftp: watts, weightKg: weightKg) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("FTP")
                        Spacer()
                        TextField("watts", text: $wattsText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 90)
                            .font(Brand.mono(16))
                            .accessibilityLabel("FTP in watts")
                        Text("W").foregroundStyle(Brand.text3)
                    }
                    if wattsValid && weightKg > 0 {
                        InfoRow(label: "Power-to-weight", value: "\(Format.oneDecimal(wkg)) W/kg", mono: true)
                    } else if !wattsValid && !wattsText.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle").foregroundStyle(Brand.warn)
                            Text("FTP must be greater than zero.").font(.caption).foregroundStyle(Brand.warn)
                        }
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    Picker("Source", selection: $source) {
                        ForEach(FTPSource.allCases) { s in Text(s.label).tag(s) }
                    }
                } header: {
                    Text("Value")
                }
                .listRowBackground(Brand.mist2.opacity(0.5))

                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes").font(.caption).foregroundStyle(Brand.text3)
                        TextField("Conditions, protocol…", text: $notes, axis: .vertical)
                            .lineLimit(2...4)
                    }
                } header: {
                    Text("Notes")
                }
                .listRowBackground(Brand.mist2.opacity(0.5))

                if isEditing {
                    Section {
                        Button(role: .destructive) {
                            Haptics.warning(); showDeleteConfirm = true
                        } label: {
                            Label("Delete entry", systemImage: "trash").frame(maxWidth: .infinity)
                        }
                        .confirmationDialog("Delete this FTP entry?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                            Button("Delete", role: .destructive) { deleteEntry() }
                            Button("Cancel", role: .cancel) {}
                        }
                    }
                    .listRowBackground(Brand.mist2.opacity(0.5))
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle(isEditing ? "Edit FTP" : "New FTP")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { Haptics.tap(); dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.fontWeight(.semibold).disabled(!wattsValid)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let entry else { return }
        wattsText = String(entry.watts)
        date = entry.date
        source = entry.source
        notes = entry.notes
    }

    private func save() {
        guard wattsValid else { Haptics.warning(); return }
        if let entry {
            entry.watts = watts
            entry.date = date
            entry.source = source
            entry.notes = notes.trimmingCharacters(in: .whitespaces)
        } else {
            context.insert(FTPEntry(date: date, watts: watts, source: source,
                                    notes: notes.trimmingCharacters(in: .whitespaces)))
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }

    private func deleteEntry() {
        guard let entry else { return }
        context.delete(entry)
        try? context.save()
        Haptics.warning()
        dismiss()
    }
}

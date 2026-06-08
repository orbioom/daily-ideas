import SwiftUI
import SwiftData

struct ProjectEditorView: View {
    @Bindable var project: Project
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Client.name) private var clients: [Client]
    @AppStorage("defaultCurrency") private var currency = Locale.current.currency?.identifier ?? "USD"

    private let palette: [UInt32] = [0x3E8E7E, 0x6E7BA6, 0x9E5E7E, 0xB0814E, 0x3E9E78, 0x4E9EA6, 0x8A5A3E, 0xC0953E]

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section("Project") {
                        TextField("Name", text: $project.name)
                        Picker("Client", selection: Binding(
                            get: { project.client },
                            set: { project.client = $0 }
                        )) {
                            Text("No client").tag(Optional<Client>.none)
                            ForEach(clients) { c in Text(c.name).tag(Optional(c)) }
                        }
                    }
                    Section {
                        Toggle("Billable", isOn: $project.billable)
                        if project.billable {
                            Toggle("Custom rate", isOn: $project.useCustomRate)
                            if project.useCustomRate {
                                HStack {
                                    Text("Rate")
                                    Spacer()
                                    TextField("0", value: $project.customRate, format: .number)
                                        .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 100)
                                    Text("/h").foregroundStyle(Brand.text3)
                                }
                            } else {
                                LabeledContent("Rate (from client)",
                                               value: "\(Money.compact(project.client?.hourlyRate ?? 0, code: currency))/h")
                            }
                        }
                    } header: {
                        Text("Billing")
                    }
                    Section("Color") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 10) {
                            ForEach(palette, id: \.self) { hex in
                                Circle().fill(Color(hex: hex)).frame(width: 28, height: 28)
                                    .overlay(Circle().strokeBorder(.white, lineWidth: project.colorHex == hex ? 3 : 0))
                                    .overlay(Circle().strokeBorder(Brand.hairline, lineWidth: 1))
                                    .onTapGesture { project.colorHex = hex; Haptics.selection() }
                            }
                        }
                    }
                    Section {
                        Button(role: .destructive) {
                            context.delete(project); Haptics.warning(); dismiss()
                        } label: {
                            Label("Delete project", systemImage: "trash").frame(maxWidth: .infinity)
                        }
                    } footer: {
                        Text("Deleting a project also removes its time entries.")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(project.name.isEmpty ? "New Project" : "Edit Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        if project.name.trimmingCharacters(in: .whitespaces).isEmpty { context.delete(project) }
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { try? context.save(); Haptics.success(); dismiss() }
                        .fontWeight(.semibold)
                        .disabled(project.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

import SwiftUI
import SwiftData

struct ClientEditorView: View {
    @Bindable var client: Client
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage("defaultCurrency") private var currency = Locale.current.currency?.identifier ?? "USD"

    private let palette: [UInt32] = [0x3E8E7E, 0x6E7BA6, 0x9E5E7E, 0xB0814E, 0x3E9E78, 0x4E9EA6, 0x8A5A3E, 0xC0953E]

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section("Client") {
                        TextField("Name", text: $client.name)
                        HStack {
                            Text("Default rate")
                            Spacer()
                            TextField("0", value: $client.hourlyRate, format: .number)
                                .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 100)
                            Text("/h").foregroundStyle(Brand.text3)
                        }
                    }
                    Section("Color") {
                        colorRow
                    }
                    Section {
                        Button(role: .destructive) {
                            context.delete(client); Haptics.warning(); dismiss()
                        } label: {
                            Label("Delete client", systemImage: "trash").frame(maxWidth: .infinity)
                        }
                    } footer: {
                        Text("Deleting a client also removes its projects and their time entries.")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(client.name.isEmpty ? "New Client" : "Edit Client")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        if client.name.trimmingCharacters(in: .whitespaces).isEmpty { context.delete(client) }
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { try? context.save(); Haptics.success(); dismiss() }
                        .fontWeight(.semibold)
                        .disabled(client.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private var colorRow: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 10) {
            ForEach(palette, id: \.self) { hex in
                Circle().fill(Color(hex: hex)).frame(width: 28, height: 28)
                    .overlay(Circle().strokeBorder(.white, lineWidth: client.colorHex == hex ? 3 : 0))
                    .overlay(Circle().strokeBorder(Brand.hairline, lineWidth: 1))
                    .onTapGesture { client.colorHex = hex; Haptics.selection() }
            }
        }
    }
}

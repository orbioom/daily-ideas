import SwiftUI

/// A small sheet to name a scenario before saving.
struct SaveScenarioSheet: View {
    @Environment(CalculatorModel.self) private var calc
    @Environment(\.dismiss) private var dismiss
    let onSave: (String) -> Void

    @State private var name: String = ""
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Give this loan a name so you can find it later.")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)

                TextField("e.g. Maple St. mortgage", text: $name)
                    .font(Theme.rounded(17, .semibold))
                    .foregroundStyle(Theme.ink)
                    .focused($focused)
                    .padding(14)
                    .background(Theme.surfaceAlt)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .submitLabel(.done)
                    .onSubmit(save)

                Button(action: save) {
                    Text("Save")
                        .font(Theme.rounded(16, .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .foregroundStyle(Color.white)
                }
                Spacer(minLength: 0)
            }
            .padding(20)
            .background(Theme.bg)
            .navigationTitle("Save scenario")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                name = calc.name
                focused = true
            }
        }
    }

    private func save() {
        onSave(name)
        dismiss()
    }
}

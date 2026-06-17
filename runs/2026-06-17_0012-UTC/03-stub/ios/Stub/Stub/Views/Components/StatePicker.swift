import SwiftUI

/// A searchable list of all states for picking the work state.
struct StatePickerView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCode: String
    @State private var query: String = ""

    private var filtered: [USState] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return StateTaxTable.all }
        return StateTaxTable.all.filter {
            $0.name.lowercased().contains(q) || $0.code.lowercased().contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if filtered.isEmpty {
                    ContentUnavailableView("No match", systemImage: "magnifyingglass",
                                           description: Text("No state matches “\(query)”."))
                } else {
                    ForEach(filtered) { state in
                        Button {
                            selectedCode = state.code
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(state.name)
                                        .foregroundStyle(StubTheme.primaryText(scheme))
                                    Text(state.hasIncomeTax
                                         ? "≈ \(Format.percent(state.effectiveRate)) state income tax"
                                         : "No state income tax")
                                        .font(.caption)
                                        .foregroundStyle(StubTheme.secondaryText(scheme))
                                }
                                Spacer()
                                if state.code == selectedCode {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(StubTheme.green)
                                }
                            }
                        }
                        .accessibilityLabel("\(state.name), \(state.hasIncomeTax ? "approximately \(Format.percent(state.effectiveRate)) state tax" : "no state income tax")")
                    }
                }
            }
            .searchable(text: $query, prompt: "Search states")
            .navigationTitle("Work state")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

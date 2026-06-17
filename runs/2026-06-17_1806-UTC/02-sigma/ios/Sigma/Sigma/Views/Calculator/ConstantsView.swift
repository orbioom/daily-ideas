import SwiftUI

/// The Pro Constants library: a searchable sheet of physics & math constants
/// that can be inserted directly into the calculator.
struct ConstantsView: View {
    let onInsert: (PhysicsConstant) -> Void

    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""

    private var results: [PhysicsConstant] {
        guard !search.isEmpty else { return PhysicsConstants.all }
        let needle = search.lowercased()
        return PhysicsConstants.all.filter {
            $0.name.lowercased().contains(needle) || $0.symbol.lowercased().contains(needle)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                Group {
                    if results.isEmpty {
                        EmptyStateView(systemImage: "magnifyingglass",
                                       title: "No constants",
                                       message: "Nothing matches \"\(search)\".")
                    } else {
                        List {
                            ForEach(results) { constant in
                                Button {
                                    onInsert(constant)
                                    Haptics.selection(enabled: settings.hapticsEnabled)
                                    dismiss()
                                } label: {
                                    row(constant)
                                }
                                .buttonStyle(.plain)
                                .listRowBackground(Theme.surface)
                            }
                        }
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Constants")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $search, prompt: "Search constants")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
        }
    }

    private func row(_ constant: PhysicsConstant) -> some View {
        HStack(spacing: 14) {
            Text(constant.symbol)
                .font(Theme.rounded(20, .bold))
                .foregroundStyle(Theme.accent)
                .frame(minWidth: 44, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                Text(constant.name)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                Text("\(constant.insertableValue) \(constant.unit)")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
                    .lineLimit(1)
            }
            Spacer()
            Image(systemName: "plus.circle")
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(constant.name), \(constant.symbol), \(constant.insertableValue) \(constant.unit)")
        .accessibilityHint("Inserts this value into the calculator")
    }
}

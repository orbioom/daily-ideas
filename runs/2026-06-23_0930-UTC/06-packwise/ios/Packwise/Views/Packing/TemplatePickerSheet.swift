import SwiftUI
import SwiftData

/// Lets the user pick a template to merge into the current trip's list.
struct TemplatePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Template.name) private var templates: [Template]
    let onPick: (Template) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if templates.isEmpty {
                    EmptyStateView(
                        symbol: "square.stack.3d.up.slash",
                        title: "No templates yet",
                        message: "Create templates from the Templates tab, then apply them here."
                    )
                } else {
                    List {
                        ForEach(templates) { template in
                            Button {
                                onPick(template)
                                dismiss()
                            } label: {
                                HStack(spacing: Theme.Space.md) {
                                    IconBadge(symbol: template.symbol, tint: Theme.primary)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(template.name)
                                            .font(.headline)
                                            .foregroundStyle(Theme.textPrimary)
                                        Text("\(template.itemCount) items")
                                            .font(.caption)
                                            .foregroundStyle(Theme.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(Theme.primary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Apply template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

import SwiftUI
import SwiftData

/// Edits a project's name, notes, color, and area.
struct ProjectEditorView: View {
    @Bindable var project: Project
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Area.order) private var areas: [Area]

    var body: some View {
        NavigationStack {
            Form {
                Section("Project") {
                    TextField("Name", text: $project.name)
                    TextField("Notes", text: $project.notes, axis: .vertical)
                        .lineLimit(2...5)
                        .foregroundStyle(Brand.text2)
                }

                Section("Area") {
                    Picker(selection: areaBinding) {
                        Text("None").tag(Area?.none)
                        ForEach(areas) { area in
                            Text(area.name).tag(Area?.some(area))
                        }
                    } label: {
                        Label("Area", systemImage: "square.stack.3d.up")
                    }
                }

                Section("Color") {
                    FlowLayout(spacing: 12) {
                        ForEach(CruxPalette.swatches, id: \.self) { hex in
                            colorSwatch(hex)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle("Edit Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        project.name = project.name.trimmingCharacters(in: .whitespaces)
                        if project.name.isEmpty { project.name = "Untitled" }
                        TaskActions.save(context)
                        Haptics.success()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private var areaBinding: Binding<Area?> {
        Binding(get: { project.area }, set: { project.area = $0 })
    }

    private func colorSwatch(_ hex: String) -> some View {
        let isSelected = project.colorHex.uppercased() == hex.uppercased()
        return Button {
            project.colorHex = hex
            Haptics.selection()
        } label: {
            Circle()
                .fill(Color(brandHex: hex))
                .frame(width: 34, height: 34)
                .overlay(
                    Circle().strokeBorder(Brand.text, lineWidth: isSelected ? 3 : 0)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Color")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }
}

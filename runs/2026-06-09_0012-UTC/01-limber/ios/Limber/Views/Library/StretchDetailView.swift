import SwiftUI
import SwiftData

struct StretchDetailView: View {
    @Bindable var stretch: Stretch
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var editing = false
    @State private var confirmDelete = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                header
                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Eyebrow(text: "How to")
                        Text(stretch.detail)
                            .font(.body)
                            .foregroundStyle(Brand.text2)
                    }
                }
                GlassCard {
                    VStack(spacing: 12) {
                        infoRow("Area", stretch.area.title, stretch.area.icon, stretch.area.tint)
                        Divider().overlay(Brand.hairline)
                        infoRow("Suggested hold", "\(stretch.defaultSeconds) seconds", "clock", Brand.text2)
                        Divider().overlay(Brand.hairline)
                        infoRow("Sides", stretch.bothSides ? "Both sides" : "Single", "arrow.left.arrow.right", Brand.text2)
                        Divider().overlay(Brand.hairline)
                        infoRow("Difficulty", stretch.difficultyLabel, "gauge.medium", Brand.text2)
                    }
                }
                if stretch.isCustom {
                    Button(role: .destructive) { confirmDelete = true } label: {
                        Label("Delete stretch", systemImage: "trash").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(GlassButtonStyle())
                    .tint(Brand.danger)
                }
            }
            .padding(20)
        }
        .scrollContentBackground(.hidden)
        .background(Brand.pageBackground)
        .navigationTitle(stretch.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if stretch.isCustom {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit") { editing = true }
                }
            }
        }
        .sheet(isPresented: $editing) { StretchEditorView(stretch: stretch) }
        .alert("Delete this stretch?", isPresented: $confirmDelete) {
            Button("Delete", role: .destructive) {
                context.delete(stretch)
                try? context.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Routines that used it will simply skip the missing step.")
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(stretch.area.tint.opacity(0.18)).frame(width: 96, height: 96)
                Image(systemName: stretch.area.icon)
                    .font(.system(size: 42, weight: .light))
                    .foregroundStyle(stretch.area.tint)
            }
            .accessibilityHidden(true)
            Text(stretch.area.group)
                .font(.subheadline)
                .foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity)
    }

    private func infoRow(_ label: String, _ value: String, _ icon: String, _ tint: Color) -> some View {
        HStack {
            Label(label, systemImage: icon)
                .foregroundStyle(Brand.text2)
                .labelStyle(.titleAndIcon)
            Spacer()
            Text(value).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
        }
        .font(.subheadline)
    }
}

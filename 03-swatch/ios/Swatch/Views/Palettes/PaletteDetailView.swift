import SwiftUI
import SwiftData

struct PaletteDetailView: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    let palette: Palette
    @State private var showShareSheet = false
    @State private var shareText = ""
    @State private var copiedId: UUID?
    @State private var showDeleteAlert = false

    private var sortedColors: [SwatchColor] {
        palette.colors.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SwatchTheme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Large color strip at top
                        HStack(spacing: 0) {
                            ForEach(sortedColors) { sc in
                                sc.color
                            }
                        }
                        .frame(height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: SwatchTheme.shadow, radius: 10, y: 5)

                        // Color list
                        VStack(spacing: 10) {
                            ForEach(sortedColors) { sc in
                                ColorDetailRow(sc: sc, copiedId: $copiedId)
                            }
                        }

                        // Delete button
                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            Label("Delete Palette", systemImage: "trash")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.red.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle(palette.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        shareText = buildShareText()
                        showShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .foregroundStyle(SwatchTheme.accent)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: [shareText])
            }
            .alert("Delete Palette?", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    ctx.delete(palette)
                    try? ctx.save()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete \"\(palette.name)\" and all its colors.")
            }
        }
    }

    private func buildShareText() -> String {
        var lines = ["Palette: \(palette.name)", ""]
        for sc in sortedColors {
            lines.append("\(sc.colorName) — \(sc.hex) / \(sc.rgbString)")
        }
        return lines.joined(separator: "\n")
    }
}

struct ColorDetailRow: View {
    let sc: SwatchColor
    @Binding var copiedId: UUID?

    var body: some View {
        HStack(spacing: 14) {
            sc.color
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(color: .black.opacity(0.08), radius: 3, y: 1)

            VStack(alignment: .leading, spacing: 3) {
                Text(sc.colorName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SwatchTheme.accent)

                Button {
                    UIPasteboard.general.string = sc.hex
                    copiedId = sc.id
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        if copiedId == sc.id { copiedId = nil }
                    }
                } label: {
                    Text(sc.hex)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(copiedId == sc.id ? .green : SwatchTheme.subtleText)
                }

                Button {
                    UIPasteboard.general.string = sc.rgbString
                    copiedId = sc.id
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        if copiedId == sc.id { copiedId = nil }
                    }
                } label: {
                    Text(sc.rgbString)
                        .font(.caption)
                        .foregroundStyle(copiedId == sc.id ? .green : SwatchTheme.subtleText)
                }
            }

            Spacer()

            if copiedId == sc.id {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(12)
        .background(SwatchTheme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: SwatchTheme.shadow, radius: 4, y: 2)
        .animation(.spring(duration: 0.2), value: copiedId)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

import SwiftUI
import SwiftData
import UIKit

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavedCode.createdAt, order: .reverse) private var codes: [SavedCode]
    @State private var search = ""

    private var filtered: [SavedCode] {
        let base = codes.sorted { ($0.isFavorite ? 0 : 1, $1.createdAt) < ($1.isFavorite ? 0 : 1, $0.createdAt) }
        guard !search.trimmingCharacters(in: .whitespaces).isEmpty else { return base }
        let needle = search.lowercased()
        return base.filter { $0.title.lowercased().contains(needle) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if codes.isEmpty {
                    ContentUnavailableView(
                        "No Saved Codes",
                        systemImage: "qrcode",
                        description: Text("Design a code on the Create tab and save it — it will live here, ready to show or share.")
                    )
                } else if filtered.isEmpty {
                    ContentUnavailableView.search(text: search)
                } else {
                    List {
                        ForEach(filtered) { code in
                            NavigationLink {
                                CodeDetailView(code: code)
                            } label: {
                                row(code)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    modelContext.delete(code)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                Button {
                                    code.isFavorite.toggle()
                                    Haptics.tap()
                                } label: {
                                    Label(code.isFavorite ? "Unpin" : "Pin", systemImage: code.isFavorite ? "pin.slash" : "pin")
                                }
                                .tint(GlyphTheme.mint)
                            }
                        }
                    }
                    .searchable(text: $search, prompt: "Search codes")
                }
            }
            .navigationTitle("Library")
        }
    }

    private func row(_ code: SavedCode) -> some View {
        HStack(spacing: 12) {
            Image(systemName: code.kind.symbol)
                .font(.body)
                .foregroundStyle(Color(hex: code.foregroundHex))
                .frame(width: 38, height: 38)
                .background(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(Color(hex: code.backgroundHex))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
                )
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    if code.isFavorite {
                        Image(systemName: "pin.fill")
                            .font(.caption2)
                            .foregroundStyle(GlyphTheme.mint)
                    }
                    Text(code.title)
                        .font(.body.weight(.medium))
                        .lineLimit(1)
                }
                Text("\(code.kind.displayName) · \(code.createdAt.formatted(.dateTime.day().month().year()))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

struct CodeDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let code: SavedCode

    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var confirmingDelete = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color(hex: code.backgroundHex))
                        .frame(height: 330)
                    if isLoading {
                        ProgressView()
                    } else if let image {
                        Image(uiImage: image)
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                            .frame(height: 280)
                            .accessibilityLabel("QR code for \(code.title)")
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.title)
                                .foregroundStyle(.orange)
                            Text("This code couldn't be rendered. Its data may be too long for the chosen correction level.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                    }
                }
                .padding(.horizontal)

                if let draft = code.draft {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Encodes")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(draft.encoded())
                            .font(.footnote.monospaced())
                            .textSelection(.enabled)
                            .lineLimit(8)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glyphPanel()
                    .padding(.horizontal)
                }

                HStack(spacing: 10) {
                    if let image {
                        ShareLink(
                            item: Image(uiImage: image),
                            preview: SharePreview(code.title, image: Image(uiImage: image))
                        ) {
                            Label("Share", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(GlyphTheme.mint)
                        .foregroundStyle(.black)
                    }
                    Button(role: .destructive) {
                        confirmingDelete = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(code.title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await render() }
        .confirmationDialog("Delete this code?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                modelContext.delete(code)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    @MainActor
    private func render() async {
        isLoading = true
        guard let draft = code.draft else {
            image = nil
            isLoading = false
            return
        }
        let payload = draft.encoded()
        let fg = UIColor(hex: code.foregroundHex)
        let bg = UIColor(hex: code.backgroundHex)
        let level = CorrectionLevel(rawValue: code.correctionRaw) ?? .medium
        image = await Task.detached(priority: .userInitiated) {
            QRRenderer.image(for: payload, correction: level, foreground: fg, background: bg)
        }.value
        isLoading = false
    }
}

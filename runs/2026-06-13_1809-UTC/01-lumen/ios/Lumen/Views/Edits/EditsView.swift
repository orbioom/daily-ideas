import SwiftUI
import UIKit
import SwiftData

struct EditsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \EditRecord.createdAt, order: .reverse) private var edits: [EditRecord]
    @State private var detail: EditRecord?

    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if edits.isEmpty {
                    EmptyStateView(icon: "photo.on.rectangle.angled",
                                   title: "No saved edits yet",
                                   message: "Every photo you save to your library is logged here, with the exact look you used.")
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(edits) { edit in
                                Button { detail = edit } label: {
                                    if let ui = UIImage(data: edit.thumbnail) {
                                        Image(uiImage: ui).resizable().scaledToFill()
                                            .frame(width: 110, height: 110).clipped()
                                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    } else {
                                        RoundedRectangle(cornerRadius: 12).fill(Theme.surfaceAlt).frame(width: 110, height: 110)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 28)
                    }
                }
            }
            .navigationTitle("Gallery")
            .sheet(item: $detail) { e in EditDetailSheet(edit: e) }
        }
    }
}

struct EditDetailSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let edit: EditRecord
    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        ZStack {
                            Theme.canvas
                            if let ui = UIImage(data: edit.thumbnail) {
                                Image(uiImage: ui).resizable().scaledToFit()
                            }
                        }
                        .frame(height: 320)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                        Card {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Saved \(Fmt.relativeDay(edit.createdAt))")
                                        .font(Theme.rounded(14, .bold)).foregroundStyle(Theme.ink)
                                    Spacer()
                                    if let p = edit.presetName { Pill(text: p) }
                                }
                                Divider().background(Theme.hairline)
                                let active = Adjustments.Field.allCases.filter { edit.adjustments[$0] != 0 }
                                if active.isEmpty {
                                    Text("No adjustments — saved as-is.").foregroundStyle(Theme.inkSoft)
                                } else {
                                    ForEach(active) { f in
                                        HStack {
                                            Label(f.label, systemImage: f.icon).font(Theme.rounded(14, .medium)).foregroundStyle(Theme.ink)
                                            Spacer()
                                            Text("\(edit.adjustments[f] > 0 && f.bipolar ? "+" : "")\(Int((edit.adjustments[f] * 100).rounded()))")
                                                .font(Theme.rounded(14, .bold)).foregroundStyle(Theme.accent)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)

                        Button(role: .destructive) { confirmDelete = true } label: {
                            Label("Delete from gallery", systemImage: "trash")
                                .font(Theme.rounded(15, .semibold)).frame(maxWidth: .infinity).padding(.vertical, 12)
                                .background(Theme.bad.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .foregroundStyle(Theme.bad)
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Saved edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
            .alert("Delete this edit?", isPresented: $confirmDelete) {
                Button("Delete", role: .destructive) {
                    context.delete(edit); try? context.save(); dismiss()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This only removes it from Lumen’s gallery. The photo stays in your library.")
            }
        }
    }
}

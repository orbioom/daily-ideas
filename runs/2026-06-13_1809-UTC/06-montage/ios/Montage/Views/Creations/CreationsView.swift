import SwiftUI
import UIKit
import SwiftData

struct CreationsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Creation.createdAt, order: .reverse) private var creations: [Creation]
    @State private var detail: Creation?

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if creations.isEmpty {
                    EmptyStateView(icon: "photo.on.rectangle.angled",
                                   title: "No creations yet",
                                   message: "Design a montage and export it — every one you save shows up here, ready to re-share.")
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(creations) { c in
                                Button { detail = c } label: {
                                    if let ui = UIImage(data: c.image) {
                                        Image(uiImage: ui).resizable().scaledToFill()
                                            .frame(height: 200).frame(maxWidth: .infinity).clipped()
                                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                            .overlay(alignment: .bottomLeading) {
                                                Text(c.templateName).font(Theme.rounded(11, .bold)).foregroundStyle(.white)
                                                    .padding(.horizontal, 8).padding(.vertical, 4)
                                                    .background(.black.opacity(0.45), in: Capsule()).padding(8)
                                            }
                                    } else {
                                        RoundedRectangle(cornerRadius: 14).fill(Theme.surfaceAlt).frame(height: 200)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 28)
                    }
                }
            }
            .navigationTitle("Creations")
            .sheet(item: $detail) { c in CreationDetailSheet(creation: c) }
        }
    }
}

struct CreationDetailSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let creation: Creation
    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                VStack(spacing: 16) {
                    if let ui = UIImage(data: creation.image) {
                        Image(uiImage: ui).resizable().scaledToFit()
                            .frame(maxHeight: 420)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
                        ShareLink(item: Image(uiImage: ui), preview: SharePreview(creation.templateName, image: Image(uiImage: ui))) {
                            Label("Share", systemImage: "square.and.arrow.up")
                                .font(Theme.rounded(16, .bold)).frame(maxWidth: .infinity).padding(.vertical, 14)
                                .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .foregroundStyle(.white)
                        }
                    }
                    Button(role: .destructive) { confirmDelete = true } label: {
                        Label("Delete", systemImage: "trash")
                            .font(Theme.rounded(15, .semibold)).frame(maxWidth: .infinity).padding(.vertical, 12)
                            .background(Theme.bad.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .foregroundStyle(Theme.bad)
                    }
                    Spacer()
                }
                .padding(16)
            }
            .navigationTitle(creation.templateName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
            .alert("Delete this creation?", isPresented: $confirmDelete) {
                Button("Delete", role: .destructive) { context.delete(creation); try? context.save(); dismiss() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This removes it from Montage. The exported image stays in your Photos.")
            }
        }
    }
}

import SwiftUI
import SwiftData

struct TagManagerView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var pro: ProStore

    @Query(sort: \Tag.name) private var tags: [Tag]

    @State private var newName = ""
    @State private var selectedColor = Tag.palette.first ?? "4C5BD4"
    @State private var showingPaywall = false

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    creator
                    if tags.isEmpty {
                        EmptyStateView(symbol: "tag", title: "No tags yet",
                                       message: "Create tags to organize roles — like Dream role, Remote-first or Referral.")
                    } else {
                        VStack(spacing: 0) {
                            ForEach(tags) { tag in
                                tagRow(tag)
                                if tag.id != tags.last?.id { Divider().padding(.leading, 16) }
                            }
                        }
                        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.radiusM, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: Theme.radiusM, style: .continuous).stroke(Theme.hairline, lineWidth: 1))
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("Tags")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingPaywall) {
            PaywallView(reason: "Custom tags and colors are a Pro feature.")
        }
    }

    private var creator: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("New tag")
                .font(Theme.rounded(16, .bold))
                .foregroundStyle(Theme.ink)
            TextField("Tag name", text: $newName)
                .textFieldStyle(.roundedBorder)
            FlowLayout(spacing: 10, lineSpacing: 10) {
                ForEach(Tag.palette, id: \.self) { hex in
                    Button {
                        selectedColor = hex
                        Haptics.selection(enabled: settings.hapticsEnabled)
                    } label: {
                        Circle()
                            .fill(Color(hex: Tag.parseHex(hex)))
                            .frame(width: 30, height: 30)
                            .overlay(
                                Circle().stroke(Theme.ink, lineWidth: selectedColor == hex ? 3 : 0)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Color option")
                    .accessibilityAddTraits(selectedColor == hex ? .isSelected : [])
                }
            }
            Button {
                addTag()
            } label: {
                Label(pro.isPro ? "Add tag" : "Add tag (Pro)", systemImage: pro.isPro ? "plus" : "lock.fill")
                    .font(Theme.rounded(15, .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(canAdd ? Theme.accent : Theme.inkFaint, in: RoundedRectangle(cornerRadius: Theme.radiusS, style: .continuous))
                    .foregroundStyle(.white)
            }
            .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .cardStyle()
    }

    private var canAdd: Bool { !newName.trimmingCharacters(in: .whitespaces).isEmpty }

    private func tagRow(_ tag: Tag) -> some View {
        HStack(spacing: 12) {
            Circle().fill(tag.color).frame(width: 18, height: 18)
            Text(tag.name)
                .font(Theme.rounded(15, .medium))
                .foregroundStyle(Theme.ink)
            Spacer()
            Text("\(tag.applications.count)")
                .font(Theme.rounded(13))
                .foregroundStyle(Theme.inkFaint)
            Button(role: .destructive) {
                delete(tag)
            } label: {
                Image(systemName: "trash").foregroundStyle(Theme.bad)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete tag \(tag.name)")
        }
        .padding(14)
    }

    private func addTag() {
        guard canAdd else { return }
        guard pro.isPro else { showingPaywall = true; return }
        let tag = Tag(name: newName.trimmingCharacters(in: .whitespaces), colorHex: selectedColor)
        context.insert(tag)
        try? context.save()
        newName = ""
        Haptics.notify(.success, enabled: settings.hapticsEnabled)
    }

    private func delete(_ tag: Tag) {
        context.delete(tag)
        try? context.save()
        Haptics.impact(.medium, enabled: settings.hapticsEnabled)
    }
}

import SwiftUI
import SwiftData

struct PassageDetailView: View {
    @Environment(ProStore.self) private var pro
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("passageFontSize") private var fontSizeRaw = PassageFontSize.medium.rawValue

    let passage: Passage

    @State private var showStudy = false
    @State private var showEdit = false
    @State private var confirmDelete = false

    private var fontSize: PassageFontSize { PassageFontSize(rawValue: fontSizeRaw) ?? .medium }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    statsCard
                    Card {
                        PassageTextView(text: passage.fullText, fontSize: fontSize)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 110)
            }
            studyBar
        }
        .navigationTitle(passage.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { Haptics.tap(); showEdit = true } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    if pro.isPro {
                        ShareLink(item: shareText) {
                            Label("Share text", systemImage: "square.and.arrow.up")
                        }
                    }
                    Button(role: .destructive) { confirmDelete = true } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Passage options")
            }
        }
        .sheet(isPresented: $showStudy) { StudyPlayerView(passage: passage) }
        .sheet(isPresented: $showEdit) { AddPassageView(editing: passage) }
        .alert("Delete this passage?", isPresented: $confirmDelete) {
            Button("Delete", role: .destructive) { deletePassage() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This permanently removes “\(passage.title)” and its review history.")
        }
    }

    private var shareText: String {
        var t = passage.title
        if !passage.source.isEmpty { t += "\n— \(passage.source)" }
        return t + "\n\n" + passage.fullText
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Label(passage.category.displayName, systemImage: passage.category.icon)
                    .font(Theme.rounded(13, .bold))
                    .foregroundStyle(Theme.accent)
                Spacer()
                Text(Fmt.dueDescription(passage.nextDue))
                    .font(Theme.rounded(13, .semibold))
                    .foregroundStyle(passage.isDue() ? Theme.accent : Theme.inkSoft)
            }
            if !passage.source.isEmpty {
                Text(passage.source)
                    .font(Theme.serif(16, .regular).italic())
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .padding(.top, 4)
    }

    private var statsCard: some View {
        HStack(spacing: 14) {
            MasteryRing(level: passage.masteryLevel, size: 56, lineWidth: 6)
            VStack(alignment: .leading, spacing: 4) {
                Text(passage.currentMaskLevel.displayName)
                    .font(Theme.rounded(17, .bold)).foregroundStyle(Theme.ink)
                Text(passage.currentMaskLevel.subtitle)
                    .font(Theme.rounded(13, .regular)).foregroundStyle(Theme.inkSoft)
                Text("\(passage.wordCount) words · about \(passage.readingMinutes) min read")
                    .font(Theme.rounded(12, .regular)).foregroundStyle(Theme.inkFaint)
            }
            Spacer()
        }
        .padding(16)
        .background(Theme.surfaceAlt, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Mastery \(passage.masteryLevel) of 5, next stage \(passage.currentMaskLevel.displayName)")
    }

    private var studyBar: some View {
        VStack {
            Spacer()
            Button {
                Haptics.tap(); showStudy = true
            } label: {
                Label(passage.masteryLevel == 0 ? "Start studying" : "Study now",
                      systemImage: "play.fill")
                    .font(Theme.rounded(18, .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            .background(
                LinearGradient(colors: [Theme.bg.opacity(0), Theme.bg],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            )
        }
    }

    private func deletePassage() {
        context.delete(passage)
        try? context.save()
        Haptics.success()
        dismiss()
    }
}

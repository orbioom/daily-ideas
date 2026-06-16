import SwiftUI

/// Vocab tab: official reading & writing vocabulary lists, grouped, with a simple
/// flashcard practice. Free users get a preview; Pro unlocks full lists + practice.
struct VocabView: View {
    @Environment(AppPreferences.self) private var prefs
    @Environment(SpeechManager.self) private var speech
    @Environment(\.colorScheme) private var scheme

    @State private var list: VocabWord.List = .reading
    @State private var practice = false
    @State private var showPaywall = false

    /// Free preview shows only the first two groups for each list.
    private let freeGroupLimit = 2

    private var groups: [VocabWord.Group] {
        let all = VocabWord.Group.allCases.filter { group in
            !CivicsContent.vocabulary(list: list, group: group).isEmpty
        }
        return prefs.isPro ? all : Array(all.prefix(freeGroupLimit))
    }

    private var hiddenGroupCount: Int {
        let all = VocabWord.Group.allCases.filter { group in
            !CivicsContent.vocabulary(list: list, group: group).isEmpty
        }
        return prefs.isPro ? 0 : max(0, all.count - freeGroupLimit)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    listPicker
                    intro
                    ForEach(groups) { group in
                        groupCard(group)
                    }
                    if hiddenGroupCount > 0 {
                        lockedGroupsCard
                    }
                    practiceButton
                }
                .padding()
            }
            .screenBackground(scheme)
            .navigationTitle("Vocabulary")
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $practice) {
                VocabPracticeView(list: list)
            }
        }
    }

    private var listPicker: some View {
        Picker("List", selection: $list) {
            ForEach(VocabWord.List.allCases) { l in
                Text(l == .reading ? "Reading" : "Writing").tag(l)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Vocabulary list")
    }

    private var intro: some View {
        Text(list == .reading
             ? "During the interview you read one of these sentences aloud. These are the words USCIS may use."
             : "You write one sentence the officer dictates. These are the words USCIS may use.")
            .font(.subheadline)
            .foregroundStyle(Theme.textSecondary(scheme))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func groupCard(_ group: VocabWord.Group) -> some View {
        let words = CivicsContent.vocabulary(list: list, group: group)
        return VStack(alignment: .leading, spacing: 10) {
            Text(group.title)
                .font(.headline)
                .foregroundStyle(Theme.textPrimary(scheme))
            FlowLayout(spacing: 8) {
                ForEach(words) { w in
                    Button {
                        if prefs.audioEnabled && prefs.isPro {
                            speech.speak(w.word)
                        } else if !prefs.isPro {
                            showPaywall = true
                        }
                    } label: {
                        Text(w.word)
                            .font(.subheadline)
                            .foregroundStyle(Theme.textPrimary(scheme))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Theme.cardSecondary(scheme)))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(w.word)
                    .accessibilityHint(prefs.isPro && prefs.audioEnabled ? "Tap to hear it" : "")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }

    private var lockedGroupsCard: some View {
        Button {
            showPaywall = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .foregroundStyle(Theme.gold)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("\(hiddenGroupCount) more groups")
                            .font(.headline)
                            .foregroundStyle(Theme.textPrimary(scheme))
                        ProBadge()
                    }
                    Text("Unlock the complete reading & writing lists.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary(scheme))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary(scheme))
                    .accessibilityHidden(true)
            }
            .cardSurface(secondary: true)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }

    private var practiceButton: some View {
        Button {
            if prefs.isPro {
                practice = true
            } else {
                showPaywall = true
            }
        } label: {
            HStack {
                Label("Practice these words", systemImage: "rectangle.on.rectangle")
                if !prefs.isPro { ProBadge() }
            }
        }
        .buttonStyle(PrimaryButtonStyle())
    }
}

/// Simple vocab flashcard practice: shows a word; tap to mark seen and advance.
struct VocabPracticeView: View {
    let list: VocabWord.List

    @Environment(\.dismiss) private var dismiss
    @Environment(SpeechManager.self) private var speech
    @Environment(AppPreferences.self) private var prefs
    @Environment(\.colorScheme) private var scheme

    @State private var index = 0
    @State private var words: [VocabWord] = []

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background(scheme).ignoresSafeArea()
                if words.isEmpty {
                    EmptyStateView(systemImage: "textformat.abc",
                                   title: "No words",
                                   message: "There are no words to practice in this list.")
                } else {
                    practiceContent
                }
            }
            .navigationTitle(list.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onAppear {
            words = CivicsContent.vocabulary(list: list).shuffled()
        }
    }

    private var practiceContent: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("Word \(min(index + 1, words.count)) of \(words.count)")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary(scheme))
            if index < words.count {
                let word = words[index]
                Text(word.word)
                    .font(Theme.serifTitle(40, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.textPrimary(scheme))
                    .padding()
                    .frame(maxWidth: .infinity, minHeight: 180)
                    .background(RoundedRectangle(cornerRadius: 22).fill(Theme.card(scheme)))
                    .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(Theme.accent.opacity(0.25)))
                    .padding(.horizontal)
                    .accessibilityLabel(word.word)

                if prefs.audioEnabled {
                    Button {
                        speech.speak(word.word)
                    } label: {
                        Label("Hear it", systemImage: "speaker.wave.2.fill")
                            .font(.subheadline)
                            .foregroundStyle(Theme.accent)
                    }
                }
            }
            Spacer()
            Button(index >= words.count - 1 ? "Finish" : "Next word") {
                if index >= words.count - 1 {
                    dismiss()
                } else {
                    index += 1
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal)
        }
        .padding(.bottom)
    }
}

/// A minimal flow layout for wrapping word chips (iOS 16+ Layout API).
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rows: [CGFloat] = [0]
        var x: CGFloat = 0
        var totalHeight: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                totalHeight += rowHeight + spacing
                x = 0
                rowHeight = 0
                rows.append(0)
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight
        return CGSize(width: maxWidth == .infinity ? x : maxWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.minX + maxWidth && x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

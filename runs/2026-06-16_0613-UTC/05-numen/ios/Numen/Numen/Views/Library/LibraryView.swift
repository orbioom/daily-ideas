import SwiftUI

struct LibraryView: View {
    @AppStorage("isPro") private var isPro = false
    @State private var selected: NumberMeaning?
    @State private var showPaywall = false

    /// Free users see a teaser: the first few entries are open.
    private let freeTeaserCount = 3

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        NavigationStack {
            ZStack {
                ScreenBackground()
                ScrollView {
                    VStack(spacing: 16) {
                        intro
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(Array(InterpretationLibrary.all.enumerated()), id: \.element.id) { index, meaning in
                                let locked = !isPro && index >= freeTeaserCount
                                LibraryCard(meaning: meaning, locked: locked) {
                                    if locked {
                                        showPaywall = true
                                    } else {
                                        selected = meaning
                                    }
                                }
                            }
                        }
                        if !isPro {
                            unlockBanner
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Library")
            .sheet(item: $selected) { meaning in
                LibraryDetailView(meaning: meaning)
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private var intro: some View {
        Text("The meaning of every number, 1 through 9 and the master numbers 11, 22, and 33.")
            .font(Theme.serif(.body))
            .foregroundStyle(Theme.inkSoft)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
    }

    private var unlockBanner: some View {
        Button { showPaywall = true } label: {
            HStack {
                Image(systemName: "lock.fill").foregroundStyle(Theme.accent)
                Text("Unlock the complete Library with Numen Pro")
                    .font(Theme.rounded(14, .semibold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Theme.inkSoft)
            }
            .padding(16)
            .background(Theme.surfaceAlt, in: RoundedRectangle(cornerRadius: Theme.cornerM))
        }
        .buttonStyle(.plain)
    }
}

struct LibraryCard: View {
    let meaning: NumberMeaning
    let locked: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    NumberGlyph(value: meaning.number, size: 38, isMaster: meaning.number > 9)
                    Spacer()
                    if locked {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(Theme.inkSoft)
                            .accessibilityHidden(true)
                    }
                }
                Text(meaning.title)
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                Text(meaning.keywords.prefix(2).joined(separator: " · "))
                    .font(Theme.rounded(12, .medium))
                    .foregroundStyle(Theme.inkSoft)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerM))
            .overlay(RoundedRectangle(cornerRadius: Theme.cornerM).stroke(Theme.hairline, lineWidth: 1))
            .opacity(locked ? 0.7 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Number \(meaning.number), \(meaning.title)\(locked ? ", locked" : "")")
        .accessibilityHint(locked ? "Requires Numen Pro" : "Opens the full meaning")
    }
}

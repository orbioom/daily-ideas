import SwiftUI
import SwiftData

struct LanguagesView: View {
    @Query private var allPrefs: [LocalePrefs]
    @Environment(\.modelContext) private var context

    private var prefs: LocalePrefs {
        if let p = allPrefs.first { return p }
        let p = LocalePrefs(); context.insert(p); return p
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(LanguageRegistry.all.filter { !$0.isPro }) { lang in
                        LanguageRow(lang: lang, isSelected: prefs.selectedLanguageId == lang.id) {
                            prefs.selectedLanguageId = lang.id
                            if prefs.hapticsEnabled {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        }
                    }
                } header: {
                    Text("Free")
                }

                Section {
                    ForEach(LanguageRegistry.all.filter { $0.isPro }) { lang in
                        if prefs.isPro {
                            LanguageRow(lang: lang, isSelected: prefs.selectedLanguageId == lang.id) {
                                prefs.selectedLanguageId = lang.id
                                if prefs.hapticsEnabled {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }
                            }
                        } else {
                            LockedLanguageRow(lang: lang)
                        }
                    }
                } header: {
                    Text("Pro")
                }
            }
            .navigationTitle("Languages")
        }
    }
}

private struct LanguageRow: View {
    let lang: Language
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Text(lang.flag)
                    .font(.title)

                VStack(alignment: .leading, spacing: 2) {
                    Text(lang.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(lang.nativeName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.title3)
                }
            }
            .padding(.vertical, 4)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(lang.name), \(lang.nativeName)\(isSelected ? ", selected" : "")")
    }
}

private struct LockedLanguageRow: View {
    let lang: Language

    var body: some View {
        HStack(spacing: 16) {
            Text(lang.flag)
                .font(.title)
                .opacity(0.5)

            VStack(alignment: .leading, spacing: 2) {
                Text(lang.name)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text(lang.nativeName)
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Label("Pro", systemImage: "lock.fill")
                .font(.caption.bold())
                .foregroundStyle(.orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.15))
                .clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }
}

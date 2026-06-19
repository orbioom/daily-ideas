import SwiftUI
import SwiftData
import AVFoundation

struct PhraseDetailView: View {
    let phrase: Phrase
    let language: Language

    @Query private var favorites: [FavoritePhrase]
    @Query private var allPrefs: [LocalePrefs]
    @Environment(\.modelContext) private var context

    @State private var isSpeaking = false
    @State private var speechSynthesizer = AVSpeechSynthesizer()
    @State private var delegate: SpeechDelegate?

    private var prefs: LocalePrefs {
        if let p = allPrefs.first { return p }
        let p = LocalePrefs(); context.insert(p); return p
    }

    private var isFavorite: Bool {
        favorites.contains { $0.phraseId == phrase.id && $0.languageId == phrase.languageId }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                translationCard
                englishCard
                if let ph = phrase.phonetic {
                    phoneticCard(ph)
                }
                speakButton
            }
            .padding(20)
        }
        .navigationTitle(CategoryRegistry.all.first { $0.id == phrase.categoryId }.map { "\($0.emoji) \($0.name)" } ?? "Phrase")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    toggleFavorite()
                } label: {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(isFavorite ? .red : .secondary)
                }
                .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
            }
        }
    }

    private var translationCard: some View {
        VStack(spacing: 10) {
            Text(language.flag)
                .font(.system(size: 48))
            Text(phrase.translation)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var englishCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("English", systemImage: "textformat")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(phrase.english)
                .font(.title3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func phoneticCard(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Pronunciation", systemImage: "character.phonetic")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(text)
                .font(.title3)
                .italic()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var speakButton: some View {
        Button {
            speakPhrase()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isSpeaking ? "waveform" : "speaker.wave.2.fill")
                    .font(.title3)
                    .symbolEffect(.variableColor, isActive: isSpeaking)
                Text(isSpeaking ? "Speaking…" : "Hear Pronunciation")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSpeaking ? Color.green : Color.blue)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .accessibilityLabel(isSpeaking ? "Speaking" : "Hear pronunciation")
        .disabled(isSpeaking)
    }

    private func speakPhrase() {
        guard !isSpeaking else { return }
        if prefs.hapticsEnabled {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
        isSpeaking = true
        let utterance = AVSpeechUtterance(string: phrase.translation)
        utterance.voice = AVSpeechSynthesisVoice(language: language.avLocale)
        utterance.rate = 0.45
        let del = SpeechDelegate { isSpeaking = false }
        delegate = del
        speechSynthesizer.delegate = del
        speechSynthesizer.speak(utterance)
    }

    private func toggleFavorite() {
        if prefs.hapticsEnabled {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        if isFavorite {
            if let fav = favorites.first(where: { $0.phraseId == phrase.id && $0.languageId == phrase.languageId }) {
                context.delete(fav)
            }
        } else {
            context.insert(FavoritePhrase(phraseId: phrase.id, languageId: phrase.languageId))
        }
    }
}

final class SpeechDelegate: NSObject, AVSpeechSynthesizerDelegate {
    let onFinish: () -> Void
    init(onFinish: @escaping () -> Void) { self.onFinish = onFinish }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.onFinish() }
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.onFinish() }
    }
}

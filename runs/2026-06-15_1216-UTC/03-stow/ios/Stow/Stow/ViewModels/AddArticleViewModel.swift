import SwiftUI

/// Drives the paste-URL → loading → preview → save flow with real async work.
@MainActor
final class AddArticleViewModel: ObservableObject {

    enum Phase: Equatable {
        case input
        case loading
        case preview
        case failed(String, String)  // message, suggestion
    }

    @Published var urlText = ""
    @Published var phase: Phase = .input
    @Published private(set) var result: ExtractedArticle?

    private let extractor: ArticleExtractor

    init(wordsPerMinute: Int) {
        self.extractor = ArticleExtractor(wordsPerMinute: wordsPerMinute)
    }

    var canSubmit: Bool {
        !urlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        phase != .loading
    }

    func fetch() async {
        let raw = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return }
        phase = .loading
        result = nil
        do {
            let extracted = try await extractor.extract(from: raw)
            result = extracted
            phase = .preview
        } catch let error as ExtractionError {
            phase = .failed(
                error.errorDescription ?? "Something went wrong.",
                error.recoverySuggestion ?? "Please try again."
            )
        } catch {
            phase = .failed("Something went wrong.", "Please try again.")
        }
    }

    func reset() {
        phase = .input
        result = nil
    }
}

import Foundation

// MARK: - Result & error types

/// The clean, readable output of extraction.
struct ExtractedArticle {
    var url: String
    var title: String
    var byline: String
    var siteName: String
    var blocks: [ContentBlock]
    var wordCount: Int
    var estMinutes: Int
    var excerpt: String

    func makeModel(source: ArticleSource) -> Article {
        Article(
            url: url,
            title: title,
            byline: byline,
            siteName: siteName,
            wordCount: wordCount,
            estMinutes: estMinutes,
            excerpt: excerpt,
            source: source,
            blocks: blocks
        )
    }
}

/// Calm, recoverable failures surfaced to the UI.
enum ExtractionError: LocalizedError, Equatable {
    case invalidURL
    case network(String)
    case notHTML
    case emptyContent

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "That doesn't look like a valid web address."
        case .network(let detail):
            return "Couldn't reach the page. \(detail)"
        case .notHTML:
            return "That link isn't a readable web page."
        case .emptyContent:
            return "We couldn't find readable text on that page."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .invalidURL:
            return "Check the address and try again. It should start with http:// or https://."
        case .network:
            return "Check your connection, then retry."
        case .notHTML:
            return "Try a link to an article or blog post."
        case .emptyContent:
            return "The page may use a layout we can't read yet. Try another source."
        }
    }
}

// MARK: - Extractor

/// On-device readability engine. An `actor` so fetch+parse never blocks the
/// main thread and concurrent saves stay serialized safely.
actor ArticleExtractor {

    private let session: URLSession
    private let wordsPerMinute: Int

    init(session: URLSession = .shared, wordsPerMinute: Int = 200) {
        self.session = session
        self.wordsPerMinute = max(60, wordsPerMinute)
    }

    /// Fetch a URL and extract a clean article. Throws `ExtractionError`.
    func extract(from rawURL: String) async throws -> ExtractedArticle {
        let trimmed = rawURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = Self.normalizedURL(from: trimmed) else {
            throw ExtractionError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) Stow/1.0",
            forHTTPHeaderField: "User-Agent"
        )
        request.timeoutInterval = 25

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError {
            throw ExtractionError.network(urlError.localizedDescription)
        } catch {
            throw ExtractionError.network(error.localizedDescription)
        }

        if let http = response as? HTTPURLResponse {
            if !(200..<400).contains(http.statusCode) {
                throw ExtractionError.network("Server returned status \(http.statusCode).")
            }
            if let mime = http.mimeType, !mime.contains("html"), !mime.contains("xml") {
                throw ExtractionError.notHTML
            }
        }

        guard let html = Self.decodeHTML(data, response: response) else {
            throw ExtractionError.notHTML
        }

        return try parse(html: html, url: url.absoluteString)
    }

    /// Pure parse step — exposed for testing & sample seeding without network.
    func parse(html: String, url: String) throws -> ExtractedArticle {
        let parsed = Self.readability(html: html, url: url, wpm: wordsPerMinute)
        guard !parsed.blocks.isEmpty else { throw ExtractionError.emptyContent }
        return parsed
    }

    // MARK: URL normalization

    static func normalizedURL(from raw: String) -> URL? {
        guard !raw.isEmpty else { return nil }
        var candidate = raw
        if !candidate.lowercased().hasPrefix("http://"),
           !candidate.lowercased().hasPrefix("https://") {
            candidate = "https://" + candidate
        }
        guard let url = URL(string: candidate),
              let host = url.host, host.contains(".") else {
            return nil
        }
        return url
    }

    // MARK: HTML decoding

    private static func decodeHTML(_ data: Data, response: URLResponse) -> String? {
        if let name = response.textEncodingName,
           let cf = CFStringConvertIANACharSetNameToEncoding(name as CFString) as CFStringEncoding?,
           cf != kCFStringEncodingInvalidId {
            let enc = CFStringConvertEncodingToNSStringEncoding(cf)
            if let s = String(data: data, encoding: String.Encoding(rawValue: enc)) {
                return s
            }
        }
        if let s = String(data: data, encoding: .utf8) { return s }
        return String(data: data, encoding: .isoLatin1)
    }

    // MARK: Readability core (pure, deterministic)

    /// Hand-rolled readability extraction. No external libs.
    static func readability(html: String, url: String, wpm: Int) -> ExtractedArticle {
        let host = URL(string: url)?.host?.replacingOccurrences(of: "www.", with: "") ?? ""

        // Pull metadata before we strip the page apart.
        let title = extractTitle(html: html)
        let byline = extractMeta(html: html, names: ["author", "article:author"]) ??
            extractMetaProperty(html: html, properties: ["article:author"]) ?? ""
        let siteName = extractMetaProperty(html: html, properties: ["og:site_name"]) ?? host

        // Remove noise blocks entirely.
        var body = html
        for tag in ["script", "style", "noscript", "svg", "head", "nav", "header",
                    "footer", "aside", "form", "figure", "iframe", "template"] {
            body = removeBlocks(tag: tag, in: body)
        }

        // Prefer an <article> or <main> container if present and substantial.
        let scoped = mainContentScope(in: body) ?? body

        // Extract candidate blocks (headings + paragraphs) in document order.
        var blocks = extractBlocks(from: scoped)

        // Fallback: if scoping yielded too little, retry on the whole stripped body.
        if blocks.filter({ $0.kind == .paragraph }).count < 2, scoped != body {
            blocks = extractBlocks(from: body)
        }

        // Drop a leading heading that merely duplicates the title.
        if let first = blocks.first, first.kind == .heading,
           similar(first.text, title) {
            blocks.removeFirst()
        }

        let words = blocks.reduce(0) { $0 + wordCount(of: $1.text) }
        let minutes = max(1, Int((Double(words) / Double(max(60, wpm))).rounded(.up)))
        let excerpt = makeExcerpt(from: blocks)

        return ExtractedArticle(
            url: url,
            title: title.isEmpty ? (host.isEmpty ? "Untitled" : host) : title,
            byline: byline,
            siteName: siteName.isEmpty ? host : siteName,
            blocks: blocks,
            wordCount: words,
            estMinutes: minutes,
            excerpt: excerpt
        )
    }

    // MARK: Block extraction

    private static func extractBlocks(from html: String) -> [ContentBlock] {
        var blocks: [ContentBlock] = []

        // Scan for <p>, <h1>..<h3>, <li>, <blockquote> open tags and grab inner text.
        let pattern = "(?i)<(p|h1|h2|h3|h4|li|blockquote)(\\s[^>]*)?>(.*?)</\\1>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
            return blocks
        }
        let ns = html as NSString
        let matches = regex.matches(in: html, options: [], range: NSRange(location: 0, length: ns.length))
        for match in matches {
            guard match.numberOfRanges >= 4 else { continue }
            let tag = ns.substring(with: match.range(at: 1)).lowercased()
            let inner = ns.substring(with: match.range(at: 3))
            let clean = cleanText(inner)
            guard !clean.isEmpty else { continue }

            if tag.hasPrefix("h") {
                guard clean.count <= 200 else { continue }
                blocks.append(ContentBlock(kind: .heading, text: clean))
            } else {
                // Skip trivial fragments that are likely chrome/boilerplate.
                guard wordCount(of: clean) >= 3 else { continue }
                blocks.append(ContentBlock(kind: .paragraph, text: clean))
            }
        }
        return dedupeConsecutive(blocks)
    }

    /// Choose the densest <article>/<main> region if one clearly dominates.
    private static func mainContentScope(in html: String) -> String? {
        for tag in ["article", "main"] {
            let pattern = "(?i)<\(tag)(\\s[^>]*)?>(.*?)</\(tag)>"
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
                continue
            }
            let ns = html as NSString
            let matches = regex.matches(in: html, options: [], range: NSRange(location: 0, length: ns.length))
            // Pick the match with the most paragraph text.
            var best: String?
            var bestScore = 0
            for m in matches where m.numberOfRanges >= 3 {
                let inner = ns.substring(with: m.range(at: 2))
                let score = paragraphTextLength(inner)
                if score > bestScore {
                    bestScore = score
                    best = inner
                }
            }
            if let best, bestScore > 400 { return best }
        }
        return nil
    }

    private static func paragraphTextLength(_ html: String) -> Int {
        guard let regex = try? NSRegularExpression(
            pattern: "(?i)<p(\\s[^>]*)?>(.*?)</p>",
            options: [.dotMatchesLineSeparators]) else { return 0 }
        let ns = html as NSString
        let matches = regex.matches(in: html, options: [], range: NSRange(location: 0, length: ns.length))
        return matches.reduce(0) { acc, m in
            guard m.numberOfRanges >= 3 else { return acc }
            return acc + cleanText(ns.substring(with: m.range(at: 2))).count
        }
    }

    // MARK: Metadata

    private static func extractTitle(html: String) -> String {
        if let og = extractMetaProperty(html: html, properties: ["og:title"]), !og.isEmpty {
            return og
        }
        if let m = firstMatch(in: html, pattern: "(?i)<title[^>]*>(.*?)</title>") {
            // Strip trailing " - Site" / " | Site" suffixes for cleanliness.
            let raw = cleanText(m)
            if let range = raw.range(of: " | ") ?? raw.range(of: " - ") {
                let head = String(raw[..<range.lowerBound])
                if head.count >= 12 { return head }
            }
            return raw
        }
        if let h1 = firstMatch(in: html, pattern: "(?i)<h1[^>]*>(.*?)</h1>") {
            return cleanText(h1)
        }
        return ""
    }

    private static func extractMeta(html: String, names: [String]) -> String? {
        for name in names {
            let pattern = "(?i)<meta[^>]*name=[\"']\(NSRegularExpression.escapedPattern(for: name))[\"'][^>]*content=[\"'](.*?)[\"']"
            if let v = firstMatch(in: html, pattern: pattern), !v.isEmpty {
                return cleanText(v)
            }
        }
        return nil
    }

    private static func extractMetaProperty(html: String, properties: [String]) -> String? {
        for prop in properties {
            let pattern = "(?i)<meta[^>]*property=[\"']\(NSRegularExpression.escapedPattern(for: prop))[\"'][^>]*content=[\"'](.*?)[\"']"
            if let v = firstMatch(in: html, pattern: pattern), !v.isEmpty {
                return cleanText(v)
            }
            // content can precede property
            let alt = "(?i)<meta[^>]*content=[\"'](.*?)[\"'][^>]*property=[\"']\(NSRegularExpression.escapedPattern(for: prop))[\"']"
            if let v = firstMatch(in: html, pattern: alt), !v.isEmpty {
                return cleanText(v)
            }
        }
        return nil
    }

    // MARK: Text utilities

    /// Strip inline tags, decode entities, collapse whitespace.
    static func cleanText(_ raw: String) -> String {
        var s = raw
        // Replace <br> with spaces first.
        s = s.replacingOccurrences(of: "(?i)<br\\s*/?>", with: " ", options: .regularExpression)
        // Strip any remaining tags.
        s = s.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        s = HTMLEntities.decode(s)
        // Collapse whitespace.
        s = s.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func removeBlocks(tag: String, in html: String) -> String {
        let pattern = "(?i)<\(tag)(\\s[^>]*)?>.*?</\(tag)>"
        var result = html.replacingOccurrences(of: pattern, with: " ", options: .regularExpression)
        // Also drop self-closing / void variants.
        result = result.replacingOccurrences(
            of: "(?i)<\(tag)(\\s[^>]*)?/?>",
            with: " ",
            options: .regularExpression
        )
        return result
    }

    static func wordCount(of text: String) -> Int {
        text.split { $0 == " " || $0 == "\n" || $0 == "\t" }.count
    }

    private static func makeExcerpt(from blocks: [ContentBlock]) -> String {
        guard let para = blocks.first(where: { $0.kind == .paragraph }) else { return "" }
        let text = para.text
        if text.count <= 180 { return text }
        let idx = text.index(text.startIndex, offsetBy: 180)
        let slice = String(text[..<idx])
        if let lastSpace = slice.lastIndex(of: " ") {
            return String(slice[..<lastSpace]) + "…"
        }
        return slice + "…"
    }

    private static func dedupeConsecutive(_ blocks: [ContentBlock]) -> [ContentBlock] {
        var out: [ContentBlock] = []
        for b in blocks {
            if let last = out.last, last.text == b.text { continue }
            out.append(b)
        }
        return out
    }

    private static func similar(_ a: String, _ b: String) -> Bool {
        let x = a.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let y = b.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return !x.isEmpty && (x == y || x.hasPrefix(y) || y.hasPrefix(x))
    }

    private static func firstMatch(in text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
            return nil
        }
        let ns = text as NSString
        guard let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: ns.length)),
              match.numberOfRanges >= 2 else { return nil }
        return ns.substring(with: match.range(at: 1))
    }
}

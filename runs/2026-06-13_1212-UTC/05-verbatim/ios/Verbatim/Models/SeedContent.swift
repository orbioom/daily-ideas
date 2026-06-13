import Foundation
import SwiftData

/// Three short, clearly public-domain passages so the library is never empty on
/// first run. Seeding is guarded by a one-time flag so it only runs once.
enum SeedContent {

    struct Sample {
        let title: String
        let source: String
        let category: PassageCategory
        let text: String
    }

    static let samples: [Sample] = [
        Sample(
            title: "“Hope” is the thing with feathers",
            source: "Emily Dickinson",
            category: .poem,
            text: """
            “Hope” is the thing with feathers -
            That perches in the soul -
            And sings the tune without the words -
            And never stops - at all -

            And sweetest - in the Gale - is heard -
            And sore must be the storm -
            That could abash the little Bird
            That kept so many warm -
            """),
        Sample(
            title: "Sonnet 18",
            source: "William Shakespeare",
            category: .poem,
            text: """
            Shall I compare thee to a summer’s day?
            Thou art more lovely and more temperate:
            Rough winds do shake the darling buds of May,
            And summer’s lease hath all too short a date;

            Sometime too hot the eye of heaven shines,
            And often is his gold complexion dimm’d;
            And every fair from fair sometime declines,
            By chance or nature’s changing course untrimm’d.
            """),
        Sample(
            title: "The Gettysburg Address",
            source: "Abraham Lincoln, 1863",
            category: .speech,
            text: """
            Four score and seven years ago our fathers brought forth on this \
            continent, a new nation, conceived in Liberty, and dedicated to the \
            proposition that all men are created equal.

            Now we are engaged in a great civil war, testing whether that \
            nation, or any nation so conceived and so dedicated, can long endure.
            """)
    ]

    /// Insert the samples once. The caller must check the guard flag first.
    static func insertSamples(into context: ModelContext) {
        for sample in samples {
            let passage = Passage(title: sample.title,
                                  source: sample.source,
                                  category: sample.category,
                                  fullText: sample.text)
            context.insert(passage)
        }
        try? context.save()
    }
}

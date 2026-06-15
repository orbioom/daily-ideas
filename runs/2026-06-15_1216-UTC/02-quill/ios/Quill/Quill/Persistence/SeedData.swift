import Foundation
import SwiftData
import UIKit

/// Seeds the store with realistic sample notebooks on first launch.
/// Runs once, guarded by an `@AppStorage("hasSeeded")` flag at the call site.
@MainActor
enum SeedData {
    static func seedIfNeeded(context: ModelContext) {
        // Only seed an empty store.
        let descriptor = FetchDescriptor<Notebook>()
        let existing = (try? context.fetchCount(descriptor)) ?? 0
        guard existing == 0 else { return }

        let ink = UIColor(hex: 0x1E1B2E)

        // Notebook 1 — Journal
        let journal = Notebook(
            title: "Morning Pages",
            coverColorHex: "#4C63D8",
            createdAt: .now.addingTimeInterval(-86_400 * 6),
            updatedAt: .now.addingTimeInterval(-3_600),
            defaultTemplate: .ruled,
            isFavorite: true
        )
        context.insert(journal)
        addPages(
            to: journal,
            specs: [
                (.ruled, SampleStrokes.titleSketch(color: ink)),
                (.ruled, Data()),
                (.ruled, SampleStrokes.doodle(color: UIColor(hex: 0x4C63D8)))
            ],
            context: context
        )

        // Notebook 2 — Sketchbook
        let sketch = Notebook(
            title: "Sketchbook",
            coverColorHex: "#C4453F",
            createdAt: .now.addingTimeInterval(-86_400 * 3),
            updatedAt: .now.addingTimeInterval(-86_400),
            defaultTemplate: .blank,
            isFavorite: false
        )
        context.insert(sketch)
        addPages(
            to: sketch,
            specs: [
                (.blank, SampleStrokes.doodle(color: UIColor(hex: 0xC4453F))),
                (.blank, Data())
            ],
            context: context
        )

        // Notebook 3 — Project notes
        let project = Notebook(
            title: "Project Notes",
            coverColorHex: "#2E9E6B",
            createdAt: .now.addingTimeInterval(-86_400),
            updatedAt: .now.addingTimeInterval(-1_800),
            defaultTemplate: .ruled,
            isFavorite: false
        )
        context.insert(project)
        addPages(
            to: project,
            specs: [
                (.ruled, SampleStrokes.titleSketch(color: UIColor(hex: 0x2E9E6B)))
            ],
            context: context
        )

        try? context.save()
    }

    private static func addPages(
        to notebook: Notebook,
        specs: [(PaperTemplate, Data)],
        context: ModelContext
    ) {
        for (index, spec) in specs.enumerated() {
            let page = Page(
                orderIndex: index,
                drawingData: spec.1,
                template: spec.0,
                createdAt: notebook.createdAt.addingTimeInterval(Double(index) * 60),
                updatedAt: notebook.updatedAt,
                notebook: notebook
            )
            context.insert(page)
        }
    }
}

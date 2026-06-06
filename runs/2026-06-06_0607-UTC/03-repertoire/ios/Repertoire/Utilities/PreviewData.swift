import Foundation
import SwiftUI
import SwiftData

/// A shared in-memory container seeded with sample data, for `#Preview` use only.
/// Building it once keeps previews fast and gives every screen realistic content.
@MainActor
enum PreviewData {
    /// Optional so a (practically impossible) in-memory store failure degrades to an
    /// empty canvas rather than a crash. Previews unwrap with the `.modelContainer`
    /// overload that accepts the model types directly when this is nil.
    static let container: ModelContainer? = {
        let schema = Schema([Piece.self, PracticeSpot.self, PracticeSession.self, SessionEntry.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        guard let container = try? ModelContainer(for: schema, configurations: config) else {
            return nil
        }
        SampleData.insert(into: container.mainContext)
        return container
    }()

    /// A convenience: the first sample piece, for detail-screen previews.
    static var samplePiece: Piece {
        guard let context = container?.mainContext else { return Piece(title: "Untitled") }
        let descriptor = FetchDescriptor<Piece>(sortBy: [SortDescriptor(\.createdAt)])
        return (try? context.fetch(descriptor))?.first ?? Piece(title: "Untitled")
    }
}

extension View {
    /// Attach the seeded preview container, or an empty in-memory one if creation failed.
    @MainActor @ViewBuilder
    func previewContainer() -> some View {
        if let container = PreviewData.container {
            self.modelContainer(container)
        } else {
            self.modelContainer(for: [Piece.self, PracticeSpot.self,
                                      PracticeSession.self, SessionEntry.self],
                                inMemory: true)
        }
    }
}

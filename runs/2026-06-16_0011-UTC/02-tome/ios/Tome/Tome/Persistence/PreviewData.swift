import SwiftUI
import SwiftData

/// An in-memory container seeded with the full sample library, for #Previews.
@MainActor
enum PreviewData {
    static let container: ModelContainer = {
        let container = TomeContainer.makeInMemory()
        SeedData.seed(context: container.mainContext)
        return container
    }()

    /// A single sample book for detail previews.
    static var sampleBook: Book {
        let descriptor = FetchDescriptor<Book>()
        let books = (try? container.mainContext.fetch(descriptor)) ?? []
        return books.first(where: { $0.shelf == .reading }) ?? books.first ?? Book(title: "Sample", author: "Author", pageCount: 300)
    }
}

#Preview("Reading") {
    ReadingView()
        .modelContainer(PreviewData.container)
        .environmentObject(AppSettings())
        .tint(Theme.accent)
}

#Preview("Library") {
    LibraryView()
        .modelContainer(PreviewData.container)
        .environmentObject(AppSettings())
        .tint(Theme.accent)
}

#Preview("Stats") {
    StatsView()
        .modelContainer(PreviewData.container)
        .environmentObject(AppSettings())
        .tint(Theme.accent)
}

#Preview("To Read") {
    TBRView()
        .modelContainer(PreviewData.container)
        .environmentObject(AppSettings())
        .tint(Theme.accent)
}

#Preview("Book Detail") {
    NavigationStack {
        BookDetailView(book: PreviewData.sampleBook)
    }
    .modelContainer(PreviewData.container)
    .environmentObject(AppSettings())
    .tint(Theme.accent)
}

#Preview("Settings") {
    SettingsView()
        .modelContainer(PreviewData.container)
        .environmentObject(AppSettings())
        .tint(Theme.accent)
}

#Preview("Onboarding") {
    OnboardingView()
        .environmentObject(AppSettings())
        .tint(Theme.accent)
}

import Foundation
import SwiftUI

@MainActor
final class LibraryViewModel: ObservableObject {
    @Published var books: [Book] { didSet { save() } }
    private let key = "folio.library.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let b = try? JSONDecoder().decode([Book].self, from: data) {
            books = b
        } else {
            let now = Date()
            books = [
                Book(title: "The Left Hand of Darkness", author: "Ursula K. Le Guin",
                     totalPages: 304,
                     sessions: [
                        ReadingSession(date: now.addingTimeInterval(-6*86400), page: 0),
                        ReadingSession(date: now.addingTimeInterval(-4*86400), page: 58),
                        ReadingSession(date: now.addingTimeInterval(-2*86400), page: 122),
                        ReadingSession(date: now, page: 171),
                     ]),
                Book(title: "Thinking in Systems", author: "Donella Meadows",
                     totalPages: 240,
                     sessions: [
                        ReadingSession(date: now.addingTimeInterval(-9*86400), page: 0),
                        ReadingSession(date: now.addingTimeInterval(-1*86400), page: 240),
                     ]),
            ]
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(books) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func addBook(title: String, author: String, totalPages: Int) {
        let b = Book(title: title, author: author, totalPages: totalPages,
                     sessions: [ReadingSession(date: Date(), page: 0)])
        books.insert(b, at: 0)
    }

    func logProgress(_ book: Book, page: Int) {
        guard let i = books.firstIndex(where: { $0.id == book.id }) else { return }
        let clamped = max(0, min(page, books[i].totalPages))
        books[i].sessions.append(ReadingSession(date: Date(), page: clamped))
    }

    func delete(_ book: Book) {
        books.removeAll { $0.id == book.id }
    }

    var activeBooks: [Book] { books.filter { !$0.isFinished } }
    var finishedBooks: [Book] { books.filter { $0.isFinished } }
}

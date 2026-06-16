import SwiftUI
import SwiftData

/// Log a reading session: date, pages (from→to or count), minutes.
/// Advances the book's current page and can auto-finish the book.
struct LogSessionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    @Bindable var book: Book

    @State private var date = Date()
    @State private var useRange = true
    @State private var fromText = ""
    @State private var toText = ""
    @State private var pagesText = ""
    @State private var minutesText = "30"
    @State private var validationMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Session") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    Picker("Track by", selection: $useRange) {
                        Text("Page range").tag(true)
                        Text("Pages read").tag(false)
                    }
                    .pickerStyle(.segmented)
                }

                if useRange {
                    Section("Pages") {
                        HStack {
                            Text("From").foregroundStyle(Theme.inkSoft)
                            Spacer()
                            TextField("\(book.currentPage)", text: $fromText)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: 90)
                        }
                        HStack {
                            Text("To").foregroundStyle(Theme.inkSoft)
                            Spacer()
                            TextField("\(book.pageCount)", text: $toText)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: 90)
                        }
                    }
                } else {
                    Section("Pages") {
                        HStack {
                            Text("Pages read").foregroundStyle(Theme.inkSoft)
                            Spacer()
                            TextField("0", text: $pagesText)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: 90)
                        }
                    }
                }

                Section("Time") {
                    HStack {
                        Text("Minutes").foregroundStyle(Theme.inkSoft)
                        Spacer()
                        TextField("0", text: $minutesText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 90)
                    }
                }

                if let validationMessage {
                    Section {
                        Label(validationMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(Theme.rounded(14))
                            .foregroundStyle(Theme.bad)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Log Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }.fontWeight(.semibold)
                }
            }
            .onAppear {
                fromText = String(book.currentPage)
            }
        }
    }

    private func save() {
        let minutes = max(0, Int(minutesText.trimmingCharacters(in: .whitespaces)) ?? 0)
        var pagesRead = 0
        var newCurrentPage = book.currentPage

        if useRange {
            let from = Int(fromText.trimmingCharacters(in: .whitespaces)) ?? book.currentPage
            guard let to = Int(toText.trimmingCharacters(in: .whitespaces)), to > from else {
                validationMessage = "End page must be greater than start page."
                Haptics.warning(enabled: settings.hapticsEnabled)
                return
            }
            pagesRead = to - from
            newCurrentPage = min(book.pageCount, to)
        } else {
            guard let count = Int(pagesText.trimmingCharacters(in: .whitespaces)), count > 0 else {
                validationMessage = "Enter how many pages you read."
                Haptics.warning(enabled: settings.hapticsEnabled)
                return
            }
            pagesRead = count
            newCurrentPage = min(book.pageCount, book.currentPage + count)
        }

        let session = ReadingSession(date: date, pagesRead: pagesRead, minutes: minutes)
        session.book = book
        book.sessions.append(session)
        context.insert(session)

        book.currentPage = newCurrentPage
        if book.shelf == .wantToRead {
            book.shelf = .reading
        }
        if book.startedDate == nil {
            book.startedDate = date
        }
        // Auto-finish when the last page is reached.
        if book.currentPage >= book.pageCount, book.shelf == .reading {
            book.shelf = .finished
            book.finishedDate = date
        }

        try? context.save()
        Haptics.success(enabled: settings.hapticsEnabled)
        dismiss()
    }
}

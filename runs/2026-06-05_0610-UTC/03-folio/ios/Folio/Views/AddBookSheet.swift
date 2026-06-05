import SwiftUI

struct AddBookSheet: View {
    @ObservedObject var vm: LibraryViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var author = ""
    @State private var pages = ""

    private var valid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && (Int(pages) ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                OrbMistBackground()
                Form {
                    Section {
                        TextField("Title", text: $title)
                        TextField("Author", text: $author)
                        TextField("Total pages", text: $pages)
                            .keyboardType(.numberPad)
                    } header: { Text("New book") }
                        .listRowBackground(Color.white.opacity(0.45))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Add a book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        vm.addBook(title: title, author: author, totalPages: Int(pages) ?? 0)
                        dismiss()
                    }.disabled(!valid)
                }
            }
        }
    }
}

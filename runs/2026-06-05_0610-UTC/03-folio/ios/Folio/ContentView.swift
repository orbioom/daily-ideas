import SwiftUI

struct ContentView: View {
    @StateObject private var vm = LibraryViewModel()
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            ZStack {
                OrbMistBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        header
                        if vm.activeBooks.isEmpty && vm.finishedBooks.isEmpty {
                            empty
                        }
                        ForEach(vm.activeBooks) { book in
                            NavigationLink {
                                BookDetailView(vm: vm, bookID: book.id)
                            } label: {
                                BookCard(book: book)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) { vm.delete(book) } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                            }
                        }
                        if !vm.finishedBooks.isEmpty {
                            Text("FINISHED").eyebrow().padding(.top, 8)
                            ForEach(vm.finishedBooks) { book in
                                NavigationLink {
                                    BookDetailView(vm: vm, bookID: book.id)
                                } label: { BookCard(book: book) }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) { vm.delete(book) } label: {
                                        Label("Remove", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAdd) { AddBookSheet(vm: vm) }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("FOLIO").eyebrow()
                Text("Your reading")
                    .font(.system(.title, design: .rounded).weight(.bold))
                    .foregroundStyle(Color.orbInk)
            }
            Spacer()
            Button { showAdd = true } label: {
                Image(systemName: "plus")
                    .font(.headline).foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(LinearGradient(colors: [Color(red:0.227,green:0.243,blue:0.298),
                                                        Color(red:0.137,green:0.149,blue:0.184)],
                                               startPoint: .top, endPoint: .bottom),
                                in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    private var empty: some View {
        VStack(spacing: 8) {
            Image(systemName: "books.vertical")
                .font(.system(size: 38)).foregroundStyle(Color.orbText3)
            Text("Add a book to start tracking your pace.")
                .font(.subheadline).foregroundStyle(Color.orbText2)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 60)
    }
}

#Preview {
    ContentView()
}

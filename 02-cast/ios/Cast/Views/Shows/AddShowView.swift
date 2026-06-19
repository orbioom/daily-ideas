import SwiftUI
import SwiftData

struct AddShowView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var showToEdit: PodcastShow? = nil

    @State private var title = ""
    @State private var host = ""
    @State private var genre: PodcastGenre = .other
    @State private var status: ShowStatus = .active
    @State private var rating = 0
    @State private var notes = ""
    @State private var showValidation = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Show Info") {
                    TextField("Podcast title", text: $title)
                        .accessibilityLabel("Podcast title")
                    TextField("Host name", text: $host)
                        .accessibilityLabel("Host name")
                }
                Section("Category") {
                    Picker("Genre", selection: $genre) {
                        ForEach(PodcastGenre.allCases, id: \.self) { g in
                            Label(g.rawValue, systemImage: g.icon).tag(g)
                        }
                    }
                    Picker("Status", selection: $status) {
                        ForEach(ShowStatus.allCases, id: \.self) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }
                }
                Section("My Rating") {
                    HStack(spacing: 10) {
                        ForEach(1...5, id: \.self) { i in
                            Button {
                                rating = rating == i ? 0 : i
                            } label: {
                                Image(systemName: i <= rating ? "star.fill" : "star")
                                    .foregroundStyle(i <= rating ? .yellow : .secondary)
                            }
                        }
                        Spacer()
                    }
                }
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 60)
                }
            }
            .navigationTitle(showToEdit != nil ? "Edit Show" : "New Show")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .alert("Missing Title", isPresented: $showValidation) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please enter the podcast title.")
            }
            .onAppear {
                guard let s = showToEdit else { return }
                title = s.title; host = s.host; genre = s.genre
                status = s.status; rating = s.rating; notes = s.notes
            }
        }
    }

    private func save() {
        let t = title.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { showValidation = true; return }
        if let s = showToEdit {
            s.title = t; s.host = host; s.genre = genre
            s.status = status; s.rating = rating; s.notes = notes
        } else {
            context.insert(PodcastShow(title: t, host: host, genre: genre,
                                       status: status, rating: rating, notes: notes))
        }
        dismiss()
    }
}

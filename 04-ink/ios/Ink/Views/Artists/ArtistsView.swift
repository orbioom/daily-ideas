import SwiftUI
import SwiftData

struct ArtistsView: View {
    @Query(sort: \TattooArtist.name) private var artists: [TattooArtist]
    @Environment(\.modelContext) private var modelContext
    @State private var showAdd = false
    @State private var searchText = ""

    var filtered: [TattooArtist] {
        guard !searchText.isEmpty else { return artists }
        return artists.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.studio.localizedCaseInsensitiveContains(searchText) ||
            $0.city.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ZStack {
            InkTheme.background.ignoresSafeArea()
            if filtered.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(filtered) { artist in
                        NavigationLink {
                            ArtistDetailView(artist: artist)
                        } label: {
                            ArtistRow(artist: artist)
                        }
                        .listRowBackground(InkTheme.surface)
                    }
                    .onDelete(perform: delete)
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
            }
        }
        .searchable(text: $searchText, prompt: "Search artists")
        .navigationTitle("Artists")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(InkTheme.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAdd = true } label: {
                    Image(systemName: "plus").foregroundStyle(InkTheme.accent)
                }
            }
        }
        .sheet(isPresented: $showAdd) { AddArtistView() }
    }

    var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.rectangle.fill")
                .font(.system(size: 52))
                .foregroundStyle(InkTheme.textSecondary)
            Text("No Artists Saved")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(InkTheme.textPrimary)
            Text("Save tattoo artists you're interested in for easy reference.")
                .font(.system(size: 15))
                .foregroundStyle(InkTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button { showAdd = true } label: {
                Text("Add Artist")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(InkTheme.accent, in: Capsule())
            }
        }
    }

    func delete(at offsets: IndexSet) {
        for i in offsets { modelContext.delete(filtered[i]) }
    }
}

struct ArtistRow: View {
    let artist: TattooArtist

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(InkTheme.accent.opacity(0.2))
                    .frame(width: 44, height: 44)
                Text(String(artist.name.prefix(1)).uppercased())
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(InkTheme.accent)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(artist.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(InkTheme.textPrimary)
                HStack(spacing: 8) {
                    if !artist.studio.isEmpty {
                        Text(artist.studio)
                            .font(.system(size: 13))
                            .foregroundStyle(InkTheme.textSecondary)
                    }
                    if !artist.city.isEmpty {
                        Text("· \(artist.city)")
                            .font(.system(size: 13))
                            .foregroundStyle(InkTheme.textSecondary)
                    }
                }
                HStack(spacing: 2) {
                    ForEach(0..<5) { i in
                        Image(systemName: i < artist.rating ? "star.fill" : "star")
                            .font(.system(size: 10))
                            .foregroundStyle(i < artist.rating ? InkTheme.accentOrange : InkTheme.textSecondary.opacity(0.4))
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct ArtistDetailView: View {
    @Bindable var artist: TattooArtist
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            InkTheme.background.ignoresSafeArea()
            List {
                Section {
                    detailRow("Studio", artist.studio)
                    detailRow("City", artist.city)
                    detailRow("Instagram", artist.instagram.isEmpty ? "—" : "@\(artist.instagram)")
                    detailRow("Price Range", artist.priceRange)
                } header: { Text("Info").foregroundStyle(InkTheme.textSecondary) }
                .listRowBackground(InkTheme.surface)

                Section {
                    HStack(spacing: 4) {
                        ForEach(0..<5) { i in
                            Image(systemName: i < artist.rating ? "star.fill" : "star")
                                .font(.system(size: 20))
                                .foregroundStyle(i < artist.rating ? InkTheme.accentOrange : InkTheme.textSecondary.opacity(0.3))
                                .onTapGesture { artist.rating = i + 1 }
                        }
                        Text("(\(artist.rating)/5)")
                            .font(.system(size: 13))
                            .foregroundStyle(InkTheme.textSecondary)
                            .padding(.leading, 8)
                    }
                } header: { Text("Rating").foregroundStyle(InkTheme.textSecondary) }
                .listRowBackground(InkTheme.surface)

                if !artist.specialties.isEmpty {
                    Section {
                        ForEach(artist.specialties, id: \.self) { s in
                            Text(s).foregroundStyle(InkTheme.textPrimary)
                        }
                    } header: { Text("Specialties").foregroundStyle(InkTheme.textSecondary) }
                    .listRowBackground(InkTheme.surface)
                }

                if !artist.notes.isEmpty {
                    Section {
                        Text(artist.notes).foregroundStyle(InkTheme.textPrimary)
                    } header: { Text("Notes").foregroundStyle(InkTheme.textSecondary) }
                    .listRowBackground(InkTheme.surface)
                }

                Section {
                    Button(role: .destructive) {
                        modelContext.delete(artist)
                        dismiss()
                    } label: {
                        Text("Delete Artist").foregroundStyle(.red)
                    }
                }
                .listRowBackground(InkTheme.surface)
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(artist.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(InkTheme.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(InkTheme.textSecondary)
            Spacer()
            Text(value.isEmpty ? "—" : value).foregroundStyle(InkTheme.textPrimary)
        }
    }
}

struct AddArtistView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var studio = ""
    @State private var instagram = ""
    @State private var city = ""
    @State private var specialtiesText = ""
    @State private var rating = 5
    @State private var notes = ""
    @State private var priceRange = "$150-250/hr"

    var body: some View {
        NavigationStack {
            ZStack {
                InkTheme.background.ignoresSafeArea()
                Form {
                    Section {
                        TextField("Artist Name", text: $name)
                        TextField("Studio", text: $studio)
                        TextField("City", text: $city)
                        TextField("Instagram handle", text: $instagram)
                    } header: {
                        Text("Artist Info").foregroundStyle(InkTheme.textSecondary)
                    }
                    .listRowBackground(InkTheme.surface)
                    .foregroundStyle(InkTheme.textPrimary)

                    Section {
                        TextField("Price range (e.g. $150-250/hr)", text: $priceRange)
                        TextField("Specialties (comma separated)", text: $specialtiesText)
                    } header: {
                        Text("Work").foregroundStyle(InkTheme.textSecondary)
                    }
                    .listRowBackground(InkTheme.surface)
                    .foregroundStyle(InkTheme.textPrimary)

                    Section {
                        HStack {
                            Text("Rating").foregroundStyle(InkTheme.textSecondary)
                            Spacer()
                            HStack(spacing: 4) {
                                ForEach(1...5, id: \.self) { i in
                                    Image(systemName: i <= rating ? "star.fill" : "star")
                                        .foregroundStyle(i <= rating ? InkTheme.accentOrange : InkTheme.textSecondary.opacity(0.4))
                                        .onTapGesture { rating = i }
                                }
                            }
                        }
                        TextField("Notes", text: $notes, axis: .vertical)
                            .lineLimit(3...6)
                            .foregroundStyle(InkTheme.textPrimary)
                    } header: {
                        Text("Notes & Rating").foregroundStyle(InkTheme.textSecondary)
                    }
                    .listRowBackground(InkTheme.surface)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("New Artist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(InkTheme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundStyle(InkTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .foregroundStyle(InkTheme.accent)
                        .disabled(name.isEmpty)
                }
            }
        }
    }

    func save() {
        let specialties = specialtiesText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        let artist = TattooArtist(
            name: name, studio: studio, instagram: instagram, city: city,
            specialties: specialties, rating: rating, notes: notes, priceRange: priceRange
        )
        modelContext.insert(artist)
        dismiss()
    }
}

import SwiftUI
import SwiftData

struct ObservationDetailView: View {
    @Bindable var observation: Observation
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var showingEdit = false
    @State private var showingDelete = false

    private static let df: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .long; f.timeStyle = .short; return f
    }()

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                heroSection
                if !observation.habitat.isEmpty || !observation.locationName.isEmpty {
                    locationSection
                }
                conditionGrid
                if !observation.behavior.isEmpty || !observation.notes.isEmpty {
                    notesSection
                }
            }
            .padding()
        }
        .navigationTitle(observation.displayName)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button { showingEdit = true } label: { Image(systemName: "pencil") }
                    .foregroundStyle(FieldTheme.fern).accessibilityLabel("Edit")
                Button(role: .destructive) { showingDelete = true } label: { Image(systemName: "trash") }
                    .foregroundStyle(.red).accessibilityLabel("Delete")
            }
        }
        .sheet(isPresented: $showingEdit) { ObservationFormView(observation: observation) }
        .confirmationDialog("Delete this sighting?", isPresented: $showingDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                context.delete(observation); try? context.save(); dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: { Text("This cannot be undone.") }
    }

    private var heroSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    if !observation.speciesName.isEmpty && observation.speciesName != observation.commonName {
                        Text(observation.speciesName)
                            .font(.subheadline.italic())
                            .foregroundStyle(.secondary)
                    }
                    Text(Self.df.string(from: observation.date))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if observation.isLifer {
                    LiferBadge()
                }
            }
            HStack(spacing: 16) {
                Text(observation.speciesClass.emoji).font(.system(size: 44)).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    SpeciesClassBadge(speciesClass: observation.speciesClass)
                    if observation.count > 1 {
                        Label("\(observation.count) individuals", systemImage: "number")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 5, x: 0, y: 2)
    }

    private var locationSection: some View {
        HStack(spacing: 12) {
            if !observation.locationName.isEmpty {
                Label(observation.locationName, systemImage: "mappin.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(FieldTheme.fern)
            }
            if !observation.habitat.isEmpty {
                Divider().frame(height: 16)
                Label(observation.habitat, systemImage: "leaf.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Location: \(observation.locationName). Habitat: \(observation.habitat)")
    }

    private var conditionGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            InfoCell2(icon: "binoculars.fill", title: "Quality", value: observation.quality.rawValue)
            InfoCell2(icon: observation.weather.sfSymbol, title: "Weather", value: observation.weather.rawValue)
            if !observation.tripName.isEmpty {
                InfoCell2(icon: "map.fill", title: "Trip", value: observation.tripName)
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !observation.behavior.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Behaviour", systemImage: "figure.walk").font(.headline)
                    Text(observation.behavior).font(.body).foregroundStyle(.secondary)
                }
            }
            if !observation.notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Notes", systemImage: "note.text").font(.headline)
                    Text(observation.notes).font(.body).foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
}

struct InfoCell2: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon).foregroundStyle(FieldTheme.fern).frame(width: 20).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption).foregroundStyle(.secondary)
                Text(value).font(.subheadline.bold())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

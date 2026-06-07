import SwiftUI
import SwiftData

struct GearView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Telescope.name) private var scopes: [Telescope]
    @Query(sort: \Eyepiece.focalLength, order: .reverse) private var eyepieces: [Eyepiece]
    @State private var addScope = false
    @State private var addEyepiece = false

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if scopes.isEmpty && eyepieces.isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "binoculars",
                                       title: "No gear yet",
                                       message: "Add a telescope and a few eyepieces — Zenith handles the rest of the math.")
                            .padding(.top, 60)
                    }
                } else {
                    List {
                        Section {
                            ForEach(scopes) { s in
                                NavigationLink { TelescopeDetailView(scope: s) } label: { ScopeRow(scope: s) }
                                    .listRowBackground(Color.clear).listRowSeparator(.hidden)
                            }
                            .onDelete { idx in idx.forEach { context.delete(scopes[$0]) }; try? context.save() }
                        } header: { Text("Telescopes").foregroundStyle(Brand.text2) }

                        Section {
                            ForEach(eyepieces) { e in
                                Button { editEyepiece = e } label: { EyepieceRow(eyepiece: e) }
                                    .buttonStyle(.plain)
                                    .listRowBackground(Color.clear).listRowSeparator(.hidden)
                            }
                            .onDelete { idx in idx.forEach { context.delete(eyepieces[$0]) }; try? context.save() }
                        } header: { Text("Eyepieces").foregroundStyle(Brand.text2) }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Gear")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button { addScope = true } label: { Label("Telescope", systemImage: "binoculars") }
                        Button { addEyepiece = true } label: { Label("Eyepiece", systemImage: "circle.circle") }
                    } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $addScope) { ScopeEditView(scope: nil) }
            .sheet(isPresented: $addEyepiece) { EyepieceEditView(eyepiece: nil) }
            .sheet(item: $editEyepiece) { e in EyepieceEditView(eyepiece: e) }
        }
    }

    @State private var editEyepiece: Eyepiece?
}

struct ScopeRow: View {
    let scope: Telescope
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(scope.name).font(.headline).foregroundStyle(Brand.text)
                Spacer()
                if scope.isPrimary {
                    Image(systemName: "star.fill").font(.caption).foregroundStyle(Brand.warn)
                        .accessibilityLabel("Primary")
                }
            }
            HStack(spacing: 8) {
                Chip(text: scope.type.label)
                Chip(text: "\(Int(scope.aperture))mm", system: "circle.circle")
                Chip(text: String(format: "f/%.1f", scope.focalRatio))
            }
        }
        .glassCard()
    }
}

struct EyepieceRow: View {
    let eyepiece: Eyepiece
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(eyepiece.name).font(.headline).foregroundStyle(Brand.text)
                if !eyepiece.brand.isEmpty {
                    Text(eyepiece.brand).font(.caption).foregroundStyle(Brand.text3)
                }
            }
            Spacer()
            Chip(text: "\(Int(eyepiece.focalLength))mm")
            Chip(text: "\(Int(eyepiece.apparentFOV))° AFOV", tint: Brand.info)
        }
        .glassCard()
    }
}

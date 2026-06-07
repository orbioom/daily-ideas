import SwiftUI
import SwiftData

struct TelescopeDetailView: View {
    @Bindable var scope: Telescope
    @Environment(\.modelContext) private var context
    @Query(sort: \Eyepiece.focalLength, order: .reverse) private var eyepieces: [Eyepiece]
    @State private var showingEdit = false

    var body: some View {
        ZStack {
            Brand.pageBackground
            ScrollView {
                VStack(spacing: 16) {
                    specCard
                    limitsCard
                    eyepieceGrid
                    if !scope.notes.isEmpty { notesCard }
                }
                .padding(.horizontal, 18).padding(.vertical, 12)
            }
        }
        .navigationTitle(scope.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showingEdit = true } label: { Label("Edit", systemImage: "pencil") }
                    Button {
                        scope.isPrimary.toggle(); try? context.save()
                    } label: { Label(scope.isPrimary ? "Unset primary" : "Set primary", systemImage: "star") }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .sheet(isPresented: $showingEdit) { ScopeEditView(scope: scope) }
    }

    private var specCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatTile(value: "\(Int(scope.aperture))", label: "Aperture mm", accent: Brand.info)
                StatTile(value: "\(Int(scope.focalLength))", label: "Focal mm")
                StatTile(value: String(format: "f/%.1f", scope.focalRatio), label: "Focal ratio", accent: Brand.magic)
            }
        }
    }

    private var limitsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "What it can do")
            specRow("Max useful power", Fmt.mag(scope.maxUsefulMag), Brand.warn)
            specRow("Min useful power", Fmt.mag(scope.minUsefulMag), Brand.text2)
            specRow("Resolving power (Dawes)", String(format: "%.2f″", scope.dawesLimit), Brand.live)
            specRow("Limiting magnitude", String(format: "%.1f", scope.limitingMagnitude), Brand.info)
        }
        .glassCard()
    }

    private func specRow(_ label: String, _ value: String, _ tint: Color) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(Brand.text2)
            Spacer()
            Text(value).font(Brand.mono(15, weight: .semibold)).foregroundStyle(tint)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private var eyepieceGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "With your eyepieces", trailing: "\(eyepieces.count)")
            if eyepieces.isEmpty {
                Text("Add eyepieces to see the magnification and field each one gives in this scope.")
                    .font(.subheadline).foregroundStyle(Brand.text2)
            } else {
                VStack(spacing: 0) {
                    HStack {
                        Text("Eyepiece").font(Brand.mono(11, weight: .medium)).foregroundStyle(Brand.text3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("Power").font(Brand.mono(11, weight: .medium)).foregroundStyle(Brand.text3)
                            .frame(width: 64, alignment: .trailing)
                        Text("TFOV").font(Brand.mono(11, weight: .medium)).foregroundStyle(Brand.text3)
                            .frame(width: 64, alignment: .trailing)
                        Text("Exit").font(Brand.mono(11, weight: .medium)).foregroundStyle(Brand.text3)
                            .frame(width: 56, alignment: .trailing)
                    }
                    .padding(.bottom, 8)
                    ForEach(eyepieces) { e in
                        let v = Optics.view(scopeFL: scope.focalLength, aperture: scope.aperture,
                                            eyepieceFL: e.focalLength, apparentFOV: e.apparentFOV)
                        HStack {
                            Text("\(Int(e.focalLength))mm").font(Brand.mono(13)).foregroundStyle(Brand.text)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(Fmt.mag(v.magnification)).font(Brand.mono(13))
                                .foregroundStyle(v.magnification > scope.maxUsefulMag ? Brand.warn : Brand.text2)
                                .frame(width: 64, alignment: .trailing)
                            Text(Fmt.deg(v.trueFOVDegrees)).font(Brand.mono(13)).foregroundStyle(Brand.text2)
                                .frame(width: 64, alignment: .trailing)
                            Text(String(format: "%.1f", v.exitPupilMM)).font(Brand.mono(13)).foregroundStyle(Brand.text2)
                                .frame(width: 56, alignment: .trailing)
                        }
                        .padding(.vertical, 6)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(Int(e.focalLength)) millimetre: \(Fmt.mag(v.magnification)), field \(Fmt.deg(v.trueFOVDegrees)), exit pupil \(String(format: "%.1f", v.exitPupilMM)) millimetres")
                        if e.persistentModelID != eyepieces.last?.persistentModelID {
                            Divider().overlay(Brand.hairline)
                        }
                    }
                }
                .glassCard()
            }
        }
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHeader(title: "Notes")
            Text(scope.notes).font(.subheadline).foregroundStyle(Brand.text2)
        }
        .glassCard()
    }
}

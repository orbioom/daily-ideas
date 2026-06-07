import SwiftUI
import SwiftData

/// Live chart viewer with transpose, capo-shape, and Nashville controls.
struct SongDetailView: View {
    @Bindable var song: Song
    @State private var transpose = 0
    @State private var nashville = false
    @State private var showingEdit = false

    private var soundingKey: String { ChordEngine.transposedKey(song.key, semitones: transpose) }
    private var preferFlats: Bool { ChordEngine.preferFlats(forKey: soundingKey) }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                controlCard
                if song.orderedSections.isEmpty {
                    EmptyStateView(icon: "doc.text", title: "No chart",
                                   message: "Edit this song to add sections and chords.").glassCard()
                } else {
                    ForEach(song.orderedSections) { section in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(section.name.uppercased())
                                .font(Brand.mono(11, weight: .semibold)).tracking(1.2)
                                .foregroundStyle(Brand.text3)
                            ChartView(content: section.content, semitones: transpose,
                                      preferFlats: preferFlats, nashville: nashville, key: song.key)
                        }
                        .glassCard()
                    }
                }
                if !song.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        SectionTitle(text: "Notes")
                        Text(song.notes).font(.subheadline).foregroundStyle(Brand.text2)
                    }.glassCard()
                }
            }
            .padding()
        }
        .navigationTitle(song.title)
        .navigationBarTitleDisplayMode(.inline)
        .background(Brand.pageBackground)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { Button("Edit") { showingEdit = true } }
        }
        .sheet(isPresented: $showingEdit) { SongEditView(existing: song) }
    }

    private var controlCard: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sounding key").font(.caption).foregroundStyle(Brand.text3)
                    Text(soundingKey).font(Brand.mono(28, weight: .bold)).foregroundStyle(Brand.text)
                        .contentTransition(.numericText())
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Original \(song.key)").font(.caption).foregroundStyle(Brand.text3)
                    if song.bpm > 0 { Text("\(song.bpm) bpm · \(song.timeSignature)").font(.caption).foregroundStyle(Brand.text3) }
                }
            }
            HStack(spacing: 12) {
                Button {
                    transpose -= 1; Haptics.selection()
                } label: { Image(systemName: "minus").frame(maxWidth: .infinity).padding(.vertical, 10) }
                    .buttonStyle(GlassButtonStyle())
                    .accessibilityLabel("Transpose down")
                VStack(spacing: 0) {
                    Text(transpose == 0 ? "0" : (transpose > 0 ? "+\(transpose)" : "\(transpose)"))
                        .font(Brand.mono(18, weight: .bold)).foregroundStyle(Brand.text)
                    Text("semitones").font(Brand.mono(9)).foregroundStyle(Brand.text3)
                }
                .frame(width: 80)
                Button {
                    transpose += 1; Haptics.selection()
                } label: { Image(systemName: "plus").frame(maxWidth: .infinity).padding(.vertical, 10) }
                    .buttonStyle(GlassButtonStyle())
                    .accessibilityLabel("Transpose up")
            }
            HStack {
                let shapeKey = ChordEngine.shapesKey(soundingKey: soundingKey, capo: song.capo)
                if song.capo > 0 {
                    Label("Capo \(song.capo) · play \(shapeKey) shapes", systemImage: "guitars")
                        .font(.caption).foregroundStyle(Brand.text2)
                } else {
                    Text("No capo").font(.caption).foregroundStyle(Brand.text3)
                }
                Spacer()
                if transpose != 0 {
                    Button("Reset") { withAnimation { transpose = 0 }; Haptics.tap() }
                        .font(.caption).foregroundStyle(Brand.live)
                }
            }
            Divider().overlay(Brand.hairline)
            Toggle(isOn: $nashville) {
                Text("Nashville numbers").font(.subheadline).foregroundStyle(Brand.text)
            }.tint(Brand.live)
        }
        .glassCard()
    }
}

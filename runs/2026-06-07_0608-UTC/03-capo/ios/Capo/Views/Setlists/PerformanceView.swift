import SwiftUI
import SwiftData

/// A swipeable, large-type performance view: one song chart per page, already
/// transposed to its setlist key and showing the capo shapes to play.
struct PerformanceView: View {
    @Bindable var setlist: Setlist
    @State private var page = 0

    private var items: [SetlistItem] { setlist.orderedItems }

    var body: some View {
        TabView(selection: $page) {
            ForEach(Array(items.enumerated()), id: \.element.id) { idx, item in
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        if let song = item.song {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(idx + 1) of \(items.count)")
                                    .font(Brand.mono(11)).foregroundStyle(Brand.text3)
                                Text(song.title).font(.title.weight(.bold)).foregroundStyle(Brand.text)
                                HStack(spacing: 10) {
                                    Text("Key \(item.performKey)").font(Brand.mono(15, weight: .semibold)).foregroundStyle(Brand.live)
                                    if item.capo > 0 {
                                        let shape = ChordEngine.shapesKey(soundingKey: item.performKey, capo: item.capo)
                                        Text("Capo \(item.capo) · \(shape) shapes").font(.caption).foregroundStyle(Brand.text2)
                                    }
                                    if song.bpm > 0 { Text("\(song.bpm) bpm").font(.caption).foregroundStyle(Brand.text2) }
                                }
                                if !item.note.isEmpty {
                                    Text(item.note).font(.caption).italic().foregroundStyle(Brand.text3)
                                }
                            }
                            ForEach(song.orderedSections) { section in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(section.name.uppercased())
                                        .font(Brand.mono(11, weight: .semibold)).tracking(1.2).foregroundStyle(Brand.text3)
                                    ChartView(content: section.content, semitones: item.transpose,
                                              preferFlats: ChordEngine.preferFlats(forKey: item.performKey),
                                              nashville: false, key: song.key)
                                }
                            }
                        } else {
                            EmptyStateView(icon: "questionmark", title: "Song removed", message: "This slot's song no longer exists.")
                        }
                    }
                    .padding()
                }
                .tag(idx)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
        .indexViewStyle(.page(backgroundDisplayMode: .interactive))
        .background(Brand.pageBackground)
        .navigationTitle("Performance")
        .navigationBarTitleDisplayMode(.inline)
    }
}

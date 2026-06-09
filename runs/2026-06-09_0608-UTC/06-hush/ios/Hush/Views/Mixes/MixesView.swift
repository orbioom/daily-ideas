import SwiftUI
import SwiftData

struct MixesView: View {
    @Environment(MixerEngine.self) private var engine
    @Environment(\.modelContext) private var context
    @Query(sort: \Mix.sortIndex) private var mixes: [Mix]

    private var builtIns: [Mix] { mixes.filter { $0.isBuiltIn } }
    private var custom: [Mix] { mixes.filter { !$0.isBuiltIn } }

    var body: some View {
        NavigationStack {
            Group {
                if mixes.isEmpty {
                    EmptyStateView(icon: "square.stack",
                                   title: "No mixes yet",
                                   message: "Blend sounds in the Mixer, then save your favourites here for one-tap recall.")
                        .padding(20)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Brand.pageBackground)
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            if !builtIns.isEmpty {
                                section("Curated", mixes: builtIns, deletable: false)
                            }
                            if !custom.isEmpty {
                                section("Your mixes", mixes: custom, deletable: true)
                            } else {
                                Text("Save a blend in the Mixer to see it here.")
                                    .font(.footnote)
                                    .foregroundStyle(Brand.text3)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(20)
                    }
                    .background(Brand.pageBackground)
                }
            }
            .navigationTitle("Mixes")
        }
    }

    private func section(_ title: String, mixes list: [Mix], deletable: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: title)
            ForEach(list) { mix in
                mixRow(mix, deletable: deletable)
            }
        }
    }

    private func mixRow(_ mix: Mix, deletable: Bool) -> some View {
        Button {
            Haptics.tap()
            engine.apply(mix)
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Brand.magic.opacity(0.14))
                        .frame(width: 46, height: 46)
                    Image(systemName: "play.fill")
                        .foregroundStyle(Brand.magic)
                        .accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(mix.name)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Brand.text)
                    Text(mix.summary)
                        .font(.caption)
                        .foregroundStyle(Brand.text2)
                }
                Spacer()
                Text("\(mix.layers.count)")
                    .font(Brand.mono(14, weight: .medium))
                    .foregroundStyle(Brand.text3)
            }
            .glassCard(padding: 12)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(mix.name), \(mix.summary)")
        .accessibilityHint("Plays this mix")
        .contextMenu {
            if deletable {
                Button(role: .destructive) {
                    context.delete(mix)
                    try? context.save()
                    Haptics.warning()
                } label: { Label("Delete", systemImage: "trash") }
            }
        }
    }
}

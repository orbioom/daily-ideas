import SwiftUI

/// A reference + preview screen describing each generated sound. Tapping a row
/// toggles that single layer in the live mixer so you can audition it.
struct SoundLibraryView: View {
    @Environment(MixerEngine.self) private var engine

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    intro
                    ForEach(SoundType.allCases) { type in
                        row(type)
                    }
                }
                .padding(20)
            }
            .background(Brand.pageBackground)
            .navigationTitle("Sounds")
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 8) {
            Eyebrow(text: "On-device synthesis")
            Text("Eight sounds, no files")
                .font(.title3.weight(.bold))
                .foregroundStyle(Brand.text)
            Text("Each sound is generated in real time on your device. Tap any sound to audition it in the mixer.")
                .font(.subheadline)
                .foregroundStyle(Brand.text2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(padding: 16)
    }

    private func row(_ type: SoundType) -> some View {
        let active = engine.isActive(type)
        return Button {
            Haptics.selection()
            engine.toggle(type)
        } label: {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(active ? Brand.magic.opacity(0.18) : Brand.hairline.opacity(0.5))
                        .frame(width: 44, height: 44)
                    Image(systemName: type.symbol)
                        .foregroundStyle(active ? Brand.magic : Brand.text3)
                        .accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(type.label)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Brand.text)
                        if type.isPremium {
                            Text("PRO")
                                .font(Brand.mono(9, weight: .medium))
                                .foregroundStyle(Brand.magic)
                                .padding(.horizontal, 5).padding(.vertical, 2)
                                .background(Brand.magic.opacity(0.14), in: Capsule())
                        }
                    }
                    Text(type.blurb)
                        .font(.caption)
                        .foregroundStyle(Brand.text2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Image(systemName: active ? "speaker.wave.2.fill" : "play.circle")
                    .foregroundStyle(active ? Brand.live : Brand.text3)
                    .accessibilityHidden(true)
            }
            .glassCard(padding: 14)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(type.label). \(type.blurb)")
        .accessibilityHint(active ? "Stops auditioning" : "Auditions this sound")
        .accessibilityAddTraits(active ? [.isSelected] : [])
    }
}

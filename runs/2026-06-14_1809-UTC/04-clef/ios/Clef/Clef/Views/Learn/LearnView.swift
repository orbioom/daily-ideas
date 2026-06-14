import SwiftUI

/// Reference library: each clef's lines & spaces with names, mnemonics, and a how-to.
struct LearnView: View {
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @State private var clef: Clef = .treble

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    clefPicker
                    mnemonicsCard
                    notesCard
                    ledgerCard
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Learn")
            .onAppear {
                if clef.requiresPro && !isPro { clef = .treble }
            }
        }
    }

    private var clefPicker: some View {
        Picker("Clef", selection: $clef) {
            ForEach(Clef.allCases) { c in
                Text(c.displayName).tag(c)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: clef) { _, newValue in
            // Learn is free to browse even for Pro clefs (it's reference, not drilling).
            _ = newValue
        }
    }

    private var info: ClefReference { ClefReference.forClef(clef) }

    private var mnemonicsCard: some View {
        CardSection("Mnemonics") {
            VStack(alignment: .leading, spacing: 12) {
                mnemonicRow("Lines (bottom → top)", info.lineMnemonic, info.lineLetters)
                Divider().overlay(Theme.hairline)
                mnemonicRow("Spaces (bottom → top)", info.spaceMnemonic, info.spaceLetters)
            }
        }
    }

    private func mnemonicRow(_ title: String, _ phrase: String, _ letters: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(Theme.rounded(12, .semibold)).foregroundStyle(Theme.inkSoft)
            Text(phrase).font(Theme.serif(18, .semibold)).foregroundStyle(Theme.accent)
            Text(letters.joined(separator: "  ·  "))
                .font(Theme.rounded(14, .medium))
                .foregroundStyle(Theme.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(phrase), notes \(letters.joined(separator: ", "))")
    }

    private var notesCard: some View {
        CardSection("Notes on the staff") {
            VStack(spacing: 14) {
                ForEach(info.referenceMIDIs, id: \.self) { midi in
                    noteReferenceRow(midi)
                }
            }
        }
    }

    private func noteReferenceRow(_ midi: Int) -> some View {
        HStack(spacing: 14) {
            StaffView(clef: clef,
                      midi: midi,
                      accessibilityText: NoteDescription.describe(midi: midi, clef: clef, useFlats: settings.useFlats))
                .frame(width: 150, height: 96)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.surfaceAlt)
                )
            VStack(alignment: .leading, spacing: 3) {
                Text(Pitch.displayLetter(Pitch(midi).letterName, solfege: settings.noteNameStyle.useSolfege))
                    .font(Theme.serif(22, .bold))
                    .foregroundStyle(Theme.ink)
                Text(positionText(midi))
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(NoteDescription.describe(midi: midi, clef: clef, useFlats: settings.useFlats))
    }

    private func positionText(_ midi: Int) -> String {
        let step = StaffLayout.diatonicStep(midi: midi, bottomLineMIDI: clef.bottomLineMIDI)
        if step >= 0 && step <= 8 {
            return StaffLayout.isOnLine(diatonicStep: step) ? "On a line" : "In a space"
        }
        return step < 0 ? "Below the staff" : "Above the staff"
    }

    private var ledgerCard: some View {
        CardSection("Reading ledger lines") {
            Text("When a note sits above or below the five staff lines, short extra lines — ledger lines — extend the staff to reach it. Count them outward from the staff: each ledger line or the space just beyond it is the next letter in sequence. Middle C, for example, rides one ledger line below the treble staff and one above the bass staff.")
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

import SwiftUI
import SwiftData

struct ChangesView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("changeDuration") private var duration = 60
    @AppStorage("changeChordA") private var chordAID = "C"
    @AppStorage("changeChordB") private var chordBID = "G"
    @State private var vm: ChangesViewModel?
    @State private var savedCPM: Int?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var chordA: Chord { ChordLibrary.byID(chordAID) ?? ChordLibrary.all[0] }
    private var chordB: Chord { ChordLibrary.byID(chordBID) ?? ChordLibrary.all[2] }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if let vm { running(vm) } else { setup }
            }
            .navigationTitle("One-Minute Changes")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: Setup

    private var setup: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Tap once for every clean change between the two chords. Beat your changes-per-minute.")
                    .font(Theme.rounded(16, .regular)).foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center).padding(.horizontal, 28).padding(.top, 16)

                HStack(spacing: 14) {
                    chordPicker("From", $chordAID)
                    Image(systemName: "arrow.left.arrow.right").foregroundStyle(Theme.accent)
                    chordPicker("To", $chordBID)
                }
                .padding(.horizontal, 16)

                HStack(spacing: 14) {
                    ChordMiniCard(chord: chordA)
                    ChordMiniCard(chord: chordB)
                }
                .padding(.horizontal, 16)

                Card {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Round length").font(Theme.rounded(14, .semibold)).foregroundStyle(Theme.inkSoft)
                        Picker("Round length", selection: $duration) {
                            Text("30s").tag(30); Text("60s").tag(60); Text("90s").tag(90)
                        }.pickerStyle(.segmented)
                    }
                }
                .padding(.horizontal, 16)

                Button {
                    let model = ChangesViewModel(chordA: chordA, chordB: chordB, durationSeconds: duration)
                    model.start(); vm = model; savedCPM = nil
                } label: {
                    Label("Start round", systemImage: "play.fill")
                        .font(Theme.rounded(18, .bold)).frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 16).padding(.bottom, 28)
            }
        }
    }

    private func chordPicker(_ label: String, _ binding: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(Theme.rounded(13, .semibold)).foregroundStyle(Theme.inkSoft)
            Picker(label, selection: binding) {
                ForEach(ChordLibrary.all) { Text($0.symbol).tag($0.id) }
            }
            .pickerStyle(.menu).tint(Theme.accent)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12).padding(.vertical, 10)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.hairline, lineWidth: 1))
        }
    }

    // MARK: Running / done

    private func running(_ vm: ChangesViewModel) -> some View {
        VStack(spacing: 18) {
            if vm.phase == .done {
                doneView(vm)
            } else {
                Text(timeString(vm.remaining))
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .monospacedDigit().foregroundStyle(Theme.ink).padding(.top, 12)
                    .contentTransition(.numericText())

                HStack(spacing: 10) {
                    chordCue(vm.chordA, active: !vm.onA)
                    chordCue(vm.chordB, active: vm.onA)
                }
                .padding(.horizontal, 24)

                Text("\(vm.changes) changes · \(vm.cpm) CPM")
                    .font(Theme.rounded(17, .semibold)).foregroundStyle(Theme.inkSoft)

                Spacer()

                Button { vm.tapChange() } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "hand.tap.fill").font(.system(size: 44))
                        Text("Tap on each change").font(Theme.rounded(17, .bold))
                    }
                    .frame(maxWidth: .infinity).frame(height: 220)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .foregroundStyle(.white)
                    .scaleEffect(reduceMotion ? 1 : (vm.onA ? 1 : 0.98))
                    .animation(reduceMotion ? nil : .spring(duration: 0.18), value: vm.changes)
                }
                .padding(.horizontal, 16)
                .accessibilityLabel("Tap to count a chord change. \(vm.changes) so far")

                Button("Stop early") { vm.finish() }
                    .font(Theme.rounded(15, .medium)).foregroundStyle(Theme.inkSoft).padding(.bottom, 16)
            }
        }
    }

    private func chordCue(_ chord: Chord, active: Bool) -> some View {
        Text(chord.symbol)
            .font(Theme.serif(28, .bold))
            .foregroundStyle(active ? .white : Theme.inkSoft)
            .frame(maxWidth: .infinity).padding(.vertical, 16)
            .background(active ? Theme.accent : Theme.surfaceAlt,
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func doneView(_ vm: ChangesViewModel) -> some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "checkmark.seal.fill").font(.system(size: 64))
                .foregroundStyle(Theme.accent).accessibilityHidden(true)
            Text("\(vm.cpm)").font(.system(size: 72, weight: .bold, design: .rounded)).foregroundStyle(Theme.ink)
            Text("changes per minute").font(Theme.rounded(17, .medium)).foregroundStyle(Theme.inkSoft)
            Text("\(vm.changes) clean changes between \(vm.chordA.symbol) and \(vm.chordB.symbol)")
                .font(Theme.rounded(15, .regular)).foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center).padding(.horizontal, 28)
            if let savedCPM { Pill(text: "Saved · \(savedCPM) CPM", color: Theme.good) }
            Spacer()
            VStack(spacing: 12) {
                Button {
                    let model = ChangesViewModel(chordA: chordA, chordB: chordB, durationSeconds: duration)
                    model.start(); self.vm = model; savedCPM = nil
                } label: {
                    Text("Go again").font(Theme.rounded(18, .bold)).frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .foregroundStyle(.white)
                }
                Button("Done") { self.vm = nil }
                    .font(Theme.rounded(16, .medium)).foregroundStyle(Theme.inkSoft)
            }
            .padding(.horizontal, 16).padding(.bottom, 28)
        }
        .onAppear { if savedCPM == nil { savedCPM = vm.save(to: context) } }
    }

    private func timeString(_ s: Int) -> String {
        String(format: "%d:%02d", s / 60, s % 60)
    }
}

private struct ChordMiniCard: View {
    let chord: Chord
    var body: some View {
        VStack(spacing: 4) {
            Text(chord.symbol).font(Theme.serif(16, .bold)).foregroundStyle(Theme.ink)
            ChordDiagram(chord: chord, showFingers: false).frame(height: 90)
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline, lineWidth: 1))
    }
}

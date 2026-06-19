import SwiftUI

struct FreePianoView: View {
    @State private var engine = PianoEngine()
    @State private var lastPlayedNote: Int? = nil
    @State private var showLabels = true
    @Query private var settingsQuery: [UserSettings]

    private var settings: UserSettings? { settingsQuery.first }

    var body: some View {
        NavigationStack {
            ZStack {
                KeysTheme.pianoBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Note display area
                    VStack(spacing: 12) {
                        if let note = lastPlayedNote {
                            VStack(spacing: 4) {
                                Text(PianoEngine.noteName(note))
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                Text("MIDI \(note)")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                            .transition(.scale.combined(with: .opacity))
                        } else {
                            VStack(spacing: 8) {
                                Image(systemName: "pianokeys")
                                    .font(.system(size: 36))
                                    .foregroundStyle(.white.opacity(0.3))
                                Text("Tap any key to play")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.4))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 160)
                    .animation(.spring(response: 0.25), value: lastPlayedNote)

                    Spacer()

                    // Keyboard
                    VStack(spacing: 0) {
                        PianoKeyboardView(
                            startMidi: 36,
                            endMidi: 96,
                            highlightedNotes: [],
                            correctNotes: [],
                            showLabels: settings?.showNoteLabels ?? true
                        ) { midi in
                            withAnimation(.spring(response: 0.2)) {
                                lastPlayedNote = midi
                            }
                            if settings?.soundEnabled ?? true {
                                engine.playNote(midi)
                            }
                            if settings?.hapticsEnabled ?? true {
                                let impact = UIImpactFeedbackGenerator(style: .light)
                                impact.impactOccurred()
                            }
                        }
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Piano")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showLabels.toggle()
                    } label: {
                        Image(systemName: showLabels ? "textformat.abc" : "textformat.abc.dottedunderline")
                            .foregroundStyle(.white)
                    }
                    .accessibilityLabel(showLabels ? "Hide note labels" : "Show note labels")
                }
            }
        }
    }
}

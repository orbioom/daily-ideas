import SwiftUI

/// How the user answers a note: an on-screen piano octave or note-name buttons.
enum AnswerStyle: String, CaseIterable, Identifiable {
    case piano
    case letters
    var id: String { rawValue }

    var label: String {
        switch self {
        case .piano: return "Piano keys"
        case .letters: return "Note buttons"
        }
    }

    var symbol: String {
        switch self {
        case .piano: return "pianokeys"
        case .letters: return "a.square"
        }
    }
}

/// Letter style for note names: C D E… or solfège Do Re Mi.
enum NoteNameStyle: String, CaseIterable, Identifiable {
    case letters
    case solfege
    var id: String { rawValue }

    var label: String {
        switch self {
        case .letters: return "Letters (C D E)"
        case .solfege: return "Solfège (Do Re Mi)"
        }
    }

    var useSolfege: Bool { self == .solfege }
}

/// Persisted user preferences that actually change behavior.
@MainActor
final class AppSettings: ObservableObject {
    @AppStorage("hapticsEnabled") var hapticsEnabled: Bool = true
    @AppStorage("soundEnabled") var soundEnabled: Bool = false
    @AppStorage("showKeyLabels") var showKeyLabels: Bool = true
    @AppStorage("useFlats") var useFlats: Bool = false
    @AppStorage("defaultClefRaw") var defaultClefRaw: String = Clef.treble.rawValue
    @AppStorage("answerStyleRaw") var answerStyleRaw: String = AnswerStyle.letters.rawValue
    @AppStorage("noteNameStyleRaw") var noteNameStyleRaw: String = NoteNameStyle.letters.rawValue

    var defaultClef: Clef {
        get { Clef(rawValue: defaultClefRaw) ?? .treble }
        set { defaultClefRaw = newValue.rawValue }
    }

    var answerStyle: AnswerStyle {
        get { AnswerStyle(rawValue: answerStyleRaw) ?? .letters }
        set { answerStyleRaw = newValue.rawValue }
    }

    var noteNameStyle: NoteNameStyle {
        get { NoteNameStyle(rawValue: noteNameStyleRaw) ?? .letters }
        set { noteNameStyleRaw = newValue.rawValue }
    }
}

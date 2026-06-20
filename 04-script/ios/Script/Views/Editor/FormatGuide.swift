import SwiftUI

struct FormatGuide: View {
    @Binding var content: String

    private let elements: [(label: String, insertion: String, tip: String)] = [
        ("INT./EXT.", "INT.  - DAY\n\n", "Scene heading"),
        ("ACTION", "\n", "Action line"),
        ("CHARACTER", "\nCHARACTER NAME\n", "Character cue"),
        ("DIALOGUE", "Dialogue text here.\n", "Dialogue"),
        ("(PAREN)", "(beat)\n", "Parenthetical"),
        ("CUT TO:", "\nCUT TO:\n\n", "Transition"),
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(elements, id: \.label) { item in
                    Button {
                        content += item.insertion
                    } label: {
                        Text(item.label)
                            .font(.system(.caption, design: .monospaced))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color(.secondarySystemBackground), in: Capsule())
                    }
                    .accessibilityLabel(item.tip)
                }
            }
        }
    }
}

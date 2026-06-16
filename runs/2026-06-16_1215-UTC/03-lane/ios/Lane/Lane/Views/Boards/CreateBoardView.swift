import SwiftUI

struct CreateBoardView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    /// (name, colorHex, symbolName, template)
    let onCreate: (String, Int, String, BoardTemplate) -> Void

    @State private var name = ""
    @State private var color = Palette.boardColors.first ?? 0x2D7FF9
    @State private var symbol = Palette.boardSymbols.first ?? "square.stack.3d.up.fill"
    @State private var template: BoardTemplate

    init(onCreate: @escaping (String, Int, String, BoardTemplate) -> Void) {
        self.onCreate = onCreate
        // Default template comes from settings; initialized in onAppear too for safety.
        _template = State(initialValue: .todoDoingDone)
    }

    private let symbolColumns = [GridItem(.adaptive(minimum: 52), spacing: 10)]
    private let colorColumns = [GridItem(.adaptive(minimum: 44), spacing: 10)]

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Product Launch", text: $name)
                        .font(.body)
                        .submitLabel(.done)
                }

                Section("Starter template") {
                    ForEach(BoardTemplate.allCases) { t in
                        Button {
                            template = t
                            Haptics.selection(enabled: settings.hapticsEnabled)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: t.symbol)
                                    .frame(width: 26)
                                    .foregroundStyle(Theme.accent)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(t.title)
                                        .font(Theme.rounded(15, .semibold))
                                        .foregroundStyle(Theme.ink)
                                    Text(t.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(Theme.inkSoft)
                                }
                                Spacer()
                                if template == t {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Theme.accent)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityElement(children: .combine)
                        .accessibilityAddTraits(template == t ? [.isSelected] : [])
                    }
                }

                Section("Color") {
                    LazyVGrid(columns: colorColumns, spacing: 10) {
                        ForEach(Palette.boardColors, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: UInt(hex)))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle().stroke(Theme.ink, lineWidth: color == hex ? 3 : 0)
                                )
                                .onTapGesture {
                                    color = hex
                                    Haptics.selection(enabled: settings.hapticsEnabled)
                                }
                                .accessibilityLabel("Color option")
                                .accessibilityAddTraits(color == hex ? [.isSelected] : [])
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Icon") {
                    LazyVGrid(columns: symbolColumns, spacing: 10) {
                        ForEach(Palette.boardSymbols, id: \.self) { sym in
                            Image(systemName: sym)
                                .font(.system(size: 20))
                                .frame(width: 48, height: 48)
                                .foregroundStyle(symbol == sym ? .white : Theme.ink)
                                .background(
                                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                                        .fill(symbol == sym ? Theme.accent : Theme.surfaceAlt)
                                )
                                .onTapGesture {
                                    symbol = sym
                                    Haptics.selection(enabled: settings.hapticsEnabled)
                                }
                                .accessibilityLabel("Icon option")
                                .accessibilityAddTraits(symbol == sym ? [.isSelected] : [])
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("New Board")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onCreate(name, color, symbol, template)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                template = settings.defaultTemplate
            }
        }
    }
}

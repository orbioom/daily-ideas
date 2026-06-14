import SwiftUI

/// A grouped gallery to pick an SF Symbol or emoji for an event.
struct SymbolPickerView: View {
    @Binding var selected: String
    let theme: CardTheme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 5)

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    ForEach(SymbolLibrary.groups) { group in
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: group.name)
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(group.symbols, id: \.self) { sym in
                                    cell(sym)
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Choose a Symbol")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
        }
    }

    private func cell(_ sym: String) -> some View {
        let isSelected = selected == sym
        return Button {
            Haptics.selection(enabled: settings.hapticsEnabled)
            selected = sym
            dismiss()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? AnyShapeStyle(theme.gradient) : AnyShapeStyle(Theme.surface))
                    .frame(height: 54)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(isSelected ? Color.clear : Theme.hairline, lineWidth: 1)
                    )
                EventSymbolView(symbol: sym, isEmoji: isEmoji(sym),
                                size: 24, color: isSelected ? theme.onGradient : Theme.ink)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(sym)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private func isEmoji(_ s: String) -> Bool {
        guard let scalar = s.unicodeScalars.first else { return false }
        return scalar.properties.isEmoji && scalar.value > 0x238C
    }
}

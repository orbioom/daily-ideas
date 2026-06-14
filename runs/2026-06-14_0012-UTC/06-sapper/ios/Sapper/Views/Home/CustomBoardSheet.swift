import SwiftUI

/// Editor for a custom board with live validation. Pro feature; the parent gates
/// actually starting the game behind `isPro`.
struct CustomBoardSheet: View {
    @Binding var config: BoardConfig
    @Environment(\.dismiss) private var dismiss

    @State private var rows: Double
    @State private var cols: Double
    @State private var mines: Double

    init(config: Binding<BoardConfig>) {
        self._config = config
        _rows = State(initialValue: Double(config.wrappedValue.rows))
        _cols = State(initialValue: Double(config.wrappedValue.cols))
        _mines = State(initialValue: Double(config.wrappedValue.mines))
    }

    private var rowsI: Int { Int(rows.rounded()) }
    private var colsI: Int { Int(cols.rounded()) }
    private var minesI: Int { Int(mines.rounded()) }

    private var maxMines: Int { max(1, rowsI * colsI - 9) }

    private var validationError: String? {
        BoardConfig.validationError(rows: rowsI, cols: colsI, mines: min(minesI, maxMines))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    boardPreview
                    sliderRow(title: "Rows", value: $rows,
                              range: Double(BoardConfig.minDim)...Double(BoardConfig.maxRows),
                              display: "\(rowsI)")
                    sliderRow(title: "Columns", value: $cols,
                              range: Double(BoardConfig.minDim)...Double(BoardConfig.maxCols),
                              display: "\(colsI)")
                    sliderRow(title: "Mines", value: $mines,
                              range: 1...Double(maxMines),
                              display: "\(min(minesI, maxMines))")

                    densityNote

                    if let validationError {
                        Label(validationError, systemImage: "exclamationmark.triangle.fill")
                            .font(Theme.rounded(13, .medium))
                            .foregroundStyle(Theme.bad)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    PrimaryButton(title: "Save board", systemImage: "checkmark") {
                        save()
                    }
                    .disabled(validationError != nil)
                    .opacity(validationError != nil ? 0.5 : 1)
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Custom board")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onChange(of: rows) { _, _ in clampMines() }
            .onChange(of: cols) { _, _ in clampMines() }
        }
    }

    private var boardPreview: some View {
        VStack(spacing: 6) {
            Text("\(rowsI) × \(colsI)")
                .font(Theme.rounded(30, .bold))
                .foregroundStyle(Theme.ink)
            Text("\(min(minesI, maxMines)) mines · \(rowsI * colsI) cells")
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private func sliderRow(title: String, value: Binding<Double>,
                           range: ClosedRange<Double>, display: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text(display)
                    .font(Theme.mono(15, .semibold))
                    .foregroundStyle(Theme.accent)
            }
            Slider(value: value, in: range, step: 1)
                .tint(Theme.accent)
                .accessibilityValue(display)
        }
    }

    private var densityNote: some View {
        let density = rowsI * colsI > 0 ? Double(min(minesI, maxMines)) / Double(rowsI * colsI) : 0
        let pct = Int((density * 100).rounded())
        return HStack {
            Image(systemName: "speedometer")
            Text("Mine density \(pct)%")
            Spacer()
            Text(densityLabel(density))
                .foregroundStyle(Theme.accent)
        }
        .font(Theme.rounded(13, .medium))
        .foregroundStyle(Theme.inkSoft)
    }

    private func densityLabel(_ d: Double) -> String {
        switch d {
        case ..<0.12: return "Gentle"
        case ..<0.18: return "Classic"
        case ..<0.23: return "Tough"
        default: return "Brutal"
        }
    }

    private func clampMines() {
        if minesI > maxMines { mines = Double(maxMines) }
    }

    private func save() {
        config = BoardConfig(rows: rowsI, cols: colsI, mines: min(minesI, maxMines))
        dismiss()
    }
}

#Preview {
    CustomBoardSheet(config: .constant(BoardConfig(rows: 12, cols: 12, mines: 24)))
}

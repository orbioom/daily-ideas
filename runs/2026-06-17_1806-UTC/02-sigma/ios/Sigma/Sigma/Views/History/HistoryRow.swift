import SwiftUI

/// A single tape row showing an expression, its result and timestamp.
/// Tap inserts the result; the context menu also offers inserting the expression.
struct HistoryRow: View {
    let entry: CalcEntry
    let onInsertResult: (String) -> Void
    let onInsertExpression: (String) -> Void

    var body: some View {
        Button {
            onInsertResult(entry.result)
        } label: {
            VStack(alignment: .trailing, spacing: 4) {
                Text(entry.expression)
                    .font(Theme.rounded(15))
                    .foregroundStyle(Theme.inkSoft)
                    .lineLimit(1)
                    .truncationMode(.head)
                Text("= \(entry.result)")
                    .font(Theme.rounded(24, .semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(entry.timestamp, format: .dateTime.month().day().hour().minute())
                    .font(Theme.rounded(11))
                    .foregroundStyle(Theme.inkFaint)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                onInsertResult(entry.result)
            } label: {
                Label("Insert result", systemImage: "equal.circle")
            }
            Button {
                onInsertExpression(entry.expression)
            } label: {
                Label("Insert expression", systemImage: "function")
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(entry.expression) equals \(entry.result)")
        .accessibilityHint("Double tap to insert the result into the calculator")
    }
}

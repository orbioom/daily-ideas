import SwiftUI
import SwiftData

/// The live calculator state shared across tabs (so History can push values back in).
/// Uses Observation (`@Observable`) and is owned by `RootView` via `@State`.
@Observable
@MainActor
final class CalculatorModel {
    /// The raw expression the user is building (uses calculator glyphs × ÷ −).
    var expression = ""
    /// The most recent evaluated result, or nil before any evaluation.
    var liveResult: String = ""
    /// Set when the last evaluation produced an error.
    var hasError = false
    /// The active angle unit for trig (initialised from settings default).
    var angle: AngleUnit = .degrees
    /// Toggled "2nd"/shift state exposing inverse trig functions.
    var shifted = false

    private var evaluator = ExpressionEvaluator()

    /// Whether the expression is non-empty (used to enable evaluate/backspace).
    var isEmpty: Bool { expression.isEmpty }

    // MARK: Live preview

    /// Recomputes a live result preview (no history side-effects).
    func refreshPreview(places: Int?, grouping: Bool, highPrecision: Bool) {
        guard !expression.isEmpty else {
            liveResult = ""
            hasError = false
            return
        }
        evaluator.angle = angle
        switch evaluator.evaluate(normalized(expression)) {
        case .value(let v):
            hasError = false
            liveResult = NumberFormatting.string(v, grouping: grouping, places: places, highPrecision: highPrecision)
        case .failure:
            // While typing an incomplete expression we simply show no preview.
            hasError = false
            liveResult = ""
        }
    }

    // MARK: Input

    func append(_ token: String) {
        expression += token
    }

    func appendDigit(_ digit: String) {
        expression += digit
    }

    func appendFunction(_ funcName: String) {
        expression += funcName + "("
    }

    func backspace() {
        guard !expression.isEmpty else { return }
        expression.removeLast()
    }

    func clear() {
        expression = ""
        liveResult = ""
        hasError = false
    }

    func toggleSign() {
        // Wrap the whole current expression in a unary minus toggle.
        if expression.hasPrefix("-(") && expression.hasSuffix(")") {
            expression = String(expression.dropFirst(2).dropLast())
        } else if !expression.isEmpty {
            expression = "-(" + expression + ")"
        }
    }

    func insertResult(_ value: String) {
        // Strip grouping separators so it re-parses cleanly.
        expression += value.replacingOccurrences(of: ",", with: "")
    }

    func insertExpression(_ expr: String) {
        expression = expr
    }

    // MARK: Evaluation (with history persistence)

    /// Evaluates the current expression. On success, returns the formatted result and
    /// the normalized expression so the caller can persist it; on error, sets `hasError`.
    @discardableResult
    func evaluate(places: Int?, grouping: Bool, highPrecision: Bool) -> (expression: String, result: String)? {
        guard !expression.isEmpty else { return nil }
        evaluator.angle = angle
        let displayExpression = expression
        switch evaluator.evaluate(normalized(expression)) {
        case .value(let v):
            let formatted = NumberFormatting.string(v, grouping: grouping, places: places, highPrecision: highPrecision)
            hasError = false
            liveResult = formatted
            // Replace the input with the result, ready for chaining.
            expression = formatted.replacingOccurrences(of: ",", with: "")
            return (displayExpression, formatted)
        case .failure(let message):
            hasError = true
            liveResult = message
            return nil
        }
    }

    // MARK: Normalization

    /// Translates calculator glyphs into the evaluator's accepted ASCII operators.
    private func normalized(_ s: String) -> String {
        s.replacingOccurrences(of: ",", with: "")
         .replacingOccurrences(of: "×", with: "*")
         .replacingOccurrences(of: "÷", with: "/")
         .replacingOccurrences(of: "−", with: "-")
         .replacingOccurrences(of: "π", with: "pi")
    }
}

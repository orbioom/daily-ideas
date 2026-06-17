import Foundation

/// The angular unit used when evaluating trigonometric functions.
enum AngleUnit: String, CaseIterable, Identifiable {
    case degrees = "DEG", radians = "RAD"
    var id: String { rawValue }
}

/// The outcome of evaluating an expression.
enum EvalResult: Equatable {
    case value(Double)
    case failure(String)
}

/// A real recursive expression evaluator: tokenizer → shunting-yard (to RPN) → RPN evaluation.
/// Supports + - × ÷, unary minus, parentheses, %, ^, functions and constants, honoring DEG/RAD.
/// Uses `Double` (correct for a calculator). Never force-unwraps; every stack pop is guarded;
/// division and modulo are guarded against zero.
struct ExpressionEvaluator {
    var angle: AngleUnit = .degrees

    // MARK: Token model

    private enum Token: Equatable {
        case number(Double)
        case constant(String)
        case op(String)      // + - * / ^ % and unary "u-"
        case function(String)
        case leftParen
        case rightParen
    }

    private static let functions: Set<String> = [
        "sin", "cos", "tan", "asin", "acos", "atan",
        "ln", "log", "sqrt", "fact", "recip", "exp"
    ]

    // MARK: Public API

    func evaluate(_ raw: String) -> EvalResult {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return .failure("Empty") }

        guard let tokens = tokenize(trimmed) else {
            return .failure("Error")
        }
        guard let rpn = toRPN(tokens) else {
            return .failure("Error")
        }
        return evaluateRPN(rpn)
    }

    // MARK: Tokenizer

    private func tokenize(_ input: String) -> [Token]? {
        var tokens: [Token] = []
        let chars = Array(input)
        var i = 0

        func previousAllowsUnary() -> Bool {
            guard let last = tokens.last else { return true }
            switch last {
            case .op, .leftParen, .function: return true
            default: return false
            }
        }

        while i < chars.count {
            let c = chars[i]

            if c == " " { i += 1; continue }

            // Numbers (with optional decimals and grouping commas removed beforehand)
            if c.isNumber || c == "." {
                var numStr = ""
                var dotSeen = false
                while i < chars.count, chars[i].isNumber || chars[i] == "." {
                    if chars[i] == "." {
                        if dotSeen { return nil }
                        dotSeen = true
                    }
                    numStr.append(chars[i])
                    i += 1
                }
                guard let value = Double(numStr) else { return nil }
                tokens.append(.number(value))
                continue
            }

            // Identifiers: functions or constants
            if c.isLetter {
                var ident = ""
                while i < chars.count, chars[i].isLetter {
                    ident.append(chars[i])
                    i += 1
                }
                let lower = ident.lowercased()
                if Self.functions.contains(lower) {
                    tokens.append(.function(lower))
                } else if lower == "pi" || lower == "e" {
                    tokens.append(.constant(lower))
                } else {
                    return nil
                }
                continue
            }

            // Operators and symbols
            switch c {
            case "+":
                tokens.append(.op("+")); i += 1
            case "-", "−":
                tokens.append(.op(previousAllowsUnary() ? "u-" : "-")); i += 1
            case "*", "×":
                tokens.append(.op("*")); i += 1
            case "/", "÷":
                tokens.append(.op("/")); i += 1
            case "^":
                tokens.append(.op("^")); i += 1
            case "%":
                tokens.append(.op("%")); i += 1
            case "!":
                // Postfix factorial → rewrite as function application via a marker handled in RPN.
                tokens.append(.op("!")); i += 1
            case "π":
                tokens.append(.constant("pi")); i += 1
            case "(":
                tokens.append(.leftParen); i += 1
            case ")":
                tokens.append(.rightParen); i += 1
            default:
                return nil
            }
        }
        return tokens
    }

    // MARK: Operator metadata

    private func precedence(_ op: String) -> Int {
        switch op {
        case "+", "-": return 2
        case "*", "/", "%": return 3
        case "u-": return 4
        case "^": return 5
        case "!": return 6
        default: return 0
        }
    }

    private func isRightAssociative(_ op: String) -> Bool {
        op == "^" || op == "u-"
    }

    // MARK: Shunting-yard → RPN

    private func toRPN(_ tokens: [Token]) -> [Token]? {
        var output: [Token] = []
        var stack: [Token] = []

        for token in tokens {
            switch token {
            case .number, .constant:
                output.append(token)
            case .function:
                stack.append(token)
            case .op(let o1):
                while let top = stack.last {
                    if case .op(let o2) = top {
                        let higher = precedence(o2) > precedence(o1)
                        let equalLeft = precedence(o2) == precedence(o1) && !isRightAssociative(o1)
                        if higher || equalLeft {
                            output.append(top)
                            stack.removeLast()
                            continue
                        }
                    } else if case .function = top {
                        output.append(top)
                        stack.removeLast()
                        continue
                    }
                    break
                }
                stack.append(token)
            case .leftParen:
                stack.append(token)
            case .rightParen:
                var foundLeft = false
                while let top = stack.last {
                    if case .leftParen = top {
                        stack.removeLast()
                        foundLeft = true
                        break
                    }
                    output.append(top)
                    stack.removeLast()
                }
                guard foundLeft else { return nil }
                // Pop a function if it directly precedes the parenthesised group.
                if let top = stack.last, case .function = top {
                    output.append(top)
                    stack.removeLast()
                }
            }
        }

        while let top = stack.last {
            if case .leftParen = top { return nil }
            if case .rightParen = top { return nil }
            output.append(top)
            stack.removeLast()
        }
        return output
    }

    // MARK: RPN evaluation

    private func evaluateRPN(_ rpn: [Token]) -> EvalResult {
        var stack: [Double] = []

        func pop() -> Double? {
            guard let last = stack.last else { return nil }
            stack.removeLast()
            return last
        }

        for token in rpn {
            switch token {
            case .number(let v):
                stack.append(v)
            case .constant(let name):
                stack.append(name == "pi" ? Double.pi : M_E)
            case .op(let o):
                if o == "u-" {
                    guard let a = pop() else { return .failure("Error") }
                    stack.append(-a)
                } else if o == "!" {
                    guard let a = pop() else { return .failure("Error") }
                    switch factorial(a) {
                    case .value(let r): stack.append(r)
                    case .failure(let m): return .failure(m)
                    }
                } else {
                    guard let b = pop(), let a = pop() else { return .failure("Error") }
                    switch applyBinary(o, a, b) {
                    case .value(let r): stack.append(r)
                    case .failure(let m): return .failure(m)
                    }
                }
            case .function(let name):
                guard let a = pop() else { return .failure("Error") }
                switch applyFunction(name, a) {
                case .value(let r): stack.append(r)
                case .failure(let m): return .failure(m)
                }
            case .leftParen, .rightParen:
                return .failure("Error")
            }
        }

        guard stack.count == 1, let result = stack.first else { return .failure("Error") }
        guard result.isFinite else { return .failure("Error") }
        return .value(result)
    }

    // MARK: Operations

    private func applyBinary(_ op: String, _ a: Double, _ b: Double) -> EvalResult {
        switch op {
        case "+": return .value(a + b)
        case "-": return .value(a - b)
        case "*": return .value(a * b)
        case "/":
            guard b != 0 else { return .failure("Cannot divide by zero") }
            return .value(a / b)
        case "%":
            // Percent acts as modulo when between two operands.
            guard b != 0 else { return .failure("Cannot divide by zero") }
            return .value(a.truncatingRemainder(dividingBy: b))
        case "^":
            let r = pow(a, b)
            guard r.isFinite else { return .failure("Error") }
            return .value(r)
        default:
            return .failure("Error")
        }
    }

    private func applyFunction(_ name: String, _ x: Double) -> EvalResult {
        let radians = angle == .degrees ? x * Double.pi / 180 : x
        switch name {
        case "sin": return .value(sin(radians))
        case "cos": return .value(cos(radians))
        case "tan":
            let r = tan(radians)
            guard r.isFinite else { return .failure("Undefined") }
            return .value(r)
        case "asin":
            guard x >= -1 && x <= 1 else { return .failure("Domain error") }
            return .value(toAngle(asin(x)))
        case "acos":
            guard x >= -1 && x <= 1 else { return .failure("Domain error") }
            return .value(toAngle(acos(x)))
        case "atan":
            return .value(toAngle(atan(x)))
        case "ln":
            guard x > 0 else { return .failure("Domain error") }
            return .value(log(x))
        case "log":
            guard x > 0 else { return .failure("Domain error") }
            return .value(log10(x))
        case "sqrt":
            guard x >= 0 else { return .failure("Cannot root a negative") }
            return .value(sqrt(x))
        case "exp":
            let r = exp(x)
            guard r.isFinite else { return .failure("Error") }
            return .value(r)
        case "recip":
            guard x != 0 else { return .failure("Cannot divide by zero") }
            return .value(1 / x)
        case "fact":
            return factorial(x)
        default:
            return .failure("Error")
        }
    }

    /// Converts a radian result back into the active angle unit (for inverse trig).
    private func toAngle(_ radians: Double) -> Double {
        angle == .degrees ? radians * 180 / Double.pi : radians
    }

    private func factorial(_ x: Double) -> EvalResult {
        guard x >= 0 else { return .failure("Cannot factorial a negative") }
        guard x == x.rounded() else { return .failure("Whole numbers only") }
        guard x <= 170 else { return .failure("Too large") }
        var result = 1.0
        var n = 2.0
        while n <= x {
            result *= n
            n += 1
        }
        guard result.isFinite else { return .failure("Too large") }
        return .value(result)
    }
}

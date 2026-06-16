import SwiftUI

/// The four arithmetic operations Digit trains.
enum MathOp: String, CaseIterable, Identifiable, Codable {
    case add, sub, mul, div
    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .add: return "+"
        case .sub: return "−"
        case .mul: return "×"
        case .div: return "÷"
        }
    }

    var title: String {
        switch self {
        case .add: return "Addition"
        case .sub: return "Subtraction"
        case .mul: return "Multiplication"
        case .div: return "Division"
        }
    }

    var shortTitle: String {
        switch self {
        case .add: return "Add"
        case .sub: return "Subtract"
        case .mul: return "Multiply"
        case .div: return "Divide"
        }
    }

    var sfSymbol: String {
        switch self {
        case .add: return "plus"
        case .sub: return "minus"
        case .mul: return "multiply"
        case .div: return "divide"
        }
    }

    var color: Color {
        switch self {
        case .add: return Theme.opAdd
        case .sub: return Theme.opSub
        case .mul: return Theme.opMul
        case .div: return Theme.opDiv
        }
    }

    /// Operations available on the free tier.
    var isFree: Bool { self == .add || self == .sub }
}

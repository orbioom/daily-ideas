import SwiftUI

/// Sort options for the recipe browser.
enum RecipeSort: String, CaseIterable, Identifiable {
    case match = "Best match"
    case time = "Quickest"
    case name = "Name"
    case recent = "Recent"
    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .match: return "percent"
        case .time: return "clock"
        case .name: return "textformat"
        case .recent: return "calendar"
        }
    }
}

/// Persisted user preferences that actually change app behavior.
@MainActor
final class AppSettings: ObservableObject {
    /// When on, common staples (salt, oil, butter…) are treated as always on hand.
    @AppStorage("assumeStaples") var assumeStaples: Bool = true
    /// Default servings used when opening a recipe's scaler.
    @AppStorage("defaultServings") var defaultServings: Int = 2
    /// Hide optional ingredients across detail / matching displays.
    @AppStorage("hideOptional") var hideOptional: Bool = false
    /// A short measurement note shown on recipe detail (US / metric reminder).
    @AppStorage("measurementNote") var measurementNote: String = "US cups"
    /// Gate for all haptic feedback.
    @AppStorage("hapticsEnabled") var hapticsEnabled: Bool = true
    /// Default browser sort.
    @AppStorage("defaultRecipeSortRaw") var defaultRecipeSortRaw: String = RecipeSort.match.rawValue

    static let measurementOptions = ["US cups", "Metric (g/ml)", "Imperial (oz)"]

    var defaultRecipeSort: RecipeSort {
        get { RecipeSort(rawValue: defaultRecipeSortRaw) ?? .match }
        set { defaultRecipeSortRaw = newValue.rawValue }
    }

    /// Clamp servings to a friendly range.
    func clampedServings(_ value: Int) -> Int {
        min(max(value, 1), 24)
    }
}

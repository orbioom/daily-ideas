import Foundation

struct ProductAnalysis {
    let flaggedIngredients: [IngredientInfo]
    let beneficialIngredients: [IngredientInfo]
    let unknownIngredients: [String]
    let overallRating: Int
    let overallLabel: String
}

struct GlowEngine {

    // MARK: - Search

    static func search(query: String) -> [IngredientInfo] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            return IngredientDatabase.all
        }
        let lowercased = query.lowercased()
        return IngredientDatabase.all.filter { ingredient in
            ingredient.iciName.lowercased().contains(lowercased)
                || ingredient.id.contains(lowercased)
                || ingredient.commonNames.contains(where: { $0.lowercased().contains(lowercased) })
                || ingredient.category.rawValue.lowercased().contains(lowercased)
        }
    }

    // MARK: - Ingredient Lookup

    static func ingredient(for id: String) -> IngredientInfo? {
        let normalized = id.lowercased().trimmingCharacters(in: .whitespaces)
        return IngredientDatabase.all.first { $0.id == normalized }
    }

    // MARK: - Analyzer

    static func analyze(ingredientList: String) -> ProductAnalysis {
        let tokens = tokenize(ingredientList)
        var flagged: [IngredientInfo] = []
        var beneficial: [IngredientInfo] = []
        var unknown: [String] = []

        for token in tokens {
            if let match = matchIngredient(token) {
                if match.safetyRating >= 3 {
                    if !flagged.contains(where: { $0.id == match.id }) {
                        flagged.append(match)
                    }
                } else {
                    if !beneficial.contains(where: { $0.id == match.id }) {
                        beneficial.append(match)
                    }
                }
            } else {
                if !token.isEmpty && !unknown.contains(token) {
                    unknown.append(token)
                }
            }
        }

        let worstRating = flagged.map(\.safetyRating).max() ?? 1
        let overallRating: Int
        if flagged.isEmpty {
            overallRating = beneficial.isEmpty ? 1 : 1
        } else {
            overallRating = worstRating
        }

        return ProductAnalysis(
            flaggedIngredients: flagged,
            beneficialIngredients: beneficial,
            unknownIngredients: unknown,
            overallRating: overallRating,
            overallLabel: label(for: overallRating)
        )
    }

    // MARK: - Conflict Checker

    static func checkConflict(a: IngredientInfo, b: IngredientInfo) -> String? {
        let conflicts: [(Set<String>, String)] = [
            (["l-ascorbic-acid", "niacinamide"], "Vitamin C and Niacinamide may form niacin when combined at low pH, potentially causing temporary flushing. Use at different times of day."),
            (["l-ascorbic-acid", "ghk-cu"], "Vitamin C can deactivate copper peptides. Apply at different times of day."),
            (["retinol", "glycolic-acid"], "Retinol and AHAs (glycolic acid) together can cause significant irritation and over-exfoliation. Alternate nights."),
            (["retinol", "lactic-acid"], "Retinol and AHAs (lactic acid) together can cause irritation. Alternate nights."),
            (["retinol", "salicylic-acid"], "Retinol and BHA may cause excessive dryness and irritation. Avoid combining."),
            (["benzophenone-3", "l-ascorbic-acid"], "Oxybenzone combined with vitamin C may increase oxidative stress. Formulation concern."),
            (["sodium-benzoate", "l-ascorbic-acid"], "Sodium benzoate and ascorbic acid at low pH can form trace benzene. Formulation concern."),
            (["glycolic-acid", "salicylic-acid"], "Layering multiple acids (glycolic + salicylic) can cause over-exfoliation and barrier disruption, especially for sensitive skin."),
            (["methylisothiazolinone", "phenoxyethanol"], "Multiple preservatives are unnecessary and increase sensitization risk."),
            (["retinol", "bakuchiol"], "These are redundant in the same routine — bakuchiol is a retinol alternative. Using both provides no added benefit."),
        ]

        let pairIds = Set([a.id, b.id])
        for (conflictSet, message) in conflicts {
            if pairIds == conflictSet {
                return message
            }
        }
        return nil
    }

    // MARK: - Private Helpers

    private static func tokenize(_ raw: String) -> [String] {
        raw
            .components(separatedBy: CharacterSet(charactersIn: ","))
            .flatMap { $0.components(separatedBy: "/") }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
    }

    private static func matchIngredient(_ token: String) -> IngredientInfo? {
        // Exact ID match
        if let exact = IngredientDatabase.all.first(where: { $0.id == token }) {
            return exact
        }

        // Exact INCI name (case-insensitive)
        if let byName = IngredientDatabase.all.first(where: { $0.iciName.lowercased() == token }) {
            return byName
        }

        // Common name exact match
        if let byCommon = IngredientDatabase.all.first(where: {
            $0.commonNames.contains(where: { $0.lowercased() == token })
        }) {
            return byCommon
        }

        // Partial/fuzzy containment — INCI name contains token
        if let partial = IngredientDatabase.all.first(where: {
            $0.iciName.lowercased().contains(token) || token.contains($0.iciName.lowercased())
        }) {
            return partial
        }

        return nil
    }

    private static func label(for rating: Int) -> String {
        switch rating {
        case 1: return "Clean"
        case 2: return "Good"
        case 3: return "Moderate"
        case 4: return "Caution"
        case 5: return "Avoid"
        default: return "Unknown"
        }
    }
}

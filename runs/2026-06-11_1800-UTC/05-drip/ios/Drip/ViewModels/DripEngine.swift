import Foundation
import SwiftData

struct DripEngine {
    static func weekDrinks(entries: [DrinkEntry]) -> Double {
        let cal = Calendar.current
        let startOfWeek = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        return entries
            .filter { $0.date >= startOfWeek }
            .reduce(0) { $0 + $1.standardDrinks }
    }

    static func todayDrinks(entries: [DrinkEntry]) -> Double {
        let today = Calendar.current.startOfDay(for: Date())
        return entries
            .filter { Calendar.current.startOfDay(for: $0.date) == today }
            .reduce(0) { $0 + $1.standardDrinks }
    }

    static func alcoholFreeDaysThisWeek(entries: [DrinkEntry]) -> Int {
        let cal = Calendar.current
        let startOfWeek = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        var drinkingDays = Set<Date>()
        for e in entries where e.date >= startOfWeek {
            drinkingDays.insert(cal.startOfDay(for: e.date))
        }
        let today = cal.startOfDay(for: Date())
        let daysSoFar = max(1, cal.dateComponents([.day], from: startOfWeek, to: today).day.map { $0 + 1 } ?? 1)
        return max(0, daysSoFar - drinkingDays.count)
    }

    static func moneySavedThisWeek(entries: [DrinkEntry], goal: DrinkGoal) -> Double {
        let weekDrinks = Self.weekDrinks(entries: entries)
        let limit = Double(goal.weeklyLimit)
        guard weekDrinks < limit else { return 0 }
        return (limit - weekDrinks) * goal.costPerDrink
    }

    static func weeklyDrinksByDay(entries: [DrinkEntry]) -> [(day: String, drinks: Double)] {
        let cal = Calendar.current
        let startOfWeek = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        let daySymbols = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return (0..<7).map { offset in
            let day = cal.date(byAdding: .day, value: offset, to: startOfWeek) ?? startOfWeek
            let drinks = entries
                .filter { cal.startOfDay(for: $0.date) == cal.startOfDay(for: day) }
                .reduce(0) { $0 + $1.standardDrinks }
            let weekday = cal.component(.weekday, from: day) - 1
            return (day: daySymbols[weekday], drinks: drinks)
        }
    }

    static func contextBreakdown(entries: [DrinkEntry]) -> [(context: String, drinks: Double)] {
        var totals: [String: Double] = [:]
        for e in entries { totals[e.context.rawValue, default: 0] += e.standardDrinks }
        return totals.map { ($0.key, $0.value) }.sorted { $0.drinks > $1.drinks }
    }
}

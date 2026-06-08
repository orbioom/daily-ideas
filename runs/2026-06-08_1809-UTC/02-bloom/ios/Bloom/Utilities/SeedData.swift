import Foundation
import SwiftData

/// Adds a few sample logs the first time a pregnancy is created so the app's
/// charts and lists feel alive immediately.
enum SeedData {
    static func seedLogs(_ context: ModelContext, pregnancy: Pregnancy) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)

        // Weight trend (last 6 weeks), starting near pre-pregnancy weight.
        let base = pregnancy.prePregnancyWeightKg > 0 ? pregnancy.prePregnancyWeightKg : 64
        for w in stride(from: 6, through: 0, by: -1) {
            let day = cal.date(byAdding: .day, value: -w * 7, to: today) ?? today
            let kg = base + Double(6 - w) * 0.5
            context.insert(WeightEntry(date: day, kg: kg))
        }

        // A couple of symptoms.
        context.insert(SymptomEntry(date: cal.date(byAdding: .day, value: -1, to: today) ?? today,
                                    symptom: .fatigue, severity: 2))
        context.insert(SymptomEntry(date: today, symptom: .cravings, severity: 1, note: "Citrus, all day"))

        // Upcoming appointment.
        let next = cal.date(byAdding: .day, value: 9, to: today) ?? today
        context.insert(Appointment(date: cal.date(bySettingHour: 10, minute: 30, second: 0, of: next) ?? next,
                                   title: "Routine checkup",
                                   location: "Maternity clinic"))
        try? context.save()
    }
}

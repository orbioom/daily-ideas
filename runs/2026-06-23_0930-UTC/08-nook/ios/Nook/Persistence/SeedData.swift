import Foundation
import SwiftData

/// Seeds a realistic starter home: rooms, equipment with warranties, and a
/// homeowner maintenance checklist (60+ tasks) with staggered due dates and
/// some completion history. Runs once, gated by AppSettings existence.
enum SeedData {

    struct TaskTemplate {
        let title: String
        let detail: String
        let recurrence: Recurrence
        let minutes: Int
        let offsetDays: Int          // due date relative to today
        let roomKind: RoomKind
        let applianceKind: ApplianceKind?
        let completedCount: Int      // synthetic history entries
        let typicalCost: Double
    }

    static func seedIfNeeded(context: ModelContext) {
        let existing = try? context.fetch(FetchDescriptor<AppSettings>())
        if let existing, !existing.isEmpty { return }

        // Settings row
        let settings = AppSettings()
        context.insert(settings)

        let today = Calendar.current.startOfDay(for: .now)

        // Rooms
        var roomByKind: [RoomKind: Room] = [:]
        let roomSpecs: [(RoomKind, String)] = [
            (.kitchen, "Kitchen"),
            (.bathroom, "Main Bathroom"),
            (.livingRoom, "Living Room"),
            (.bedroom, "Primary Bedroom"),
            (.laundry, "Laundry Room"),
            (.garage, "Garage"),
            (.basement, "Basement"),
            (.exterior, "Exterior"),
            (.yard, "Yard & Garden"),
            (.wholeHome, "Whole Home")
        ]
        for (kind, name) in roomSpecs {
            let r = Room(name: name, kind: kind)
            context.insert(r)
            roomByKind[kind] = r
        }

        // Appliances / equipment with warranties
        let applianceSpecs: [(ApplianceKind, String, String, String, RoomKind, Int, Int)] = [
            // kind, name, brand, model, room, monthsAgoPurchased, warrantyMonths
            (.hvac, "Central AC Unit", "Carrier", "24ACC636A003", .exterior, 30, 120),
            (.furnace, "Gas Furnace", "Lennox", "ML193UH070XP36B", .basement, 30, 240),
            (.waterHeater, "Water Heater", "Rheem", "XE50T10H45U0", .basement, 18, 144),
            (.refrigerator, "Refrigerator", "LG", "LRFVS3006S", .kitchen, 14, 12),
            (.dishwasher, "Dishwasher", "Bosch", "SHEM63W55N", .kitchen, 26, 24),
            (.oven, "Range / Oven", "GE", "JGB735SPSS", .kitchen, 26, 12),
            (.washer, "Washing Machine", "Samsung", "WF45T6000AW", .laundry, 8, 12),
            (.dryer, "Dryer", "Samsung", "DVE45T6000W", .laundry, 8, 12),
            (.sumpPump, "Sump Pump", "Zoeller", "M53", .basement, 40, 36),
            (.garageDoor, "Garage Door Opener", "Chamberlain", "B970", .garage, 22, 60),
            (.waterSoftener, "Water Softener", "Whirlpool", "WHES40E", .basement, 50, 12),
            (.smokeDetector, "Smoke / CO Detectors", "First Alert", "SCO5CN", .wholeHome, 36, 120)
        ]
        var applianceByKind: [ApplianceKind: Appliance] = [:]
        let cal = Calendar.current
        for (kind, name, brand, model, roomKind, monthsAgo, warranty) in applianceSpecs {
            let purchase = cal.date(byAdding: .month, value: -monthsAgo, to: today)
            let a = Appliance(name: name,
                              kind: kind,
                              brand: brand,
                              modelNumber: model,
                              serialNumber: "SN-\(Int.random(in: 100000...999999))",
                              purchaseDate: purchase,
                              warrantyMonths: warranty,
                              room: roomByKind[roomKind])
            context.insert(a)
            applianceByKind[kind] = a
        }

        // Maintenance task templates — staggered so the Due tab has real content.
        let templates: [TaskTemplate] = [
            .init(title: "Replace HVAC air filter", detail: "Swap the furnace/AC return filter. Check size before buying.", recurrence: .monthly, minutes: 10, offsetDays: -6, roomKind: .basement, applianceKind: .hvac, completedCount: 5, typicalCost: 18),
            .init(title: "Test smoke & CO detectors", detail: "Press test button on every detector; listen for the alarm.", recurrence: .monthly, minutes: 15, offsetDays: -2, roomKind: .wholeHome, applianceKind: .smokeDetector, completedCount: 4, typicalCost: 0),
            .init(title: "Run garbage disposal cleaner", detail: "Grind ice + citrus peel, then flush with cold water.", recurrence: .monthly, minutes: 10, offsetDays: 3, roomKind: .kitchen, applianceKind: nil, completedCount: 3, typicalCost: 4),
            .init(title: "Clean range hood filter", detail: "Soak metal mesh filter in hot soapy water.", recurrence: .monthly, minutes: 20, offsetDays: 8, roomKind: .kitchen, applianceKind: .oven, completedCount: 2, typicalCost: 0),
            .init(title: "Wipe refrigerator coils", detail: "Vacuum the condenser coils behind/under the fridge.", recurrence: .quarterly, minutes: 20, offsetDays: 12, roomKind: .kitchen, applianceKind: .refrigerator, completedCount: 1, typicalCost: 0),
            .init(title: "Replace fridge water filter", detail: "Swap the in-door water/ice filter cartridge.", recurrence: .quarterly, minutes: 10, offsetDays: -1, roomKind: .kitchen, applianceKind: .refrigerator, completedCount: 2, typicalCost: 42),
            .init(title: "Clean dishwasher filter", detail: "Remove and rinse the bottom filter; wipe the door gasket.", recurrence: .monthly, minutes: 15, offsetDays: 1, roomKind: .kitchen, applianceKind: .dishwasher, completedCount: 3, typicalCost: 0),
            .init(title: "Descale coffee maker", detail: "Run a vinegar or descaler cycle.", recurrence: .quarterly, minutes: 25, offsetDays: 20, roomKind: .kitchen, applianceKind: nil, completedCount: 1, typicalCost: 8),
            .init(title: "Clean dryer lint exhaust", detail: "Vacuum the lint trap housing and outdoor vent.", recurrence: .quarterly, minutes: 30, offsetDays: -4, roomKind: .laundry, applianceKind: .dryer, completedCount: 2, typicalCost: 0),
            .init(title: "Clean washer gasket & run tub clean", detail: "Wipe the door seal; run the washer's self-clean cycle.", recurrence: .monthly, minutes: 20, offsetDays: 5, roomKind: .laundry, applianceKind: .washer, completedCount: 3, typicalCost: 6),
            .init(title: "Check washer hoses", detail: "Inspect supply hoses for bulges or cracks.", recurrence: .annual, minutes: 15, offsetDays: 90, roomKind: .laundry, applianceKind: .washer, completedCount: 0, typicalCost: 0),
            .init(title: "Flush water heater", detail: "Drain a few gallons to clear sediment from the tank.", recurrence: .annual, minutes: 45, offsetDays: 35, roomKind: .basement, applianceKind: .waterHeater, completedCount: 1, typicalCost: 0),
            .init(title: "Test water heater T&P valve", detail: "Lift the relief valve lever briefly to confirm it releases.", recurrence: .annual, minutes: 10, offsetDays: 35, roomKind: .basement, applianceKind: .waterHeater, completedCount: 1, typicalCost: 0),
            .init(title: "Test sump pump", detail: "Pour a bucket of water into the pit; confirm it kicks on.", recurrence: .quarterly, minutes: 15, offsetDays: -3, roomKind: .basement, applianceKind: .sumpPump, completedCount: 2, typicalCost: 0),
            .init(title: "Replace water softener salt", detail: "Top off the brine tank with softener salt.", recurrence: .monthly, minutes: 15, offsetDays: 2, roomKind: .basement, applianceKind: .waterSoftener, completedCount: 4, typicalCost: 12),
            .init(title: "Schedule HVAC tune-up (cooling)", detail: "Book a pro to service the AC before summer.", recurrence: .annual, minutes: 90, offsetDays: -10, roomKind: .exterior, applianceKind: .hvac, completedCount: 1, typicalCost: 145),
            .init(title: "Schedule HVAC tune-up (heating)", detail: "Book a pro to service the furnace before winter.", recurrence: .annual, minutes: 90, offsetDays: 150, roomKind: .basement, applianceKind: .furnace, completedCount: 1, typicalCost: 145),
            .init(title: "Lubricate garage door", detail: "Spray hinges, rollers and springs; tighten loose bolts.", recurrence: .semiAnnual, minutes: 25, offsetDays: 18, roomKind: .garage, applianceKind: .garageDoor, completedCount: 1, typicalCost: 9),
            .init(title: "Test garage door auto-reverse", detail: "Place a 2x4 in the path; door must reverse on contact.", recurrence: .semiAnnual, minutes: 10, offsetDays: 18, roomKind: .garage, applianceKind: .garageDoor, completedCount: 1, typicalCost: 0),
            .init(title: "Clean gutters & downspouts", detail: "Clear leaves and debris; check for sagging.", recurrence: .seasonal, minutes: 90, offsetDays: -8, roomKind: .exterior, applianceKind: nil, completedCount: 2, typicalCost: 0),
            .init(title: "Inspect roof & flashing", detail: "Look for missing shingles and damaged flashing.", recurrence: .semiAnnual, minutes: 30, offsetDays: 25, roomKind: .exterior, applianceKind: nil, completedCount: 1, typicalCost: 0),
            .init(title: "Caulk windows & doors", detail: "Reseal gaps in exterior caulk to stop drafts.", recurrence: .annual, minutes: 60, offsetDays: 60, roomKind: .exterior, applianceKind: nil, completedCount: 0, typicalCost: 14),
            .init(title: "Power-wash siding & deck", detail: "Rinse off mildew and grime from siding and decking.", recurrence: .annual, minutes: 120, offsetDays: 40, roomKind: .exterior, applianceKind: nil, completedCount: 0, typicalCost: 0),
            .init(title: "Drain & winterize outdoor faucets", detail: "Shut off and drain hose bibs before the first freeze.", recurrence: .seasonal, minutes: 30, offsetDays: 120, roomKind: .exterior, applianceKind: nil, completedCount: 1, typicalCost: 0),
            .init(title: "Service the lawn mower", detail: "Change oil, replace spark plug, sharpen the blade.", recurrence: .seasonal, minutes: 45, offsetDays: 15, roomKind: .yard, applianceKind: nil, completedCount: 1, typicalCost: 22),
            .init(title: "Fertilize the lawn", detail: "Apply seasonal fertilizer appropriate to your grass.", recurrence: .seasonal, minutes: 40, offsetDays: 9, roomKind: .yard, applianceKind: nil, completedCount: 1, typicalCost: 38),
            .init(title: "Trim trees & shrubs", detail: "Cut back branches away from the house and power lines.", recurrence: .semiAnnual, minutes: 90, offsetDays: 30, roomKind: .yard, applianceKind: nil, completedCount: 1, typicalCost: 0),
            .init(title: "Check irrigation / sprinklers", detail: "Run each zone; fix clogged or misaligned heads.", recurrence: .seasonal, minutes: 30, offsetDays: 6, roomKind: .yard, applianceKind: nil, completedCount: 1, typicalCost: 0),
            .init(title: "Reseal grout in shower", detail: "Inspect tile grout; re-seal to prevent water damage.", recurrence: .annual, minutes: 60, offsetDays: 70, roomKind: .bathroom, applianceKind: nil, completedCount: 0, typicalCost: 16),
            .init(title: "Clean bathroom exhaust fan", detail: "Remove the cover and vacuum dust from the fan blades.", recurrence: .semiAnnual, minutes: 20, offsetDays: 22, roomKind: .bathroom, applianceKind: nil, completedCount: 1, typicalCost: 0),
            .init(title: "Check caulk around tub & sink", detail: "Re-caulk any cracked or moldy seams.", recurrence: .annual, minutes: 30, offsetDays: 80, roomKind: .bathroom, applianceKind: nil, completedCount: 0, typicalCost: 8),
            .init(title: "Vacuum & rotate mattress", detail: "Vacuum the mattress and rotate it head-to-foot.", recurrence: .quarterly, minutes: 15, offsetDays: 14, roomKind: .bedroom, applianceKind: nil, completedCount: 1, typicalCost: 0),
            .init(title: "Replace HVAC vent filters (bedrooms)", detail: "Swap any room-level return filters.", recurrence: .quarterly, minutes: 10, offsetDays: 11, roomKind: .bedroom, applianceKind: .hvac, completedCount: 1, typicalCost: 22),
            .init(title: "Dust ceiling fans", detail: "Wipe fan blades and reverse direction for the season.", recurrence: .quarterly, minutes: 15, offsetDays: 7, roomKind: .livingRoom, applianceKind: nil, completedCount: 1, typicalCost: 0),
            .init(title: "Vacuum HVAC supply registers", detail: "Remove vent covers and vacuum the ducts you can reach.", recurrence: .quarterly, minutes: 25, offsetDays: 13, roomKind: .livingRoom, applianceKind: .hvac, completedCount: 1, typicalCost: 0),
            .init(title: "Test GFCI outlets", detail: "Press TEST then RESET on kitchen/bath/garage GFCIs.", recurrence: .quarterly, minutes: 15, offsetDays: 4, roomKind: .wholeHome, applianceKind: nil, completedCount: 1, typicalCost: 0),
            .init(title: "Replace detector batteries", detail: "Swap 9V/AA batteries in smoke and CO detectors.", recurrence: .semiAnnual, minutes: 20, offsetDays: -5, roomKind: .wholeHome, applianceKind: .smokeDetector, completedCount: 1, typicalCost: 11),
            .init(title: "Check fire extinguisher gauge", detail: "Confirm the pressure needle is in the green zone.", recurrence: .annual, minutes: 5, offsetDays: 45, roomKind: .wholeHome, applianceKind: nil, completedCount: 0, typicalCost: 0),
            .init(title: "Deep-clean & inspect grout/seal stone counters", detail: "Reseal natural-stone countertops.", recurrence: .annual, minutes: 40, offsetDays: 100, roomKind: .kitchen, applianceKind: nil, completedCount: 0, typicalCost: 18),
            .init(title: "Vacuum dryer vent (deep)", detail: "Detach the duct and clean the full run to the exterior.", recurrence: .annual, minutes: 60, offsetDays: 55, roomKind: .laundry, applianceKind: .dryer, completedCount: 0, typicalCost: 0),
            .init(title: "Inspect attic for leaks & pests", detail: "Check for water stains, daylight, and droppings.", recurrence: .semiAnnual, minutes: 30, offsetDays: 65, roomKind: .wholeHome, applianceKind: nil, completedCount: 0, typicalCost: 0),
            .init(title: "Clean & test dehumidifier", detail: "Empty the reservoir and rinse the air filter.", recurrence: .monthly, minutes: 10, offsetDays: 0, roomKind: .basement, applianceKind: nil, completedCount: 3, typicalCost: 0),
            .init(title: "Inspect basement for moisture", detail: "Look for damp spots, efflorescence, or musty smells.", recurrence: .quarterly, minutes: 15, offsetDays: 16, roomKind: .basement, applianceKind: nil, completedCount: 1, typicalCost: 0),
            .init(title: "Test the doorbell & locks", detail: "Confirm the doorbell works and lubricate sticky locks.", recurrence: .annual, minutes: 15, offsetDays: 75, roomKind: .exterior, applianceKind: nil, completedCount: 0, typicalCost: 6),
            .init(title: "Clean window tracks & screens", detail: "Vacuum tracks; wash and re-hang window screens.", recurrence: .semiAnnual, minutes: 60, offsetDays: 28, roomKind: .wholeHome, applianceKind: nil, completedCount: 1, typicalCost: 0),
            .init(title: "Check & re-stock emergency kit", detail: "Verify flashlight, water, batteries and first-aid supplies.", recurrence: .annual, minutes: 20, offsetDays: 110, roomKind: .wholeHome, applianceKind: nil, completedCount: 0, typicalCost: 25),
            .init(title: "Drain garden hose & store", detail: "Disconnect, drain and coil hoses for storage.", recurrence: .seasonal, minutes: 15, offsetDays: 130, roomKind: .yard, applianceKind: nil, completedCount: 1, typicalCost: 0),
            .init(title: "Aerate the lawn", detail: "Core-aerate compacted areas to improve drainage.", recurrence: .annual, minutes: 60, offsetDays: 48, roomKind: .yard, applianceKind: nil, completedCount: 0, typicalCost: 30),
            .init(title: "Mulch garden beds", detail: "Refresh mulch to retain moisture and suppress weeds.", recurrence: .seasonal, minutes: 90, offsetDays: 21, roomKind: .yard, applianceKind: nil, completedCount: 1, typicalCost: 55),
            .init(title: "Service the generator", detail: "Run it under load; change oil and check the fuel.", recurrence: .semiAnnual, minutes: 45, offsetDays: 33, roomKind: .garage, applianceKind: nil, completedCount: 0, typicalCost: 28),
            .init(title: "Inspect deck boards & railings", detail: "Check for rot, popped nails, and loose railings.", recurrence: .annual, minutes: 30, offsetDays: 62, roomKind: .exterior, applianceKind: nil, completedCount: 0, typicalCost: 0),
            .init(title: "Clean oven & calibrate", detail: "Run the self-clean cycle and verify the temperature.", recurrence: .quarterly, minutes: 60, offsetDays: 10, roomKind: .kitchen, applianceKind: .oven, completedCount: 1, typicalCost: 0),
            .init(title: "Vacuum behind the dryer", detail: "Pull the dryer out and vacuum lint buildup behind it.", recurrence: .quarterly, minutes: 20, offsetDays: 17, roomKind: .laundry, applianceKind: .dryer, completedCount: 1, typicalCost: 0),
            .init(title: "Check exterior light fixtures", detail: "Replace burnt bulbs; clean lenses on porch/path lights.", recurrence: .semiAnnual, minutes: 20, offsetDays: 36, roomKind: .exterior, applianceKind: nil, completedCount: 0, typicalCost: 10),
            .init(title: "Inspect & clean grill", detail: "Scrub grates and empty the grease tray.", recurrence: .quarterly, minutes: 30, offsetDays: 19, roomKind: .yard, applianceKind: nil, completedCount: 1, typicalCost: 0),
            .init(title: "Replace whole-home humidifier pad", detail: "Swap the evaporator pad on the furnace humidifier.", recurrence: .annual, minutes: 20, offsetDays: 140, roomKind: .basement, applianceKind: .furnace, completedCount: 0, typicalCost: 19),
            .init(title: "Check toilet flappers & fill valves", detail: "Listen for running water; replace worn flappers.", recurrence: .annual, minutes: 20, offsetDays: 85, roomKind: .bathroom, applianceKind: nil, completedCount: 0, typicalCost: 12),
            .init(title: "Vacuum & wipe baseboards", detail: "Dust and wipe baseboards throughout the home.", recurrence: .quarterly, minutes: 45, offsetDays: 23, roomKind: .wholeHome, applianceKind: nil, completedCount: 1, typicalCost: 0),
            .init(title: "Inspect caulk & weatherstripping", detail: "Replace worn door sweeps and weatherstripping.", recurrence: .annual, minutes: 40, offsetDays: 95, roomKind: .wholeHome, applianceKind: nil, completedCount: 0, typicalCost: 18),
            .init(title: "Test backup battery / surge protectors", detail: "Check UPS batteries and surge-protector indicator lights.", recurrence: .annual, minutes: 15, offsetDays: 105, roomKind: .livingRoom, applianceKind: nil, completedCount: 0, typicalCost: 0)
        ]

        for tpl in templates {
            let due = cal.date(byAdding: .day, value: tpl.offsetDays, to: today) ?? today
            let task = MaintenanceTask(title: tpl.title,
                                       detail: tpl.detail,
                                       recurrence: tpl.recurrence,
                                       nextDue: due,
                                       estimatedMinutes: tpl.minutes,
                                       room: roomByKind[tpl.roomKind],
                                       appliance: tpl.applianceKind.flatMap { applianceByKind[$0] })
            context.insert(task)

            // Synthetic completion history walking backwards through cycles.
            var historyDate = cal.date(byAdding: .day, value: tpl.offsetDays, to: today) ?? today
            var last: Date? = nil
            for i in 0..<tpl.completedCount {
                if let prev = tpl.recurrence.nextDate(after: historyDate, calendar: cal) {
                    // step backwards: previous cycle is one interval before current
                    let interval = cal.dateComponents([.day], from: historyDate, to: prev).day ?? 30
                    historyDate = cal.date(byAdding: .day, value: -abs(interval), to: historyDate) ?? historyDate
                } else {
                    historyDate = cal.date(byAdding: .day, value: -30 * (i + 1), to: historyDate) ?? historyDate
                }
                let cost = tpl.typicalCost > 0 ? (tpl.typicalCost * Double.random(in: 0.85...1.15)) : 0
                let rec = ServiceRecord(completedDate: historyDate,
                                        cost: (cost * 100).rounded() / 100,
                                        note: "",
                                        vendor: "",
                                        task: task)
                context.insert(rec)
                if last == nil { last = historyDate }
            }
            task.lastCompleted = last
        }

        try? context.save()
    }
}

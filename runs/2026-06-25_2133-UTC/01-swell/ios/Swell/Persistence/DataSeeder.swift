import Foundation
import SwiftData

enum DataSeeder {
    static func seed(context: ModelContext) {
        let spots = seedSpots(context: context)
        let boards = seedBoards(context: context)
        seedSessions(context: context, spots: spots.map(\.name), boards: boards.map(\.name))
        try? context.save()
    }

    @discardableResult
    static func seedSpots(context: ModelContext) -> [SurfSpot] {
        let spotsData: [(String, BreakType, SpotDifficulty, String)] = [
            ("Malibu", .point, .intermediate, "Classic California point break. Long right-handers."),
            ("Trestles", .point, .advanced, "World-class point break in San Clemente. Multiple breaks."),
            ("Rincon", .point, .advanced, "The Queen of the Coast. Perfect rights in winter."),
            ("Pipeline", .reef, .expert, "Iconic hollow reef break on Oahu's North Shore."),
            ("Sunset Beach", .beach, .advanced, "Big and powerful. Best Nov–Feb."),
            ("Mondos", .beach, .beginner, "Mellow beach break. Great for learning."),
            ("C Street", .point, .intermediate, "Ventura's classic right-hander. Works on any swell."),
            ("Huntington Pier", .beach, .intermediate, "Surf City USA. Consistent beach break."),
        ]
        let spots = spotsData.map { data in
            let spot = SurfSpot(name: data.0, breakType: data.1, difficulty: data.2, notes: data.3)
            context.insert(spot)
            return spot
        }
        return spots
    }

    @discardableResult
    static func seedBoards(context: ModelContext) -> [Board] {
        let boardsData: [(String, BoardType, Int, Int, Double, FinSetup)] = [
            ("Channel Islands FishBeard", .fish, 5, 10, 36.5, .quad),
            ("JS Monsta Box", .shortboard, 6, 0, 31.2, .thruster),
            ("Firewire Seaside", .funboard, 7, 4, 56.0, .fiveFinBox),
            ("Harbour Revenge", .longboard, 9, 2, 78.0, .single),
            ("NSP Elements", .malibu, 8, 0, 65.0, .fiveFinBox),
        ]
        let boards = boardsData.map { data in
            let board = Board(
                name: data.0,
                type: data.1,
                lengthFt: data.2,
                lengthIn: data.3,
                volumeLiters: data.4,
                finSetup: data.5
            )
            context.insert(board)
            return board
        }
        return boards
    }

    static func seedSessions(context: ModelContext, spots: [String], boards: [String]) {
        let calendar = Calendar.current
        let now = Date.now

        let sessionData: [(Int, String, String, Int, Double, Int, Double, WindDirection, SessionConditions, Int, String)] = [
            // daysAgo, spot, board, duration, waveHt, period, wind, dir, cond, rating, notes
            (2, "Malibu", "JS Monsta Box", 120, 4.5, 14, 8.0, .w, .epic, 5, "Firing! Best session in months. Long walls all the way through."),
            (5, "Trestles", "Channel Islands FishBeard", 90, 3.5, 13, 10.0, .w, .good, 4, "Consistent sets, a bit crowded but worth it."),
            (9, "C Street", "Firewire Seaside", 75, 2.0, 11, 15.0, .sw, .fair, 3, "A bit mushy but good practice."),
            (12, "Huntington Pier", "JS Monsta Box", 60, 2.5, 10, 12.0, .nw, .fair, 3, "Afternoon slop, still fun."),
            (16, "Rincon", "Channel Islands FishBeard", 150, 6.0, 16, 5.0, .w, .epic, 5, "Unbelievable Rincon. Rode one wave for over a minute."),
            (19, "Malibu", "Harbour Revenge", 90, 3.0, 12, 9.0, .w, .good, 4, "Perfect longboard day at Malibu."),
            (23, "Mondos", "NSP Elements", 60, 1.5, 9, 18.0, .sw, .poor, 2, "Choppy and small but needed to get wet."),
            (27, "Trestles", "JS Monsta Box", 105, 4.0, 14, 7.0, .w, .good, 4, "Lower Trestles on fire. Clean glassy walls."),
            (31, "Sunset Beach", "JS Monsta Box", 90, 5.5, 15, 14.0, .ne, .good, 4, "Overhead plus. Got worked but scored some bombs."),
            (35, "C Street", "Firewire Seaside", 75, 2.5, 11, 11.0, .w, .good, 3, "Steady rights. Fun session."),
            (39, "Malibu", "Channel Islands FishBeard", 120, 4.0, 13, 8.0, .nw, .epic, 5, "Malibu at its best. Six-foot rights."),
            (44, "Rincon", "Harbour Revenge", 135, 5.0, 15, 6.0, .w, .epic, 5, "Rincon wintertime perfection. Shoulder-high sets rolling through."),
            (48, "Huntington Pier", "NSP Elements", 70, 2.0, 10, 20.0, .s, .poor, 2, "South windswell, choppy mess."),
            (52, "Trestles", "JS Monsta Box", 100, 3.5, 13, 9.0, .w, .good, 4, "Solid NW swell. Fun all morning."),
            (56, "Mondos", "NSP Elements", 60, 1.5, 9, 14.0, .sw, .fair, 3, "Teaching a friend. Small but clean."),
            (61, "Malibu", "Harbour Revenge", 90, 3.0, 12, 10.0, .w, .good, 4, "Longboard paradise. Noserode a couple."),
            (65, "C Street", "Channel Islands FishBeard", 80, 3.5, 12, 8.0, .nw, .good, 4, "C Street performing well with the NW."),
            (70, "Rincon", "JS Monsta Box", 120, 5.5, 16, 5.0, .w, .epic, 5, "Magical December morning at the Queen."),
            (74, "Sunset Beach", "Firewire Seaside", 90, 4.0, 14, 12.0, .n, .good, 3, "Powerful sets. A bit too much for the funboard."),
            (78, "Trestles", "Channel Islands FishBeard", 95, 3.0, 12, 10.0, .w, .good, 4, "Fish was flying. Found a great rhythm."),
            (82, "Huntington Pier", "JS Monsta Box", 75, 2.5, 11, 15.0, .nw, .fair, 3, "Bit windblown, still fun."),
            (87, "Malibu", "Firewire Seaside", 100, 3.5, 13, 8.0, .w, .good, 4, "Funboard session at Malibu. So comfortable."),
            (91, "Mondos", "NSP Elements", 65, 1.5, 9, 16.0, .sw, .fair, 2, "Small summer swell. Better than nothing."),
            (96, "C Street", "Harbour Revenge", 90, 2.5, 10, 12.0, .w, .fair, 3, "Longboard, choppy walls."),
            (100, "Rincon", "JS Monsta Box", 110, 4.5, 14, 7.0, .nw, .good, 4, "Good October swell. Sets stacking up nicely."),
            (105, "Trestles", "Channel Islands FishBeard", 90, 3.5, 13, 9.0, .w, .good, 4, "Another great Trestles session."),
            (110, "Sunset Beach", "Firewire Seaside", 85, 5.0, 15, 11.0, .ne, .good, 4, "Big, powerful, exhilarating."),
            (114, "Malibu", "Harbour Revenge", 100, 4.0, 14, 6.0, .w, .epic, 5, "Dawn patrol. Empty lineup, glassy. Heaven."),
            (119, "Huntington Pier", "JS Monsta Box", 70, 2.5, 10, 17.0, .s, .poor, 2, "Windy and choppy."),
            (124, "C Street", "Channel Islands FishBeard", 80, 3.0, 12, 10.0, .w, .good, 4, "Fish tearing C Street apart."),
            (128, "Mondos", "NSP Elements", 60, 1.5, 8, 15.0, .sw, .fair, 3, "Summer small stuff. Got some rides."),
            (133, "Rincon", "Harbour Revenge", 130, 5.5, 16, 5.0, .w, .epic, 5, "Another Rincon classic. Could live here."),
            (137, "Trestles", "JS Monsta Box", 95, 4.0, 13, 8.0, .nw, .good, 4, "Solid session. Made some good turns."),
            (142, "Malibu", "Channel Islands FishBeard", 110, 3.5, 13, 9.0, .w, .good, 4, "Fish loves this spot. Super fun."),
            (147, "Sunset Beach", "JS Monsta Box", 90, 6.0, 16, 13.0, .n, .epic, 5, "Double overhead sets. Paddled for 30 minutes to get out."),
            (151, "Huntington Pier", "Firewire Seaside", 75, 2.5, 10, 14.0, .nw, .fair, 3, "Funboard fun. Not the best day."),
            (156, "C Street", "JS Monsta Box", 85, 3.5, 12, 8.0, .w, .good, 4, "Rights peeling beautifully."),
            (161, "Malibu", "Harbour Revenge", 95, 4.5, 14, 7.0, .w, .epic, 5, "Winter Malibu magic. Classic set waves."),
            (165, "Rincon", "Channel Islands FishBeard", 115, 5.0, 15, 6.0, .w, .epic, 5, "The fish at Rincon is a revelation. Buttery."),
            (170, "Trestles", "JS Monsta Box", 90, 3.5, 13, 10.0, .nw, .good, 4, "Consistent sets all morning."),
            (175, "Mondos", "NSP Elements", 60, 1.5, 9, 20.0, .sw, .poor, 2, "Onshore mess. Surfed anyway."),
            (180, "Huntington Pier", "JS Monsta Box", 70, 3.0, 11, 12.0, .w, .good, 3, "Average pier session. Caught some runners."),
            (185, "C Street", "Firewire Seaside", 80, 2.5, 10, 14.0, .sw, .fair, 3, "C Street dying off on an E swell day."),
            (190, "Malibu", "Harbour Revenge", 90, 3.5, 13, 8.0, .w, .good, 4, "Super fun longboard session."),
            (195, "Trestles", "Channel Islands FishBeard", 100, 4.5, 14, 7.0, .nw, .epic, 5, "NW swell firing. Trestles on a weekday = heaven."),
            (200, "Rincon", "JS Monsta Box", 120, 6.0, 16, 5.0, .w, .epic, 5, "The day Rincon delivered a foot overhead sets all day."),
            (210, "Sunset Beach", "Firewire Seaside", 85, 5.0, 15, 12.0, .ne, .good, 4, "Big powerful beach break. Held on for dear life."),
            (220, "Malibu", "Channel Islands FishBeard", 105, 4.0, 14, 8.0, .w, .epic, 5, "Perfect NW swell. Fish was a dream."),
            (230, "C Street", "Harbour Revenge", 95, 3.5, 13, 9.0, .w, .good, 4, "Longboard cruising. Pure joy."),
            (240, "Trestles", "JS Monsta Box", 90, 3.5, 13, 10.0, .nw, .good, 4, "Start of the season. A bit rusty."),
            (250, "Mondos", "NSP Elements", 65, 1.5, 9, 13.0, .sw, .fair, 3, "Summer slop. Got a little workout."),
            (260, "Huntington Pier", "JS Monsta Box", 75, 3.0, 12, 11.0, .w, .good, 3, "Early morning glass. Decent sets."),
            (270, "Rincon", "Channel Islands FishBeard", 120, 5.5, 16, 5.0, .w, .epic, 5, "First Rincon session of the year. Set the bar high."),
            (280, "Malibu", "Harbour Revenge", 100, 4.5, 14, 7.0, .w, .epic, 5, "Overhead Malibu. The longboard was in its element."),
            (290, "C Street", "JS Monsta Box", 85, 3.5, 12, 9.0, .nw, .good, 4, "Quality rights peeling into the cove."),
            (300, "Sunset Beach", "Firewire Seaside", 90, 4.5, 14, 13.0, .n, .good, 4, "Powerful sets. A lot of fun."),
        ]

        for data in sessionData {
            let daysAgo = data.0
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: now) else { continue }
            let session = SurfSession(
                date: date,
                spotName: data.1,
                boardName: data.2,
                durationMinutes: data.3,
                waveHeightFt: data.4,
                swellPeriodSec: data.5,
                windSpeedKnots: data.6,
                windDirection: data.7,
                conditions: data.8,
                rating: data.9,
                notes: data.10
            )
            context.insert(session)
        }
    }
}

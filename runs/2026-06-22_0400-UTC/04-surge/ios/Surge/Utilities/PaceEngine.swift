import Foundation

struct PaceEngine {

    // MARK: - Conversions

    /// Convert finish time to pace (seconds per km)
    static func pace(finishTimeSeconds: Int, distanceKm: Double) -> Double {
        guard distanceKm > 0 else { return 0 }
        return Double(finishTimeSeconds) / distanceKm
    }

    /// Convert pace (seconds per km) to finish time for a given distance
    static func finishTime(paceSecondsPerKm: Double, distanceKm: Double) -> Int {
        guard paceSecondsPerKm > 0, distanceKm > 0 else { return 0 }
        return Int(paceSecondsPerKm * distanceKm)
    }

    /// Convert km pace to mile pace
    static func kmPaceToMilePace(_ secondsPerKm: Double) -> Double {
        return secondsPerKm * 1.60934
    }

    /// Convert mile pace to km pace
    static func milePaceToKmPace(_ secondsPerMile: Double) -> Double {
        guard secondsPerMile > 0 else { return 0 }
        return secondsPerMile / 1.60934
    }

    /// Convert km distance to miles
    static func kmToMiles(_ km: Double) -> Double {
        return km * 0.621371
    }

    /// Convert miles to km
    static func milesToKm(_ miles: Double) -> Double {
        return miles * 1.60934
    }

    // MARK: - Formatting

    /// Format pace as "mm:ss /km" or "mm:ss /mi"
    static func formatPace(_ secondsPerKm: Double, unit: String = "km") -> String {
        guard secondsPerKm > 0 else { return "--:-- /\(unit)" }
        let paceSeconds: Double
        if unit == "mi" {
            paceSeconds = kmPaceToMilePace(secondsPerKm)
        } else {
            paceSeconds = secondsPerKm
        }
        let minutes = Int(paceSeconds) / 60
        let seconds = Int(paceSeconds) % 60
        return String(format: "%d:%02d /%@", minutes, seconds, unit)
    }

    /// Format pace as "mm:ss" only (no unit suffix)
    static func formatPaceShort(_ secondsPerKm: Double, unit: String = "km") -> String {
        guard secondsPerKm > 0 else { return "--:--" }
        let paceSeconds: Double
        if unit == "mi" {
            paceSeconds = kmPaceToMilePace(secondsPerKm)
        } else {
            paceSeconds = secondsPerKm
        }
        let minutes = Int(paceSeconds) / 60
        let seconds = Int(paceSeconds) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Format duration as "h:mm:ss" or "mm:ss" if under an hour
    static func formatDuration(_ seconds: Int) -> String {
        guard seconds > 0 else { return "0:00" }
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }

    /// Format distance with appropriate unit
    static func formatDistance(_ km: Double, unit: String = "km") -> String {
        if unit == "mi" {
            return String(format: "%.1f mi", kmToMiles(km))
        } else {
            return String(format: "%.1f km", km)
        }
    }

    /// Format a goal time for display (e.g. "3:45:00")
    static func formatGoalTime(_ seconds: Int) -> String {
        return formatDuration(seconds)
    }

    // MARK: - Training Paces

    static func trainingPaces(goalRaceSeconds: Int, raceType: RaceType) -> TrainingPaces {
        let goalPace = pace(finishTimeSeconds: goalRaceSeconds, distanceKm: raceType.distanceKm)

        return TrainingPaces(
            goalPace: goalPace,
            easyPace: goalPace + 75,       // +75 sec/km (midpoint of 60-90)
            longRunPace: goalPace + 60,    // +60 sec/km (midpoint of 45-75)
            tempoPace: goalPace,           // at goal pace
            intervalPace: max(goalPace - 25, 180), // -25 sec/km, min 3:00/km
            racePace: goalPace
        )
    }
}

struct TrainingPaces {
    let goalPace: Double          // seconds per km
    let easyPace: Double
    let longRunPace: Double
    let tempoPace: Double
    let intervalPace: Double
    let racePace: Double

    func pace(for runType: RunType) -> Double {
        switch runType {
        case .easy: return easyPace
        case .long: return longRunPace
        case .tempo: return tempoPace
        case .interval: return intervalPace
        case .racePace: return racePace
        case .crossTrain, .rest: return 0
        }
    }

    func paceRange(for runType: RunType, unit: String = "km") -> String {
        switch runType {
        case .easy:
            let low = PaceEngine.formatPaceShort(easyPace - 10, unit: unit)
            let high = PaceEngine.formatPaceShort(easyPace + 20, unit: unit)
            return "\(low)–\(high)"
        case .long:
            let low = PaceEngine.formatPaceShort(longRunPace - 10, unit: unit)
            let high = PaceEngine.formatPaceShort(longRunPace + 20, unit: unit)
            return "\(low)–\(high)"
        case .tempo:
            let low = PaceEngine.formatPaceShort(tempoPace - 10, unit: unit)
            let high = PaceEngine.formatPaceShort(tempoPace + 10, unit: unit)
            return "\(low)–\(high)"
        case .interval:
            let low = PaceEngine.formatPaceShort(intervalPace - 10, unit: unit)
            let high = PaceEngine.formatPaceShort(intervalPace + 10, unit: unit)
            return "\(low)–\(high)"
        case .racePace:
            return PaceEngine.formatPaceShort(racePace, unit: unit)
        case .crossTrain:
            return "Low impact"
        case .rest:
            return "Recovery"
        }
    }
}

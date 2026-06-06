import Foundation
import SwiftData

/// Real, on-brand seed content so a first launch is a populated, realistic app —
/// not a void. Inserted once (gated by SettingsStore.hasSeeded) and reused by
/// "Reset to sample" in Settings. Always inserts into an empty store only.
enum SampleData {

    static func insert(into context: ModelContext) {
        insertPortraRoll(into: context)
        insertTriXRoll(into: context)
        insertVelviaRoll(into: context)
        insertHP5Roll(into: context)
    }

    /// Remove every roll (cascade removes its frames).
    static func clear(_ context: ModelContext) throws {
        let all = try context.fetch(FetchDescriptor<Roll>())
        for roll in all { context.delete(roll) }
    }

    // MARK: - Builder

    private static func addFrame(to roll: Roll,
                                 aperture: Double,
                                 shutter: Double,
                                 focal: Double,
                                 subject: String,
                                 location: String,
                                 notes: String = "",
                                 into context: ModelContext) {
        let frame = Frame(number: roll.nextFrameNumber,
                          aperture: aperture,
                          shutterSeconds: shutter,
                          focalLengthMM: focal,
                          subject: subject,
                          location: location,
                          notes: notes)
        frame.roll = roll
        roll.frames.append(frame)
        context.insert(frame)
    }

    private static func roll(_ stock: String, iso: Double, format: FilmFormat,
                             camera: String, daysAgo: Int, finished: Bool,
                             notes: String, into context: ModelContext) -> Roll {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now) ?? .now
        let r = Roll(filmStock: stock, iso: iso, format: format, camera: camera,
                     notes: notes, createdAt: date, isFinished: finished)
        context.insert(r)
        return r
    }

    // MARK: - Rolls

    private static func insertPortraRoll(into context: ModelContext) {
        let r = roll("Kodak Portra 400", iso: 400, format: .format35mm,
                     camera: "Nikon FE2", daysAgo: 6, finished: false,
                     notes: "Overcast portrait walk through the old quarter.",
                     into: context)
        addFrame(to: r, aperture: 2.8, shutter: 1.0/500, focal: 85,
                 subject: "Mara by the blue door", location: "Old Town",
                 notes: "Wide open for separation.", into: context)
        addFrame(to: r, aperture: 4, shutter: 1.0/250, focal: 50,
                 subject: "Market stall figs", location: "Saturday Market", into: context)
        addFrame(to: r, aperture: 5.6, shutter: 1.0/125, focal: 35,
                 subject: "Street musician", location: "Cathedral Square",
                 notes: "Stopped down for the band in frame.", into: context)
        addFrame(to: r, aperture: 2.8, shutter: 1.0/1000, focal: 85,
                 subject: "Theo laughing", location: "Riverside", into: context)
        addFrame(to: r, aperture: 8, shutter: 1.0/250, focal: 28,
                 subject: "Bridge in flat light", location: "Riverside", into: context)
    }

    private static func insertTriXRoll(into context: ModelContext) {
        let r = roll("Kodak Tri-X 400", iso: 400, format: .format35mm,
                     camera: "Leica M6", daysAgo: 14, finished: true,
                     notes: "Pushed one stop to 800 — gritty city night.",
                     into: context)
        addFrame(to: r, aperture: 2, shutter: 1.0/60, focal: 35,
                 subject: "Neon diner window", location: "5th & Vine",
                 notes: "Hand-held, leaned on a post.", into: context)
        addFrame(to: r, aperture: 2.8, shutter: 1.0/125, focal: 50,
                 subject: "Rain on the crosswalk", location: "Downtown", into: context)
        addFrame(to: r, aperture: 1.4, shutter: 1.0/30, focal: 35,
                 subject: "Bartender, backlit", location: "The Anchor",
                 notes: "Wide open in near dark.", into: context)
        addFrame(to: r, aperture: 4, shutter: 1.0/250, focal: 50,
                 subject: "Subway stairs", location: "Line 2", into: context)
    }

    private static func insertVelviaRoll(into context: ModelContext) {
        let r = roll("Fuji Velvia 50", iso: 50, format: .medium120,
                     camera: "Hasselblad 500C/M", daysAgo: 30, finished: true,
                     notes: "Dawn landscapes, tripod, mirror up.",
                     into: context)
        addFrame(to: r, aperture: 16, shutter: 1.0/15, focal: 80,
                 subject: "Valley fog at sunrise", location: "Ridge Overlook",
                 notes: "f/16 for front-to-back sharpness.", into: context)
        addFrame(to: r, aperture: 22, shutter: 1.0/8, focal: 50,
                 subject: "Frosted reeds", location: "Lake Edge", into: context)
        addFrame(to: r, aperture: 11, shutter: 1.0/30, focal: 80,
                 subject: "First light on the peak", location: "Ridge Overlook", into: context)
    }

    private static func insertHP5Roll(into context: ModelContext) {
        let r = roll("Ilford HP5 Plus", iso: 400, format: .format35mm,
                     camera: "Pentax K1000", daysAgo: 2, finished: false,
                     notes: "Learning roll — bright midday harbour.",
                     into: context)
        addFrame(to: r, aperture: 11, shutter: 1.0/500, focal: 50,
                 subject: "Moored boats", location: "Harbour", into: context)
        addFrame(to: r, aperture: 8, shutter: 1.0/1000, focal: 50,
                 subject: "Gulls overhead", location: "Pier", into: context)
    }
}

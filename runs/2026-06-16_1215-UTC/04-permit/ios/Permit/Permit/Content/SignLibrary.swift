import Foundation

/// Library of ~30 common US road signs, described so each can be drawn with SwiftUI shapes.
enum SignLibrary {
    static let all: [RoadSign] = [
        // MARK: Regulatory
        RoadSign(
            name: "Stop",
            kind: .regulatory,
            meaning: "Come to a complete stop, yield to traffic and pedestrians, then proceed when safe.",
            shapeColorHint: "Red octagon, white letters",
            studyTip: "The only octagon on the road. A complete stop means wheels not moving."
        ),
        RoadSign(
            name: "Yield",
            kind: .regulatory,
            meaning: "Slow down and give the right-of-way to traffic and pedestrians; stop if necessary.",
            shapeColorHint: "Downward red-and-white triangle",
            studyTip: "Yield does not always mean stop, but be ready to."
        ),
        RoadSign(
            name: "Do Not Enter",
            kind: .regulatory,
            meaning: "You may not enter the roadway from your direction; it is for opposing traffic only.",
            shapeColorHint: "Red square with white horizontal bar",
            studyTip: "Often seen at one-way streets and freeway exit ramps."
        ),
        RoadSign(
            name: "Wrong Way",
            kind: .regulatory,
            meaning: "You are traveling against traffic. Turn around safely as soon as possible.",
            shapeColorHint: "Red rectangle, white letters",
            studyTip: "Usually paired with Do Not Enter on ramps."
        ),
        RoadSign(
            name: "Speed Limit",
            kind: .regulatory,
            meaning: "The maximum legal speed in ideal conditions for that stretch of road.",
            shapeColorHint: "White rectangle, black numbers",
            studyTip: "It is a maximum, not a target — slow down in poor conditions."
        ),
        RoadSign(
            name: "No U-Turn",
            kind: .regulatory,
            meaning: "Making a U-turn at this location is prohibited.",
            shapeColorHint: "White square, black U-arrow with red slash",
            studyTip: "A red circle with a slash always means 'prohibited.'"
        ),
        RoadSign(
            name: "No Left Turn",
            kind: .regulatory,
            meaning: "Turning left at this intersection is not allowed.",
            shapeColorHint: "White square, black left arrow with red slash",
            studyTip: "Look for an alternate route to reach your destination."
        ),
        RoadSign(
            name: "No Parking",
            kind: .regulatory,
            meaning: "Parking is prohibited where this sign applies.",
            shapeColorHint: "White rectangle, red letters/circle-slash",
            studyTip: "Stopping briefly may still be banned — read the full sign."
        ),
        RoadSign(
            name: "One Way",
            kind: .regulatory,
            meaning: "Traffic flows only in the direction the arrow points.",
            shapeColorHint: "Black rectangle, white arrow",
            studyTip: "Never turn against the arrow."
        ),
        RoadSign(
            name: "Keep Right",
            kind: .regulatory,
            meaning: "Pass to the right of a divider, median or obstruction.",
            shapeColorHint: "Black-and-white arrow sign",
            studyTip: "Marks the start of a median or traffic island."
        ),
        RoadSign(
            name: "No Passing Zone",
            kind: .regulatory,
            meaning: "Passing other vehicles is prohibited in this zone.",
            shapeColorHint: "Yellow pennant (sideways triangle)",
            studyTip: "The pennant points where the no-passing zone begins, on the left."
        ),

        // MARK: Warning
        RoadSign(
            name: "Curve Ahead",
            kind: .warning,
            meaning: "The road ahead curves; reduce speed and stay in your lane.",
            shapeColorHint: "Yellow diamond, black curved arrow",
            studyTip: "Yellow diamonds warn you to prepare for a hazard."
        ),
        RoadSign(
            name: "Stop Ahead",
            kind: .warning,
            meaning: "A stop sign is ahead; begin slowing now so you can stop in time.",
            shapeColorHint: "Yellow diamond, red octagon symbol",
            studyTip: "Gives advance notice where a stop may be hidden."
        ),
        RoadSign(
            name: "Signal Ahead",
            kind: .warning,
            meaning: "A traffic signal is ahead; be prepared to stop.",
            shapeColorHint: "Yellow diamond, traffic-light symbol",
            studyTip: "Useful where the light is hard to see until close."
        ),
        RoadSign(
            name: "Pedestrian Crossing",
            kind: .warning,
            meaning: "Watch for people crossing the road; be ready to yield.",
            shapeColorHint: "Yellow (or yellow-green) diamond, walking figure",
            studyTip: "Fluorescent yellow-green is reserved for pedestrian and bike warnings."
        ),
        RoadSign(
            name: "School Zone",
            kind: .warning,
            meaning: "You are near a school; watch for children and obey reduced speed limits.",
            shapeColorHint: "Yellow-green pentagon, two figures",
            studyTip: "The five-sided pentagon shape signals a school area or crossing."
        ),
        RoadSign(
            name: "Slippery When Wet",
            kind: .warning,
            meaning: "The road can be slippery in rain or snow; slow down and avoid hard braking.",
            shapeColorHint: "Yellow diamond, car with wavy skid lines",
            studyTip: "Bridges and shaded spots ice over first."
        ),
        RoadSign(
            name: "Merge",
            kind: .warning,
            meaning: "Traffic from another lane is joining yours; adjust speed to merge smoothly.",
            shapeColorHint: "Yellow diamond, two lines merging",
            studyTip: "Drivers already in the through lane generally have right-of-way."
        ),
        RoadSign(
            name: "Divided Highway Begins",
            kind: .warning,
            meaning: "The roadway ahead is split by a median; keep right.",
            shapeColorHint: "Yellow diamond, two arrows splitting around a divider",
            studyTip: "Opposing traffic will be separated from yours."
        ),
        RoadSign(
            name: "Two-Way Traffic",
            kind: .warning,
            meaning: "You are leaving a one-way or divided road; oncoming traffic shares the road.",
            shapeColorHint: "Yellow diamond, two opposing arrows",
            studyTip: "Do not pass unless the lane lines allow it."
        ),
        RoadSign(
            name: "Railroad Crossing",
            kind: .warning,
            meaning: "A railroad crosses ahead; look, listen and be ready to stop for trains.",
            shapeColorHint: "Round yellow sign with black X and RR",
            studyTip: "Never stop on the tracks or try to beat a train."
        ),
        RoadSign(
            name: "Deer Crossing",
            kind: .warning,
            meaning: "Wildlife may enter the road; scan the shoulders, especially at dawn and dusk.",
            shapeColorHint: "Yellow diamond, leaping deer",
            studyTip: "If one animal crosses, more may follow."
        ),
        RoadSign(
            name: "T Intersection",
            kind: .warning,
            meaning: "Your road ends ahead at a T; you must turn left or right.",
            shapeColorHint: "Yellow diamond, T symbol",
            studyTip: "Slow down — through traffic does not stop for you."
        ),
        RoadSign(
            name: "Roundabout Ahead",
            kind: .warning,
            meaning: "A circular intersection is ahead; slow down and yield to traffic in the circle.",
            shapeColorHint: "Yellow diamond, three curved arrows in a circle",
            studyTip: "Traffic in the roundabout has the right-of-way."
        ),
        RoadSign(
            name: "Lane Ends",
            kind: .warning,
            meaning: "Your lane is ending ahead; merge into the continuing lane.",
            shapeColorHint: "Yellow diamond, lane narrowing symbol",
            studyTip: "Merge early and signal — do not wait until the lane disappears."
        ),
        RoadSign(
            name: "Steep Grade",
            kind: .warning,
            meaning: "A steep downhill is ahead; shift to a lower gear and watch your speed.",
            shapeColorHint: "Yellow diamond, truck on a slope",
            studyTip: "Use engine braking to avoid overheating your brakes."
        ),

        // MARK: Guide / Construction
        RoadSign(
            name: "Work Zone",
            kind: .warning,
            meaning: "Road work ahead; reduce speed, expect workers and obey flaggers.",
            shapeColorHint: "Orange diamond, black symbol",
            studyTip: "Orange always means a temporary construction or maintenance area."
        ),
        RoadSign(
            name: "Flagger Ahead",
            kind: .warning,
            meaning: "A person is directing traffic ahead; follow the flagger's signals.",
            shapeColorHint: "Orange diamond, flagger figure",
            studyTip: "A flagger's instructions override signs and signals."
        ),
        RoadSign(
            name: "Hospital",
            kind: .guidance,
            meaning: "Directs you toward a nearby hospital.",
            shapeColorHint: "Blue rectangle, white H",
            studyTip: "Blue guide signs point to motorist services."
        ),
        RoadSign(
            name: "Rest Area",
            kind: .guidance,
            meaning: "A rest area with parking and restrooms is ahead.",
            shapeColorHint: "Blue rectangle, white text/symbol",
            studyTip: "A good place to stop if you feel drowsy."
        ),
        RoadSign(
            name: "Route Marker",
            kind: .guidance,
            meaning: "Identifies the highway or interstate route you are on.",
            shapeColorHint: "Shield shape, route number",
            studyTip: "Green guide signs give directions and distances."
        )
    ]

    /// Lookup a sign by name (used to link sign questions to the library).
    static func sign(named name: String) -> RoadSign? {
        all.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
    }

    static func signs(of kind: SignKind) -> [RoadSign] {
        all.filter { $0.kind == kind }
    }
}

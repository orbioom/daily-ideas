import Foundation
import SwiftData

/// One day's shared answer to the daily question. Created when the first
/// partner starts typing; `revealed` flips when both answers are in.
@Model
final class Answer {
    var dateKey: String        // "yyyy-MM-dd"
    var questionID: Int
    var partnerAText: String
    var partnerBText: String
    var revealed: Bool
    var favorite: Bool
    var createdAt: Date

    init(dateKey: String, questionID: Int, partnerAText: String = "",
         partnerBText: String = "", revealed: Bool = false,
         favorite: Bool = false, createdAt: Date = .now) {
        self.dateKey = dateKey
        self.questionID = questionID
        self.partnerAText = partnerAText
        self.partnerBText = partnerBText
        self.revealed = revealed
        self.favorite = favorite
        self.createdAt = createdAt
    }
}

/// A logged moment worth keeping — first dates, small wins, big days.
@Model
final class Memory {
    var date: Date
    var title: String
    var note: String
    var emoji: String
    var createdAt: Date

    init(date: Date = .now, title: String, note: String = "",
         emoji: String = "💛", createdAt: Date = .now) {
        self.date = date
        self.title = title
        self.note = note
        self.emoji = emoji
        self.createdAt = createdAt
    }
}

/// A weekly relationship pulse: three 1–5 ratings plus a note.
@Model
final class CheckIn {
    var date: Date
    var connection: Int
    var communication: Int
    var fun: Int
    var note: String

    init(date: Date = .now, connection: Int, communication: Int, fun: Int, note: String = "") {
        self.date = date
        self.connection = connection
        self.communication = communication
        self.fun = fun
        self.note = note
    }

    var average: Double { Double(connection + communication + fun) / 3.0 }
}

/// Favorite/done state for a built-in date idea.
@Model
final class IdeaMark {
    var ideaID: Int
    var favorite: Bool
    var done: Bool
    var doneDate: Date?

    init(ideaID: Int, favorite: Bool = false, done: Bool = false, doneDate: Date? = nil) {
        self.ideaID = ideaID
        self.favorite = favorite
        self.done = done
        self.doneDate = doneDate
    }
}

/// An annually recurring date that matters — anniversary, birthdays.
@Model
final class Occasion {
    var title: String
    var date: Date
    var repeatsAnnually: Bool

    init(title: String, date: Date, repeatsAnnually: Bool = true) {
        self.title = title
        self.date = date
        self.repeatsAnnually = repeatsAnnually
    }
}

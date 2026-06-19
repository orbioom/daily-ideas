import SwiftData
import Foundation

@Model
class LyricEntry {
    var title: String
    var content: String
    var dateCreated: Date
    var dateModified: Date

    init(title: String, content: String = "") {
        self.title = title
        self.content = content
        self.dateCreated = Date()
        self.dateModified = Date()
    }

    var lineCount: Int { content.components(separatedBy: "\n").filter { !$0.isEmpty }.count }
    var wordCount: Int { content.components(separatedBy: .whitespaces).filter { !$0.isEmpty }.count }
}

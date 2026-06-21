import SwiftUI
import SwiftData

@Observable final class DailyLogViewModel {
    var selectedDate: Date = Calendar.current.startOfDay(for: .now)
    var newEntryText: String = ""
    var newBulletType: BulletType = .task
    var isAddingEntry: Bool = false
    var showMigrationConfirm: Bool = false
    var entryToMigrate: BulletEntry? = nil

    func entriesForDate(_ date: Date, all: [BulletEntry]) -> [BulletEntry] {
        let start = Calendar.current.startOfDay(for: date)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        return all
            .filter { $0.collectionId == nil && $0.date >= start && $0.date < end }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    func addEntry(context: ModelContext, all: [BulletEntry]) {
        let trimmed = newEntryText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let maxOrder = entriesForDate(selectedDate, all: all).map(\.sortOrder).max() ?? -1
        let entry = BulletEntry(
            date: selectedDate,
            bulletType: newBulletType,
            text: trimmed,
            sortOrder: maxOrder + 1
        )
        context.insert(entry)
        try? context.save()
        newEntryText = ""
        isAddingEntry = false
    }

    func toggleComplete(_ entry: BulletEntry, context: ModelContext) {
        guard entry.bulletTypeEnum == .task else { return }
        if entry.statusEnum == .open {
            entry.status = TaskStatus.complete.rawValue
        } else if entry.statusEnum == .complete {
            entry.status = TaskStatus.open.rawValue
        }
        try? context.save()
    }

    func migrate(_ entry: BulletEntry, context: ModelContext) {
        entry.status = TaskStatus.migrated.rawValue
        let today = Calendar.current.startOfDay(for: .now)
        let allDailyToday = (try? context.fetch(FetchDescriptor<BulletEntry>()))?.filter {
            $0.collectionId == nil && Calendar.current.isDate($0.date, inSameDayAs: today)
        } ?? []
        let maxOrder = allDailyToday.map(\.sortOrder).max() ?? -1
        let newEntry = BulletEntry(
            date: today,
            bulletType: entry.bulletTypeEnum,
            text: entry.text,
            sortOrder: maxOrder + 1
        )
        context.insert(newEntry)
        try? context.save()
    }

    func markIrrelevant(_ entry: BulletEntry, context: ModelContext) {
        guard entry.bulletTypeEnum == .task else { return }
        entry.status = TaskStatus.irrelevant.rawValue
        try? context.save()
    }

    func toggleStar(_ entry: BulletEntry, context: ModelContext) {
        entry.isStarred.toggle()
        try? context.save()
    }

    func delete(_ entry: BulletEntry, context: ModelContext) {
        context.delete(entry)
        try? context.save()
    }

    func navigateDay(by offset: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: offset, to: selectedDate) {
            selectedDate = Calendar.current.startOfDay(for: newDate)
        }
    }

    func jumpToToday() {
        selectedDate = Calendar.current.startOfDay(for: .now)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }
}

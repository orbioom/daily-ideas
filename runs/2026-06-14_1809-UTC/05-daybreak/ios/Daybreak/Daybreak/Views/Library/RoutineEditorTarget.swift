import Foundation

/// What the routine editor is editing: a brand-new routine, or an existing one.
enum RoutineEditorTarget: Identifiable {
    case create(nextSortOrder: Int)
    case edit(Routine)

    var id: String {
        switch self {
        case .create: return "create"
        case .edit(let routine): return routine.id.uuidString
        }
    }
}

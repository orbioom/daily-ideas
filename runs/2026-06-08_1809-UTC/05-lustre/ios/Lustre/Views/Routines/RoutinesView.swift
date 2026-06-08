import SwiftUI
import SwiftData

struct RoutinesView: View {
    @Environment(\.modelContext) private var context
    @Query private var steps: [RoutineStep]

    @State private var routine: RoutineKind = .am
    @State private var showAdd = false
    @State private var editing: RoutineStep?

    private var routineSteps: [RoutineStep] { SkincareEngine.steps(steps, for: routine) }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                VStack(spacing: 0) {
                    Picker("Routine", selection: $routine) {
                        ForEach(RoutineKind.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .padding()

                    if routineSteps.isEmpty {
                        Spacer()
                        EmptyStateView(icon: routine.icon,
                                       title: "No \(routine.title.lowercased()) steps",
                                       message: "Build your routine by adding products from your shelf or custom steps.")
                        Spacer()
                    } else {
                        List {
                            ForEach(routineSteps) { step in
                                Button { editing = step } label: { row(step) }
                                    .buttonStyle(.plain)
                                    .listRowBackground(Color.white.opacity(0.001))
                            }
                            .onMove(perform: move)
                            .onDelete(perform: delete)
                        }
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Routines")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !routineSteps.isEmpty { EditButton() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add step")
                }
            }
            .sheet(isPresented: $showAdd) { StepEditorView(routine: routine, order: routineSteps.count) }
            .sheet(item: $editing) { s in StepEditorView(editing: s) }
        }
    }

    private func row(_ step: RoutineStep) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill((step.product?.category.color ?? Brand.text3).opacity(0.16)).frame(width: 36, height: 36)
                Image(systemName: step.product?.category.icon ?? "square.dashed")
                    .foregroundStyle(step.product?.category.color ?? Brand.text3)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(step.displayName).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                Text(step.instruction.isEmpty ? step.displayCategory : step.instruction)
                    .font(.caption2).foregroundStyle(Brand.text3).lineLimit(1)
            }
            Spacer()
        }
        .padding(.vertical, 2)
    }

    private func move(_ offsets: IndexSet, _ destination: Int) {
        var items = routineSteps
        items.move(fromOffsets: offsets, toOffset: destination)
        for (i, s) in items.enumerated() { s.order = i }
        try? context.save()
        Haptics.selection()
    }

    private func delete(_ offsets: IndexSet) {
        let items = routineSteps
        for i in offsets { context.delete(items[i]) }
        // renumber
        let remaining = items.enumerated().filter { !offsets.contains($0.offset) }.map { $0.element }
        for (i, s) in remaining.enumerated() { s.order = i }
        try? context.save()
        Haptics.warning()
    }
}

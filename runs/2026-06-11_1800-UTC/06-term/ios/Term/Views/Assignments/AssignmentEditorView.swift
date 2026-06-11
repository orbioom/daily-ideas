import SwiftUI

struct AssignmentEditorView: View {
    @Bindable var assignment: Assignment
    @State private var earnedText = ""
    @FocusState private var focusedField: Field?

    private enum Field { case earned, notes }

    var body: some View {
        ZStack {
            TermTheme.bg.ignoresSafeArea()
            List {
                Section {
                    HStack {
                        Text("Name")
                            .foregroundStyle(TermTheme.subtle)
                        Spacer()
                        Text(assignment.name)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Category")
                            .foregroundStyle(TermTheme.subtle)
                        Spacer()
                        Text(assignment.category)
                    }
                    HStack {
                        Text("Due")
                            .foregroundStyle(TermTheme.subtle)
                        Spacer()
                        Text(assignment.dueDate, style: .date)
                    }
                } header: { SH("Info") }

                Section {
                    Picker("Status", selection: $assignment.statusRaw) {
                        ForEach(AssignmentStatus.allCases, id: \.rawValue) { s in
                            Label(s.rawValue, systemImage: s.icon).tag(s.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityLabel("Assignment status")
                } header: { SH("Status") }

                if assignment.status == .graded {
                    Section {
                        HStack {
                            Text("Max Points")
                                .foregroundStyle(TermTheme.subtle)
                            Spacer()
                            Text(String(format: "%.0f", assignment.maxPoints))
                        }
                        HStack {
                            Text("Earned Points")
                            Spacer()
                            TextField("0", value: $assignment.earnedPoints, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .focused($focusedField, equals: .earned)
                                .frame(width: 80)
                        }
                        if let pct = assignment.percentage {
                            HStack {
                                Text("Grade")
                                    .foregroundStyle(TermTheme.subtle)
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(GPACalculator.pointsToLetter(pct))
                                        .font(.headline.bold())
                                        .foregroundStyle(TermTheme.gradeColor(pct))
                                    Text(String(format: "%.1f%%", pct))
                                        .font(.caption)
                                        .foregroundStyle(TermTheme.subtle)
                                }
                            }
                        }
                    } header: { SH("Score") }
                }

                Section {
                    TextField("Notes (optional)", text: $assignment.notes, axis: .vertical)
                        .lineLimit(3...6)
                        .focused($focusedField, equals: .notes)
                } header: { SH("Notes") }
            }
            .scrollContentBackground(.hidden)
            .background(TermTheme.bg)
        }
        .navigationTitle(assignment.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                Button("Done") { focusedField = nil }
            }
        }
    }
}

private struct SH: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.caption.bold())
            .foregroundStyle(TermTheme.accent)
            .textCase(nil)
    }
}

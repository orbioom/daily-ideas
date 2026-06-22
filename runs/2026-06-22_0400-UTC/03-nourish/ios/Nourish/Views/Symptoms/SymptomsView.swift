import SwiftUI
import SwiftData

struct SymptomsView: View {
    @Query(sort: \SymptomEntry.date, order: .reverse) private var symptoms: [SymptomEntry]
    @State private var showingEditor = false
    @State private var editingEntry: SymptomEntry?

    var body: some View {
        NavigationStack {
            Group {
                if symptoms.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(symptoms) { entry in
                            SymptomRow(entry: entry) { editingEntry = entry }
                        }
                        .onDelete { offsets in
                            // deletion handled inline
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Symptoms")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingEditor = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingEditor) { SymptomEditorView(entry: nil) }
            .sheet(item: $editingEntry) { entry in SymptomEditorView(entry: entry) }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform.path.ecg.rectangle")
                .font(.system(size: 56))
                .foregroundStyle(NourishTheme.terra.opacity(0.4))
            Text("No Symptoms Logged")
                .font(.title3.weight(.semibold))
            Text("Log how you feel after meals to discover patterns.")
                .foregroundStyle(NourishTheme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
}

private struct SymptomRow: View {
    let entry: SymptomEntry
    let onEdit: () -> Void

    private var severityColor: Color {
        switch entry.severity {
        case 1, 2: return NourishTheme.sage
        case 3: return NourishTheme.corn
        default: return NourishTheme.terra
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(severityColor)
                .frame(width: 4)
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.symptomName)
                    .font(.subheadline.weight(.medium))
                HStack(spacing: 4) {
                    ForEach(0..<5) { i in
                        Circle()
                            .fill(i < entry.severity ? severityColor : Color.gray.opacity(0.2))
                            .frame(width: 7, height: 7)
                    }
                    Text(entry.severityLabel)
                        .font(.caption2)
                        .foregroundStyle(NourishTheme.secondaryText)
                }
            }
            Spacer()
            Text(entry.date, style: .relative)
                .font(.caption)
                .foregroundStyle(NourishTheme.secondaryText)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture { onEdit() }
    }
}

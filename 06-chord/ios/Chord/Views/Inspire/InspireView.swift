import SwiftUI
import SwiftData

struct InspireView: View {
    @Environment(\.modelContext) private var context
    @State private var engine = ChordEngine()
    @State private var showAddProgression = false
    @State private var selectedTemplate: (name: String, numerals: String, example: String)? = nil
    @AppStorage(ChordSettings.defaultKey) private var defaultKey = "C"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    infoCard

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Classic Progressions")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(engine.popularProgressions(), id: \.name) { template in
                            TemplateCard(template: template) {
                                createFromTemplate(template)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Inspire")
            .sheet(isPresented: $showAddProgression) {
                AddProgressionView()
            }
        }
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(ChordTheme.amber)
                    .accessibilityHidden(true)
                Text("Quick Start")
                    .font(.headline)
            }
            Text("Tap any progression below to create a new song sketch loaded with that pattern. Then customize from there.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    private func createFromTemplate(_ template: (name: String, numerals: String, example: String)) {
        let progression = Progression(title: template.name, keyName: defaultKey, genre: .pop, tempo: 120)
        context.insert(progression)
        let chordNames = template.example.components(separatedBy: "–")
        for (i, name) in chordNames.enumerated() {
            let trimmed = name.trimmingCharacters(in: .whitespaces)
            let isMinor = trimmed.count > 1 && trimmed.last == "m"
            let root = isMinor ? String(trimmed.dropLast()) : trimmed
            let quality: ChordQuality = isMinor ? .minor : .major
            let slot = ChordSlot(rootNote: root, quality: quality, duration: .four, position: i)
            context.insert(slot)
            progression.chords.append(slot)
        }
    }
}

struct TemplateCard: View {
    let template: (name: String, numerals: String, example: String)
    let onCreate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(template.name)
                        .font(.subheadline.weight(.semibold))
                    Text(template.numerals)
                        .font(.caption)
                        .foregroundStyle(ChordTheme.teal)
                }
                Spacer()
                Button {
                    onCreate()
                } label: {
                    Label("Use", systemImage: "plus.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(ChordTheme.teal)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Create progression from \(template.name)")
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(template.example.components(separatedBy: "–"), id: \.self) { chord in
                        let trimmed = chord.trimmingCharacters(in: .whitespaces)
                        let isMinor = trimmed.count > 1 && trimmed.last == "m"
                        Text(trimmed)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(isMinor ? Color.purple.opacity(0.7) : ChordTheme.teal,
                                        in: RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
    }
}

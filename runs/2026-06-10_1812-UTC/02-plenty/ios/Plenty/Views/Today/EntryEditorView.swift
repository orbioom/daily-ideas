import SwiftUI
import SwiftData

struct EntryEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var day: GratitudeDay
    let phase: RitualPhase

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        if phase == .morning { morningFields } else { eveningFields }
                    }
                    .padding(20)
                }
            }
            .navigationTitle(phase == .morning ? "Morning" : "Evening")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { save() ; dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { complete() ; dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    @ViewBuilder private var morningFields: some View {
        promptHeader(Prompts.ofDay(Prompts.gratitude), "I'm grateful for…")
        ForEach(0..<3, id: \.self) { i in
            gratitudeField(text: $day.morningGratitudes[i], placeholder: "Gratitude \(i + 1)")
        }
        Divider().background(Brand.hairline)
        Eyebrow(text: "Today's intention")
        Text(Prompts.ofDay(Prompts.intention)).font(.subheadline).foregroundStyle(Brand.text2)
        gratitudeField(text: $day.dailyIntention, placeholder: "I intend to…")
    }

    @ViewBuilder private var eveningFields: some View {
        promptHeader(Prompts.ofDay(Prompts.win), "Three good things from today")
        ForEach(0..<3, id: \.self) { i in
            gratitudeField(text: $day.eveningWins[i], placeholder: "Good thing \(i + 1)")
        }
        Divider().background(Brand.hairline)
        Eyebrow(text: "One thing that could improve")
        gratitudeField(text: $day.improvement, placeholder: "Tomorrow I could…")
        Divider().background(Brand.hairline)
        Eyebrow(text: "How was your mood?")
        moodPicker
    }

    private func promptHeader(_ prompt: String, _ title: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.title3.weight(.semibold)).foregroundStyle(Brand.text)
            if !prompt.isEmpty {
                Text(prompt).font(.subheadline).foregroundStyle(Brand.text2)
            }
        }
    }

    private func gratitudeField(text: Binding<String>, placeholder: String) -> some View {
        TextField(placeholder, text: text, axis: .vertical)
            .lineLimit(1...4)
            .foregroundStyle(Brand.text)
            .padding(14)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Brand.glassStroke.opacity(0.45), lineWidth: 1))
            .onChange(of: text.wrappedValue) { _, _ in day.updatedAt = .now }
    }

    private var moodPicker: some View {
        HStack(spacing: 10) {
            ForEach(Mood.allCases) { mood in
                Button {
                    day.mood = mood.rawValue
                    Haptics.selection()
                } label: {
                    VStack(spacing: 4) {
                        Text(mood.emoji).font(.title2)
                        Text(mood.label).font(Brand.mono(10)).foregroundStyle(Brand.text3)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(day.mood == mood.rawValue ? mood.color.opacity(0.2) : Color.clear,
                                in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(day.mood == mood.rawValue ? mood.color : Brand.glassStroke.opacity(0.4),
                                      lineWidth: day.mood == mood.rawValue ? 2 : 1))
                }
                .accessibilityLabel(mood.label)
                .accessibilityAddTraits(day.mood == mood.rawValue ? .isSelected : [])
            }
        }
    }

    private func save() {
        day.updatedAt = .now
        try? context.save()
    }

    private func complete() {
        if phase == .morning { day.morningDone = true } else { day.eveningDone = true }
        day.updatedAt = .now
        try? context.save()
        Haptics.success()
    }
}

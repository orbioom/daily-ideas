import SwiftUI
import SwiftData

/// A lightweight bottom sheet that lets the user pick a diaper type and log it
/// instantly (endTime == startTime) with a single tap.
struct DiaperQuickSheet: View {
    var baby: Baby?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var selectedType: DiaperType = .wet
    @State private var loggedAt: Date = Date()

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground

                VStack(spacing: 24) {
                    Spacer(minLength: 8)

                    // Type selector
                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Eyebrow(text: "Diaper type")

                            HStack(spacing: 12) {
                                ForEach(DiaperType.allCases, id: \.self) { type in
                                    Button {
                                        Haptics.selection()
                                        selectedType = type
                                    } label: {
                                        VStack(spacing: 8) {
                                            ZStack {
                                                Circle()
                                                    .fill(selectedType == type
                                                          ? EventKind.diaper.color.opacity(0.2)
                                                          : Color.clear)
                                                    .frame(width: 52, height: 52)
                                                Circle()
                                                    .strokeBorder(
                                                        selectedType == type
                                                            ? EventKind.diaper.color.opacity(0.6)
                                                            : Brand.hairline,
                                                        lineWidth: selectedType == type ? 1.5 : 1
                                                    )
                                                    .frame(width: 52, height: 52)
                                                Image(systemName: type.symbol)
                                                    .font(.system(size: 20, weight: .semibold))
                                                    .foregroundStyle(
                                                        selectedType == type
                                                            ? EventKind.diaper.color
                                                            : Brand.text2
                                                    )
                                                    .accessibilityHidden(true)
                                            }
                                            Text(type.label)
                                                .font(.caption.weight(.medium))
                                                .foregroundStyle(
                                                    selectedType == type ? Brand.text : Brand.text2
                                                )
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                    .accessibilityLabel(type.label)
                                    .accessibilityAddTraits(selectedType == type ? .isSelected : [])
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // Time
                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Eyebrow(text: "Time")
                            DatePicker(
                                "Logged at",
                                selection: $loggedAt,
                                in: ...Date(),
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .datePickerStyle(.compact)
                            .foregroundStyle(Brand.text)
                            .accessibilityLabel("Time logged")
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer()

                    Button("Log Diaper") {
                        logDiaper()
                    }
                    .buttonStyle(InkButtonStyle())
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Diaper")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        Haptics.tap()
                        dismiss()
                    }
                }
            }
        }
    }

    private func logDiaper() {
        guard let babyRef = baby else { return }
        let event = CareEvent(
            kind: .diaper,
            startTime: loggedAt,
            endTime: loggedAt,
            diaperType: selectedType,
            baby: babyRef
        )
        context.insert(event)
        babyRef.events.append(event)
        Haptics.success()
        dismiss()
    }
}

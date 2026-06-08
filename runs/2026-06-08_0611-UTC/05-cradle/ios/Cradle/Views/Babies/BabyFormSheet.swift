import SwiftUI
import SwiftData

/// Add or edit a Baby profile.
struct BabyFormSheet: View {
    var existingBaby: Baby?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Baby.order) private var babies: [Baby]

    @State private var name = ""
    @State private var birthDate = Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date()
    @State private var sex: Sex = .unspecified
    @State private var symbol = "star.fill"
    @State private var colorHex: UInt32 = 0x4E6BA8
    @State private var validationError: String? = nil

    private var isEditing: Bool { existingBaby != nil }

    private let symbolOptions = [
        "star.fill", "moon.fill", "heart.fill", "sun.max.fill",
        "leaf.fill", "sparkles", "pawprint.fill", "hare.fill",
        "bird.fill", "cloud.fill", "snowflake", "flame.fill"
    ]

    private let colorOptions: [UInt32] = [
        0x4E6BA8, 0xC0553E, 0x4FB98C, 0xC08A3E,
        0x8B5CF6, 0xEC4899, 0x10B981, 0xF59E0B,
        0x3B82F6, 0xEF4444, 0x6366F1, 0x14B8A6
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground

                ScrollView {
                    VStack(spacing: 20) {
                        // Avatar preview
                        avatarPreview
                            .padding(.top, 16)

                        // Name + birth date
                        GlassCard {
                            VStack(alignment: .leading, spacing: 14) {
                                Eyebrow(text: "Profile")

                                TextField("Baby's name", text: $name)
                                    .font(.body)
                                    .foregroundStyle(Brand.text)
                                    .accessibilityLabel("Baby's name")

                                Divider().foregroundStyle(Brand.hairline)

                                DatePicker(
                                    "Birth date",
                                    selection: $birthDate,
                                    in: ...Date(),
                                    displayedComponents: .date
                                )
                                .datePickerStyle(.compact)
                                .foregroundStyle(Brand.text)
                                .accessibilityLabel("Birth date")

                                Divider().foregroundStyle(Brand.hairline)

                                Picker("Sex", selection: $sex) {
                                    ForEach(Sex.allCases, id: \.self) { s in
                                        Text(s.label).tag(s)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .accessibilityLabel("Sex")
                            }
                        }
                        .padding(.horizontal, 20)

                        // Symbol picker
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Eyebrow(text: "Icon")
                                LazyVGrid(
                                    columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 6),
                                    spacing: 12
                                ) {
                                    ForEach(symbolOptions, id: \.self) { sym in
                                        Button {
                                            Haptics.selection()
                                            symbol = sym
                                        } label: {
                                            ZStack {
                                                Circle()
                                                    .fill(symbol == sym
                                                          ? Color(hex: colorHex).opacity(0.2)
                                                          : Brand.hairline.opacity(0.5))
                                                    .frame(width: 42, height: 42)
                                                Circle()
                                                    .strokeBorder(
                                                        symbol == sym
                                                            ? Color(hex: colorHex).opacity(0.6)
                                                            : Color.clear,
                                                        lineWidth: 2
                                                    )
                                                    .frame(width: 42, height: 42)
                                                Image(systemName: sym)
                                                    .font(.system(size: 16, weight: .semibold))
                                                    .foregroundStyle(
                                                        symbol == sym
                                                            ? Color(hex: colorHex)
                                                            : Brand.text2
                                                    )
                                                    .accessibilityHidden(true)
                                            }
                                        }
                                        .accessibilityLabel(sym.replacingOccurrences(of: ".fill", with: ""))
                                        .accessibilityAddTraits(symbol == sym ? .isSelected : [])
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        // Color picker
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Eyebrow(text: "Color")
                                LazyVGrid(
                                    columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6),
                                    spacing: 10
                                ) {
                                    ForEach(colorOptions, id: \.self) { hex in
                                        Button {
                                            Haptics.selection()
                                            colorHex = hex
                                        } label: {
                                            ZStack {
                                                Circle()
                                                    .fill(Color(hex: hex))
                                                    .frame(width: 36, height: 36)
                                                if colorHex == hex {
                                                    Image(systemName: "checkmark")
                                                        .font(.system(size: 12, weight: .bold))
                                                        .foregroundStyle(.white)
                                                }
                                            }
                                        }
                                        .accessibilityLabel("Color option")
                                        .accessibilityAddTraits(colorHex == hex ? .isSelected : [])
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        // Validation error
                        if let err = validationError {
                            Text(err)
                                .font(.caption)
                                .foregroundStyle(Brand.danger)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 20)
                                .accessibilityLabel("Error: \(err)")
                        }

                        // Save
                        Button(isEditing ? "Save Changes" : "Add Baby") {
                            save()
                        }
                        .buttonStyle(InkButtonStyle())
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Baby" : "New Baby")
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
        .onAppear { prepopulate() }
    }

    // MARK: - Avatar Preview

    @ViewBuilder
    private var avatarPreview: some View {
        ZStack {
            Circle()
                .fill(Color(hex: colorHex).opacity(0.15))
                .frame(width: 80, height: 80)
            Circle()
                .strokeBorder(Color(hex: colorHex).opacity(0.4), lineWidth: 2)
                .frame(width: 80, height: 80)
            Image(systemName: symbol)
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(Color(hex: colorHex))
                .accessibilityHidden(true)
        }
        .accessibilityLabel("Baby avatar preview")
    }

    // MARK: - Logic

    private func prepopulate() {
        guard let baby = existingBaby else { return }
        name = baby.name
        birthDate = baby.birthDate
        sex = baby.sex
        symbol = baby.symbol
        colorHex = baby.colorHex
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            validationError = "Please enter a name."
            Haptics.warning()
            return
        }
        guard birthDate <= Date() else {
            validationError = "Birth date cannot be in the future."
            Haptics.warning()
            return
        }

        if let baby = existingBaby {
            baby.name = trimmed
            baby.birthDate = birthDate
            baby.sex = sex
            baby.symbol = symbol
            baby.colorHex = colorHex
        } else {
            let order = babies.count
            let baby = Baby(
                name: trimmed,
                birthDate: birthDate,
                sex: sex,
                symbol: symbol,
                colorHex: colorHex,
                order: order
            )
            context.insert(baby)
        }

        Haptics.success()
        dismiss()
    }
}

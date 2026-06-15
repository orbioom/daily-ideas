import SwiftUI
import SwiftData

/// Create or edit a child. Inserts into SwiftData on save. Validates name + birth date.
struct AddChildView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    /// Existing child to edit; nil for create.
    var existing: Child?
    var isFirstChild: Bool = false
    var onSaved: (Child) -> Void = { _ in }

    @State private var name: String = ""
    @State private var sex: Sex = .male
    @State private var birthDate: Date = Date()
    @State private var colorHex: String = ChildColors.palette[0]
    @State private var showValidation = false

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var isValid: Bool { !trimmedName.isEmpty && birthDate <= Date() }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.words)
                        .accessibilityLabel("Child's name")
                    if showValidation && trimmedName.isEmpty {
                        Label("Please enter a name.", systemImage: "exclamationmark.triangle.fill")
                            .font(Theme.rounded(13)).foregroundStyle(Theme.warn)
                    }
                } header: {
                    Text("Name")
                }

                Section {
                    Picker("Sex", selection: $sex) {
                        ForEach(Sex.allCases) { s in
                            Text(s.title).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Sex")
                } footer: {
                    Text("Used to pick the correct WHO growth reference for percentiles.")
                }

                Section {
                    DatePicker("Birth date",
                               selection: $birthDate,
                               in: ...Date(),
                               displayedComponents: .date)
                    if showValidation && birthDate > Date() {
                        Label("Birth date can't be in the future.", systemImage: "exclamationmark.triangle.fill")
                            .font(Theme.rounded(13)).foregroundStyle(Theme.warn)
                    }
                } header: {
                    Text("Birth date")
                }

                Section {
                    colorPicker
                } header: {
                    Text("Color")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(existing == nil ? (isFirstChild ? "Your first child" : "New child") : "Edit child")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
            .onAppear(perform: loadExisting)
        }
    }

    private var colorPicker: some View {
        HStack(spacing: 14) {
            ForEach(ChildColors.palette, id: \.self) { hex in
                let color = ChildColors.color(hex: hex)
                Button {
                    colorHex = hex
                    Haptics.select(settings.hapticsEnabled)
                } label: {
                    Circle()
                        .fill(color)
                        .frame(width: 30, height: 30)
                        .overlay(
                            Circle().strokeBorder(Theme.ink.opacity(colorHex == hex ? 0.9 : 0), lineWidth: 2)
                                .padding(-3)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Color option")
                .accessibilityAddTraits(colorHex == hex ? .isSelected : [])
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func loadExisting() {
        guard let child = existing else { return }
        name = child.name
        sex = child.sex
        birthDate = child.birthDate
        colorHex = child.colorHex
    }

    private func save() {
        guard isValid else {
            showValidation = true
            Haptics.warn(settings.hapticsEnabled)
            return
        }
        if let child = existing {
            child.name = trimmedName
            child.sexRaw = sex.rawValue
            child.birthDate = birthDate
            child.colorHex = colorHex
            try? context.save()
            Haptics.success(settings.hapticsEnabled)
            onSaved(child)
            dismiss()
        } else {
            let child = Child(name: trimmedName, birthDate: birthDate, sex: sex, colorHex: colorHex)
            context.insert(child)
            try? context.save()
            Haptics.success(settings.hapticsEnabled)
            onSaved(child)
            dismiss()
        }
    }
}

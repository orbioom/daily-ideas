import SwiftUI
import SwiftData

struct ChoreEditorView: View {
    var chore: Chore?
    var kids: [Kid]

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("sprout.symbol") private var symbol = "$"

    @State private var title = ""
    @State private var glyph = "checkmark.circle.fill"
    @State private var assignedKid: Kid?
    @State private var repeatType: ChoreRepeat = .daily
    @State private var weekdays: Set<Int> = []
    @State private var rewardText = ""
    @State private var points = 10
    @State private var isActive = true
    @State private var loaded = false

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && assignedKid != nil &&
        (repeatType != .custom || !weekdays.isEmpty)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Chore") {
                    TextField("Title", text: $title)
                    Picker("Assign to", selection: $assignedKid) {
                        ForEach(kids) { Text($0.name).tag(Optional($0)) }
                    }
                }
                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 14) {
                        ForEach(Glyph.chores, id: \.self) { g in
                            Image(systemName: g).font(.title3).frame(width: 40, height: 40)
                                .foregroundStyle(glyph == g ? .white : Brand.text2)
                                .background(glyph == g ? (assignedKid?.color.color ?? Brand.text) : Color.clear, in: Circle())
                                .onTapGesture { Haptics.selection(); glyph = g }
                                .accessibilityLabel(g)
                                .accessibilityAddTraits(glyph == g ? .isSelected : [])
                        }
                    }
                    .padding(.vertical, 4)
                }
                Section("Schedule") {
                    Picker("Repeat", selection: $repeatType) {
                        ForEach(ChoreRepeat.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    if repeatType == .custom { weekdayPicker }
                }
                Section("Reward") {
                    HStack {
                        Text("Money").foregroundStyle(Brand.text2)
                        Spacer()
                        Text(symbol).foregroundStyle(Brand.text3)
                        TextField("0", text: $rewardText)
                            .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                            .frame(maxWidth: 100).font(Brand.mono(15))
                    }
                    Stepper(value: $points, in: 0...100, step: 5) {
                        Text("\(points) points").font(Brand.mono(14))
                    }
                }
                Section {
                    Toggle("Active", isOn: $isActive)
                    if let chore {
                        Button(role: .destructive) {
                            context.delete(chore); try? context.save(); dismiss()
                        } label: { Text("Delete chore") }
                    }
                }
            }
            .navigationTitle(chore == nil ? "New chore" : "Edit chore")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) { Button("Save") { save() }.disabled(!canSave) }
            }
            .onAppear(perform: load)
        }
    }

    private var weekdayPicker: some View {
        let syms = Calendar.current.shortWeekdaySymbols
        return HStack(spacing: 6) {
            ForEach(1...7, id: \.self) { wd in
                let on = weekdays.contains(wd)
                Button {
                    Haptics.selection()
                    if on { weekdays.remove(wd) } else { weekdays.insert(wd) }
                } label: {
                    Text(String(syms[wd - 1].prefix(1)))
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .background(on ? (assignedKid?.color.color ?? Brand.text).opacity(0.2) : Color.clear, in: Circle())
                        .overlay(Circle().strokeBorder(on ? (assignedKid?.color.color ?? Brand.text) : Brand.hairline, lineWidth: 1))
                        .foregroundStyle(Brand.text)
                }
                .accessibilityLabel(syms[wd - 1])
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        if let chore {
            title = chore.title; glyph = chore.symbol; assignedKid = chore.kid
            repeatType = chore.repeatType; isActive = chore.isActive; points = chore.points
            rewardText = chore.reward > 0 ? (chore.reward == chore.reward.rounded() ? String(Int(chore.reward)) : String(chore.reward)) : ""
            weekdays = Set((1...7).filter { chore.includes(weekday: $0) })
        } else {
            assignedKid = kids.first
        }
    }

    private func save() {
        guard let kid = assignedKid else { return }
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        let reward = max(0, Double(rewardText.replacingOccurrences(of: ",", with: ".")) ?? 0)
        let mask = repeatType == .custom ? weekdays.reduce(0) { $0 | (1 << ($1 - 1)) } : 0
        if let chore {
            chore.title = trimmed; chore.symbol = glyph; chore.kid = kid
            chore.repeatType = repeatType; chore.weekdaysMask = mask
            chore.reward = reward; chore.points = points; chore.isActive = isActive
        } else {
            let new = Chore(title: trimmed, symbol: glyph, reward: reward, points: points,
                            repeatType: repeatType, weekdaysMask: mask, sortIndex: kid.chores.count)
            new.isActive = isActive
            new.kid = kid
            context.insert(new)
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}

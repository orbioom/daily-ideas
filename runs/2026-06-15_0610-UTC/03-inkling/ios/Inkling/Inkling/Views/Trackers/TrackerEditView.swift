import SwiftUI
import SwiftData

/// Create or edit a tracker. `tracker == nil` means create. Validates the name, and gates the
/// extended symbol/color palette behind Pro (the basic set is always free).
struct TrackerEditView: View {
    let tracker: Tracker?
    let nextSortOrder: Int

    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var kind: TrackerKind = .symptom
    @State private var scale: ScaleType = .severity
    @State private var unit = ""
    @State private var colorHex = "7C5CFF"
    @State private var symbol = "bolt.heart"
    @State private var isActive = true
    @State private var paywallReason: PaywallReason?

    private var isNew: Bool { tracker == nil }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSave: Bool { !trimmedName.isEmpty }

    // Free palette + extended (Pro) palette.
    private let freeColors = ["7C5CFF", "E0584F", "37A2B8", "47B27A", "F0A93B", "5A5470"]
    private let proColors = ["B0588F", "9C6B3C", "4C6EF5", "C7506A", "1F9D6B", "8A7CC2", "D08A2E", "5BB5C9"]

    private let freeSymbols = ["bolt.heart", "face.smiling", "leaf", "pills", "ruler", "drop", "bed.double", "bolt.fill"]
    private let proSymbols = ["cup.and.saucer", "figure.walk", "iphone", "wind", "cloud.fog", "heart", "fork.knife",
                              "moon.stars", "sun.max", "brain.head.profile", "lungs", "thermometer.medium"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Migraine, Coffee, Sleep", text: $name)
                        .font(Theme.rounded(16))
                }

                Section("Kind") {
                    Picker("Kind", selection: $kind) {
                        ForEach(TrackerKind.allCases) { k in
                            Label(k.title, systemImage: k.symbol).tag(k)
                        }
                    }
                    .pickerStyle(.menu)
                    Text(kind.isOutcome
                         ? "Outcomes are what you want to explain (symptoms, mood)."
                         : "Factors are possible causes (caffeine, sleep, meds).")
                        .font(Theme.rounded(12)).foregroundStyle(Theme.inkSoft)
                }

                Section("Scale") {
                    Picker("Scale", selection: $scale) {
                        ForEach(ScaleType.allCases) { s in
                            Text(s.title).tag(s)
                        }
                    }
                    .pickerStyle(.menu)
                    Text(scale.blurb).font(Theme.rounded(12)).foregroundStyle(Theme.inkSoft)
                    if scale == .numeric || scale == .count {
                        TextField("Unit (optional, e.g. hrs, cups)", text: $unit)
                            .font(Theme.rounded(15))
                    }
                }

                Section("Color") {
                    swatchGrid(colors: freeColors, locked: false)
                    if isPro {
                        swatchGrid(colors: proColors, locked: false)
                    } else {
                        Button {
                            paywallReason = .general
                        } label: {
                            Label("More colors with Inkling Pro", systemImage: "lock.fill")
                                .font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
                        }
                    }
                }

                Section("Symbol") {
                    symbolGrid(symbols: freeSymbols)
                    if isPro {
                        symbolGrid(symbols: proSymbols)
                    } else {
                        Button {
                            paywallReason = .general
                        } label: {
                            Label("More symbols with Inkling Pro", systemImage: "lock.fill")
                                .font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
                        }
                    }
                }

                Section {
                    Toggle("Active (show on Today)", isOn: $isActive)
                        .tint(Theme.accent)
                }

                if !isNew {
                    Section {
                        previewRow
                    } header: {
                        Text("Preview")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(isNew ? "New Tracker" : "Edit Tracker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
            .onAppear(perform: loadExisting)
        }
    }

    private var previewRow: some View {
        HStack(spacing: 12) {
            TrackerIcon(symbol: symbol, color: Color(hex: UInt(colorHex, radix: 16) ?? 0x7C5CFF))
            Text(trimmedName.isEmpty ? "Tracker name" : trimmedName)
                .font(Theme.rounded(16, .semibold))
                .foregroundStyle(trimmedName.isEmpty ? Theme.inkFaint : Theme.ink)
            Spacer()
        }
    }

    private func swatchGrid(colors: [String], locked: Bool) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6), spacing: 10) {
            ForEach(colors, id: \.self) { hex in
                let isSel = hex == colorHex
                Circle()
                    .fill(Color(hex: UInt(hex, radix: 16) ?? 0x7C5CFF))
                    .frame(width: 34, height: 34)
                    .overlay(
                        Circle().strokeBorder(Theme.ink, lineWidth: isSel ? 2.5 : 0)
                    )
                    .onTapGesture {
                        colorHex = hex
                        Haptics.select(settings.hapticsEnabled)
                    }
                    .accessibilityLabel("Color option")
                    .accessibilityValue(isSel ? "Selected" : "")
            }
        }
        .padding(.vertical, 4)
    }

    private func symbolGrid(symbols: [String]) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6), spacing: 10) {
            ForEach(symbols, id: \.self) { sym in
                let isSel = sym == symbol
                Image(systemName: sym)
                    .font(.system(size: 18))
                    .frame(width: 38, height: 38)
                    .foregroundStyle(isSel ? .white : Theme.ink)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(isSel ? Theme.accent : Theme.surfaceAlt)
                    )
                    .onTapGesture {
                        symbol = sym
                        Haptics.select(settings.hapticsEnabled)
                    }
                    .accessibilityLabel("Symbol option")
                    .accessibilityValue(isSel ? "Selected" : "")
            }
        }
        .padding(.vertical, 4)
    }

    private func loadExisting() {
        guard let tracker else { return }
        name = tracker.name
        kind = tracker.kind
        scale = tracker.scaleType
        unit = tracker.unit ?? ""
        colorHex = tracker.colorHex
        symbol = tracker.symbolName
        isActive = tracker.isActive
    }

    private func save() {
        guard canSave else { return }
        let cleanUnit = unit.trimmingCharacters(in: .whitespaces)
        let unitValue = cleanUnit.isEmpty ? nil : cleanUnit

        if let tracker {
            tracker.name = trimmedName
            tracker.kind = kind
            tracker.scaleType = scale
            tracker.unit = unitValue
            tracker.colorHex = colorHex
            tracker.symbolName = symbol
            tracker.isActive = isActive
        } else {
            let new = Tracker(name: trimmedName,
                              kind: kind,
                              scaleType: scale,
                              unit: unitValue,
                              colorHex: colorHex,
                              symbolName: symbol,
                              isActive: isActive,
                              sortOrder: nextSortOrder)
            context.insert(new)
        }
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
        dismiss()
    }
}

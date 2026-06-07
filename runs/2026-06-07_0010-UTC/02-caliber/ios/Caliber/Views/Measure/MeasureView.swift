import SwiftUI
import SwiftData

struct MeasureView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("defaultPosition") private var defaultPositionRaw = WatchPosition.onWrist.rawValue

    /// When presented as a sheet for a specific watch.
    var preselected: Watch?

    @Query(sort: \Watch.name) private var watches: [Watch]
    @State private var selectedID: PersistentIdentifier?
    @State private var seconds: Double = 0
    @State private var isFast = true
    @State private var position: WatchPosition = .onWrist
    @State private var timestamp = Date.now
    @State private var savedFlash = false
    @State private var loaded = false

    private var isSheet: Bool { preselected != nil }

    private var selectedWatch: Watch? {
        if let p = preselected { return p }
        return watches.first { $0.persistentModelID == selectedID }
    }

    private var content: some View {
        ZStack {
            Brand.pageBackground
            if watches.isEmpty {
                ScrollView {
                    EmptyStateView(icon: "stopwatch",
                                   title: "No watches to measure",
                                   message: "Add a watch in the Collection tab first, then come back to log a reading.")
                        .padding(.top, 60)
                }
            } else {
                ScrollView {
                    VStack(spacing: 18) {
                        if !isSheet { watchPicker }
                        if let w = selectedWatch { currentCard(w) }
                        readingCard
                        saveButton
                    }
                    .padding(.horizontal, 18).padding(.vertical, 14)
                }
            }
        }
    }

    var body: some View {
        Group {
            if isSheet {
                NavigationStack {
                    content
                        .navigationTitle("Add reading")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
                }
            } else {
                NavigationStack { content.navigationTitle("Measure") }
            }
        }
        .onAppear(perform: load)
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        position = WatchPosition(rawValue: defaultPositionRaw) ?? .onWrist
        if let p = preselected { selectedID = p.persistentModelID }
        else { selectedID = watches.first?.persistentModelID }
    }

    private var watchPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "Watch")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(watches) { w in
                        Button {
                            Haptics.selection(); selectedID = w.persistentModelID
                        } label: {
                            HStack(spacing: 6) {
                                Circle().fill(Color(hex: w.accentHex)).frame(width: 9, height: 9)
                                Text(w.displayName).font(Brand.mono(13, weight: .medium))
                            }
                            .foregroundStyle(selectedID == w.persistentModelID ? .white : Brand.text)
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(selectedID == w.persistentModelID ? AnyShapeStyle(Brand.inkGradient)
                                                                          : AnyShapeStyle(.ultraThinMaterial),
                                        in: Capsule())
                        }
                        .accessibilityLabel("Select \(w.displayName)")
                    }
                }
            }
        }
        .glassCard()
    }

    private func currentCard(_ w: Watch) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(w.displayName).font(.headline).foregroundStyle(Brand.text)
                Text("\(w.measurements.count) reading\(w.measurements.count == 1 ? "" : "s")")
                    .font(.caption).foregroundStyle(Brand.text3)
            }
            Spacer()
            RateBadge(rate: w.dailyRate, grade: w.grade, compact: true)
        }
        .glassCard()
    }

    private var readingCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Reading")
            VStack(spacing: 6) {
                Text(String(format: "%+.0f s", isFast ? seconds : -seconds))
                    .font(Brand.mono(40, weight: .bold))
                    .foregroundStyle(Brand.text)
                    .contentTransition(.numericText())
                Text(isFast ? "watch reading fast" : "watch reading slow")
                    .font(.subheadline).foregroundStyle(Brand.text2)
            }
            .frame(maxWidth: .infinity)

            Slider(value: $seconds, in: 0...60, step: 1).tint(Brand.text)
                .accessibilityLabel("Seconds difference")
                .accessibilityValue("\(Int(seconds)) seconds")

            Picker("Direction", selection: $isFast) {
                Text("Fast (+)").tag(true)
                Text("Slow (−)").tag(false)
            }
            .pickerStyle(.segmented)

            Picker("Position", selection: $position) {
                ForEach(WatchPosition.allCases) { p in Text(p.label).tag(p) }
            }

            DatePicker("When", selection: $timestamp)
                .font(.subheadline)
        }
        .glassCard(padding: 18)
    }

    private var saveButton: some View {
        VStack(spacing: 10) {
            Button {
                save()
            } label: {
                Label(savedFlash ? "Saved" : "Save reading",
                      systemImage: savedFlash ? "checkmark.circle.fill" : "plus.circle")
            }
            .buttonStyle(InkButtonStyle())
            .disabled(selectedWatch == nil)

            if savedFlash {
                Text("Reading logged — rate updated.")
                    .font(.caption).foregroundStyle(Brand.live)
                    .transition(.opacity)
            }
        }
    }

    private func save() {
        guard let w = selectedWatch else { return }
        let m = WatchMeasurement(timestamp: timestamp,
                                 offsetSeconds: isFast ? seconds : -seconds,
                                 position: position)
        m.watch = w
        w.measurements.append(m)
        context.insert(m)
        try? context.save()
        Haptics.success()
        withAnimation(Brand.ease(0.3)) { savedFlash = true }
        if isSheet {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { dismiss() }
        } else {
            seconds = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                withAnimation(Brand.ease(0.3)) { savedFlash = false }
            }
        }
    }
}

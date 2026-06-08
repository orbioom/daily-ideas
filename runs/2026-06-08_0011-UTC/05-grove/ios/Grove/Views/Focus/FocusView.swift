import SwiftUI
import SwiftData

struct FocusView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \FocusTag.order) private var tags: [FocusTag]
    @Query(sort: \FocusSession.date, order: .reverse) private var sessions: [FocusSession]

    @AppStorage("grove.haptics") private var haptics = true
    @AppStorage("grove.strict") private var strict = true
    @AppStorage("grove.lastDuration") private var lastDurationMin = 25
    @AppStorage("grove.selectedTag") private var selectedTag = ""
    @AppStorage("grove.keepAwake") private var keepAwake = true

    enum Phase: Equatable { case setup, running, finished(Bool) }
    @State private var phase: Phase = .setup
    @State private var startDate = Date()
    @State private var plannedSeconds: Double = 1500
    @State private var resultSession: FocusSession?

    private let presets = [15, 25, 45, 60, 90]

    private var currentTag: FocusTag? {
        tags.first { $0.name == selectedTag } ?? tags.first
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                switch phase {
                case .setup: setupView
                case .running: runningView
                case .finished(let success): finishedView(success)
                }
            }
            .navigationTitle("Grove")
            .navigationBarTitleDisplayMode(phase == .setup ? .automatic : .inline)
            .onChange(of: scenePhase) { _, newPhase in
                if case .running = phase, newPhase == .background, strict {
                    fail()
                }
            }
        }
    }

    // MARK: Setup
    private var setupView: some View {
        ScrollView {
            VStack(spacing: 22) {
                TreeView(progress: 0.18, species: TreeSpecies.forDuration(minutes: Double(lastDurationMin)))
                    .frame(height: 180)
                    .padding(.top, 8)

                GlassCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Eyebrow(text: "FOCUS FOR")
                        Text("\(lastDurationMin) min")
                            .font(Brand.mono(34, weight: .semibold)).foregroundStyle(Brand.text)
                        HStack(spacing: 8) {
                            ForEach(presets, id: \.self) { p in
                                Button {
                                    lastDurationMin = p; Haptics.selection()
                                } label: {
                                    Text("\(p)")
                                        .font(.subheadline.weight(.medium))
                                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                                        .background(lastDurationMin == p ? AnyShapeStyle(Brand.inkGradient) : AnyShapeStyle(.ultraThinMaterial),
                                                    in: RoundedRectangle(cornerRadius: 12))
                                        .foregroundStyle(lastDurationMin == p ? .white : Brand.text)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("\(p) minutes")
                            }
                        }
                        Slider(value: Binding(get: { Double(lastDurationMin) },
                                              set: { lastDurationMin = Int($0) }),
                               in: 5...120, step: 5)
                            .tint(Brand.live)
                        Text("Plants a \(TreeSpecies.forDuration(minutes: Double(lastDurationMin)).name.lowercased()).")
                            .font(.footnote).foregroundStyle(Brand.text3)
                    }
                }

                tagPicker

                Button {
                    start()
                } label: { Label("Plant tree", systemImage: "leaf.fill") }
                    .buttonStyle(InkButtonStyle())
                    .disabled(currentTag == nil)
            }
            .padding(20)
        }
    }

    private var tagPicker: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Eyebrow(text: "TAG")
                if tags.isEmpty {
                    Text("Add a tag on the Tags tab.").font(.subheadline).foregroundStyle(Brand.text2)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(tags) { tag in
                                let sel = tag.name == (currentTag?.name ?? "")
                                Button { selectedTag = tag.name; Haptics.selection() } label: {
                                    HStack(spacing: 5) {
                                        Image(systemName: tag.symbol).font(.caption)
                                        Text(tag.name).font(.subheadline)
                                    }
                                    .padding(.horizontal, 12).padding(.vertical, 8)
                                    .background(sel ? AnyShapeStyle(Color(hex: tag.colorHex)) : AnyShapeStyle(.ultraThinMaterial), in: Capsule())
                                    .foregroundStyle(sel ? .white : Brand.text)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: Running
    private var runningView: some View {
        TimelineView(.periodic(from: .now, by: 0.25)) { ctx in
            let elapsed = max(0, ctx.date.timeIntervalSince(startDate))
            let progress = min(1, elapsed / plannedSeconds)
            let remaining = max(0, plannedSeconds - elapsed)
            VStack(spacing: 20) {
                Spacer()
                ZStack(alignment: .bottom) {
                    TreeView(progress: reduceMotion ? 1 : progress,
                             species: TreeSpecies.forDuration(minutes: plannedSeconds / 60))
                        .frame(height: 300)
                }
                Text(Format.clock(remaining))
                    .font(Brand.mono(56, weight: .light))
                    .foregroundStyle(Brand.text).monospacedDigit()
                if let tag = currentTag {
                    Label(tag.name, systemImage: tag.symbol)
                        .font(.subheadline).foregroundStyle(Brand.text2)
                }
                Text(strict ? "Leave the app and your tree withers." : "Stay focused.")
                    .font(.footnote).foregroundStyle(Brand.text3)
                Spacer()
                Button(role: .destructive) { fail() } label: {
                    Text("Give up").frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyle())
                .padding(.horizontal, 20).padding(.bottom, 16)
            }
            .padding(.horizontal, 20)
            .onChange(of: ctx.date) { _, _ in
                if case .running = phase, elapsed >= plannedSeconds { complete() }
            }
        }
    }

    // MARK: Finished
    private func finishedView(_ success: Bool) -> some View {
        VStack(spacing: 22) {
            Spacer()
            TreeView(progress: success ? 1 : 0.6,
                     species: TreeSpecies.forDuration(minutes: plannedSeconds / 60),
                     withered: !success)
                .frame(height: 240)
            Text(success ? "Tree planted" : "It withered")
                .font(.title.weight(.bold)).foregroundStyle(Brand.text)
            Text(success
                 ? "\(Format.minutes(plannedSeconds / 60)) of focus added to your grove."
                 : "You left before the timer finished. Try a shorter block next time.")
                .font(.subheadline).foregroundStyle(Brand.text2)
                .multilineTextAlignment(.center).padding(.horizontal, 30)
            Spacer()
            Button("Done") { phase = .setup }
                .buttonStyle(InkButtonStyle()).padding(.horizontal, 40)
            Button("Focus again") { start() }
                .buttonStyle(GlassButtonStyle()).padding(.horizontal, 40).padding(.bottom, 16)
        }
        .padding(20)
    }

    // MARK: Logic
    private func start() {
        plannedSeconds = Double(lastDurationMin) * 60
        startDate = Date()
        phase = .running
        if keepAwake { UIApplication.shared.isIdleTimerDisabled = true }
        if haptics { Haptics.tap() }
    }

    private func complete() {
        guard case .running = phase else { return }
        UIApplication.shared.isIdleTimerDisabled = false
        let species = TreeSpecies.forDuration(minutes: plannedSeconds / 60).rawValue
        let s = FocusSession(date: startDate, plannedSeconds: plannedSeconds,
                             completedSeconds: plannedSeconds, success: true,
                             tagName: currentTag?.name ?? "Focus", species: species)
        context.insert(s); try? context.save()
        resultSession = s
        if haptics { Haptics.success() }
        phase = .finished(true)
    }

    private func fail() {
        guard case .running = phase else { return }
        UIApplication.shared.isIdleTimerDisabled = false
        let elapsed = max(0, Date().timeIntervalSince(startDate))
        let species = TreeSpecies.forDuration(minutes: plannedSeconds / 60).rawValue
        let s = FocusSession(date: startDate, plannedSeconds: plannedSeconds,
                             completedSeconds: min(elapsed, plannedSeconds), success: false,
                             tagName: currentTag?.name ?? "Focus", species: species)
        context.insert(s); try? context.save()
        if haptics { Haptics.warning() }
        phase = .finished(false)
    }
}

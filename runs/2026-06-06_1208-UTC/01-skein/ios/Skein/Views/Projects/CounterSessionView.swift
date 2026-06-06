import SwiftUI
import SwiftData
import UIKit

/// Full-screen, low-friction counting. A huge tap zone increments the active
/// counter; a segmented control switches between the project's counters.
struct CounterSessionView: View {
    @Bindable var project: Project
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("keepAwake") private var keepAwake = true

    @State private var activeID: UUID?
    @State private var pulse = false

    private var counters: [Counter] { project.orderedCounters }
    private var active: Counter? {
        counters.first { $0.id == activeID } ?? counters.first
    }

    var body: some View {
        ZStack {
            Brand.pageBackground
            VStack(spacing: 20) {
                topBar
                if counters.count > 1 { picker }
                Spacer(minLength: 0)
                if let counter = active {
                    counterFace(counter)
                } else {
                    EmptyStateView(icon: "number.circle", title: "No counters",
                                   message: "Add a counter to start.")
                }
                Spacer(minLength: 0)
                if let counter = active { controls(counter) }
            }
            .padding(20)
        }
        .onAppear {
            activeID = counters.first?.id
            UIApplication.shared.isIdleTimerDisabled = keepAwake
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            try? context.save()
        }
    }

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Label("Done", systemImage: "chevron.down").labelStyle(.titleAndIcon)
            }
            .foregroundStyle(Brand.text2)
            Spacer()
            Text(project.name).font(.headline).foregroundStyle(Brand.text).lineLimit(1)
            Spacer()
            // Balance the leading button width.
            Label("Done", systemImage: "chevron.down").labelStyle(.titleAndIcon).opacity(0)
                .accessibilityHidden(true)
        }
    }

    private var picker: some View {
        Picker("Active counter", selection: Binding(
            get: { active?.id ?? counters.first?.id ?? UUID() },
            set: { activeID = $0; Haptics.selection() })) {
            ForEach(counters) { Text($0.name).tag($0.id) }
        }
        .pickerStyle(.segmented)
    }

    private func counterFace(_ counter: Counter) -> some View {
        VStack(spacing: 18) {
            Text(counter.name.uppercased())
                .font(Brand.mono(13, weight: .medium)).tracking(1.5)
                .foregroundStyle(Brand.text3)

            // Large tappable count.
            Button { bump(counter, by: counter.step) } label: {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(Circle().strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: 1))
                    if counter.tracksRepeat {
                        Circle()
                            .trim(from: 0, to: counter.repeatProgress)
                            .stroke(Brand.live, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .padding(10)
                            .animation(reduceMotion ? nil : Brand.ease(0.4), value: counter.value)
                    }
                    VStack(spacing: 4) {
                        Text("\(counter.value)")
                            .font(Brand.mono(72, weight: .bold))
                            .foregroundStyle(Brand.text)
                            .contentTransition(.numericText(value: Double(counter.value)))
                        Text("tap to count")
                            .font(.caption).foregroundStyle(Brand.text3)
                    }
                }
                .frame(width: 250, height: 250)
                .scaleEffect(pulse && !reduceMotion ? 1.03 : 1)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(counter.name), count \(counter.value)")
            .accessibilityHint("Double tap to add \(counter.step)")

            if counter.tracksRepeat, let pos = counter.repeatPosition, let rep = counter.repeatNumber {
                HStack(spacing: 8) {
                    StatusDot(color: Brand.live)
                    Text("Repeat \(rep) — step \(pos) of \(counter.repeatLength)")
                        .font(.subheadline).foregroundStyle(Brand.text2)
                }
            }
        }
    }

    private func controls(_ counter: Counter) -> some View {
        HStack(spacing: 14) {
            Button { bump(counter, by: -counter.step) } label: {
                Image(systemName: "minus").font(.title3.weight(.semibold)).frame(maxWidth: .infinity)
            }
            .buttonStyle(GlassButtonStyle())
            .disabled(counter.value == 0)

            Button { resetCounter(counter) } label: {
                Image(systemName: "arrow.counterclockwise").font(.title3).frame(maxWidth: .infinity)
            }
            .buttonStyle(GlassButtonStyle())
            .disabled(counter.value == 0)
            .accessibilityLabel("Reset counter")

            Button { bump(counter, by: counter.step) } label: {
                Image(systemName: "plus").font(.title3.weight(.semibold)).frame(maxWidth: .infinity)
            }
            .buttonStyle(InkButtonStyle())
        }
    }

    private func bump(_ counter: Counter, by delta: Int) {
        if delta >= 0 { counter.increment() } else { counter.decrement() }
        project.updatedAt = Date()
        Haptics.tap()
        if !reduceMotion {
            withAnimation(Brand.ease(0.15)) { pulse = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
                withAnimation(Brand.ease(0.2)) { pulse = false }
            }
        }
    }

    private func resetCounter(_ counter: Counter) {
        counter.value = 0
        project.updatedAt = Date()
        Haptics.warning()
    }
}

import SwiftUI
import SwiftData

struct TimerView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("useMetric") private var useMetric = true
    @Query(sort: \Cook.startedAt, order: .reverse) private var cooks: [Cook]

    private var active: [Cook] { cooks.filter { $0.state == .cooking } }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if active.isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "timer",
                                       title: "No cook running",
                                       message: "Start a cook from the Calculate tab and it counts down here — even if you close the app.")
                            .padding(.top, 60)
                    }
                } else {
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        ScrollView {
                            VStack(spacing: 18) {
                                ForEach(active) { cook in
                                    ActiveCookCard(cook: cook, now: context.date, useMetric: useMetric,
                                                   onDone: { markDone(cook) }, onCancel: { cancel(cook) })
                                }
                            }
                            .padding(.horizontal, 18).padding(.vertical, 14)
                        }
                    }
                }
            }
            .navigationTitle("Timer")
        }
    }

    private func markDone(_ cook: Cook) {
        cook.state = .done
        try? context.save()
        Haptics.success()
    }

    private func cancel(_ cook: Cook) {
        context.delete(cook)
        try? context.save()
        Haptics.tap()
    }
}

struct ActiveCookCard: View {
    let cook: Cook
    let now: Date
    let useMetric: Bool
    var onDone: () -> Void
    var onCancel: () -> Void

    private var remaining: Double { cook.secondsRemaining(now: now) }
    private var ready: Bool { remaining <= 0 }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(cook.foodName).font(.headline).foregroundStyle(Brand.text)
                    Text("\(Int(cook.thicknessMM)) mm · \(TempFmt.temp(cook.bathC, metric: useMetric))")
                        .font(.caption).foregroundStyle(Brand.text3)
                }
                Spacer()
                if ready {
                    Chip(text: "Ready", system: "checkmark.circle.fill", tint: Brand.live)
                } else {
                    Chip(text: "Cooking", system: "flame", tint: Brand.warn)
                }
            }

            CookRing(progress: cook.progress(now: now),
                     centerTop: ready ? "Done" : Fmt.clockRemaining(remaining),
                     centerBottom: ready ? "READY" : "REMAINING",
                     tint: ready ? Brand.live : Brand.warn)
                .frame(width: 190, height: 190)
                .padding(.vertical, 4)

            HStack(spacing: 12) {
                infoPill("Come-up", TempFmt.duration(cook.comeUpMinutes))
                if cook.pasteurizeMinutes > 0 {
                    infoPill("Hold", TempFmt.duration(cook.pasteurizeMinutes))
                }
                infoPill("Ready at", cook.readyAt.formatted(.dateTime.hour().minute()))
            }

            HStack(spacing: 12) {
                Button(role: .destructive, action: onCancel) {
                    Label("Cancel", systemImage: "xmark")
                }
                .buttonStyle(GlassButtonStyle())
                Button(action: onDone) {
                    Label(ready ? "Pull it out" : "Mark done", systemImage: "checkmark")
                }
                .buttonStyle(InkButtonStyle())
            }
        }
        .glassCard(padding: 20)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(cook.foodName), \(ready ? "ready" : Fmt.clockRemaining(remaining) + " remaining")")
    }

    private func infoPill(_ label: String, _ value: String) -> some View {
        VStack(spacing: 3) {
            Text(value).font(Brand.mono(13, weight: .semibold)).foregroundStyle(Brand.text)
            Text(label.uppercased()).font(Brand.mono(9, weight: .medium)).tracking(0.8)
                .foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

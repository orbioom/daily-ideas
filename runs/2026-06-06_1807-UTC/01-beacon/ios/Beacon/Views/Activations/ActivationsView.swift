import SwiftUI
import SwiftData

struct ActivationsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Activation.date, order: .reverse) private var activations: [Activation]
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if activations.isEmpty {
                    EmptyStateView(icon: "map",
                                   title: "No outings yet",
                                   message: "Create a POTA park, SOTA summit, or contest session to group your contacts.")
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(activations) { a in
                                NavigationLink(value: a) { ActivationRow(activation: a) }
                                    .buttonStyle(.plain)
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Outings")
            .navigationDestination(for: Activation.self) { ActivationDetailView(activation: $0) }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Haptics.tap(); showAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("New outing")
                }
            }
            .sheet(isPresented: $showAdd) { ActivationEditView(activation: nil) }
        }
    }
}

private struct ActivationRow: View {
    let activation: Activation
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: activation.kind.icon).font(.title3).foregroundStyle(Brand.text)
                    .frame(width: 28).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(activation.title).font(.headline).foregroundStyle(Brand.text)
                    HStack(spacing: 6) {
                        Chip(text: activation.kind.rawValue)
                        if !activation.reference.isEmpty { Chip(text: activation.reference) }
                    }
                }
                Spacer()
                if activation.kind == .pota {
                    if activation.isActivated {
                        Label("Activated", systemImage: "checkmark.seal.fill")
                            .labelStyle(.iconOnly).font(.title3).foregroundStyle(Brand.live)
                            .accessibilityLabel("Activated")
                    }
                }
            }
            HStack {
                Text("\(activation.qsoCount) contacts").font(Brand.mono(13)).foregroundStyle(Brand.text2)
                Spacer()
                Text(activation.date, format: .dateTime.month().day().year())
                    .font(Brand.mono(12)).foregroundStyle(Brand.text3)
            }
            if activation.kind.qsoTarget > 0 {
                ProgressBar(value: Double(activation.qsoCount), target: Double(activation.kind.qsoTarget))
            }
        }
        .glassCard()
    }
}

/// A thin progress bar toward an activation target.
struct ProgressBar: View {
    let value: Double
    let target: Double
    var body: some View {
        let frac = target > 0 ? min(1, value / target) : 0
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Brand.hairline).frame(height: 6)
                Capsule().fill(frac >= 1 ? Brand.live : Brand.info)
                    .frame(width: max(6, geo.size.width * frac), height: 6)
            }
        }
        .frame(height: 6)
        .accessibilityLabel("Progress \(Int(value)) of \(Int(target))")
    }
}

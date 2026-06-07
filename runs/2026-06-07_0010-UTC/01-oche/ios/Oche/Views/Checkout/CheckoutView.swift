import SwiftUI

struct CheckoutView: View {
    @AppStorage("showAlternateRoutes") private var showAlternateRoutes = true
    @State private var score = 170
    @State private var dartsInHand = 3
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var routes: [[Dart]] {
        CheckoutEngine.alternativeCheckouts(score, darts: dartsInHand,
                                            limit: showAlternateRoutes ? 3 : 1)
    }
    private var primary: [Dart]? { routes.first }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(spacing: 18) {
                        scoreCard
                        resultCard
                        chartLink
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                }
            }
            .navigationTitle("Checkout")
        }
    }

    private var scoreCard: some View {
        VStack(spacing: 16) {
            HStack {
                Eyebrow(text: "Score remaining")
                Spacer()
                Text("\(score)")
                    .font(Brand.mono(34, weight: .bold))
                    .foregroundStyle(Brand.text)
                    .contentTransition(.numericText())
                    .accessibilityLabel("Score remaining \(score)")
            }
            stepperRow
            quickPresets
            Picker("Darts in hand", selection: $dartsInHand) {
                Text("1 dart").tag(1)
                Text("2 darts").tag(2)
                Text("3 darts").tag(3)
            }
            .pickerStyle(.segmented)
            .onChange(of: dartsInHand) { _, _ in Haptics.selection() }
        }
        .glassCard(padding: 18)
    }

    private var stepperRow: some View {
        HStack(spacing: 12) {
            stepButton("-10") { adjust(-10) }
            stepButton("-1") { adjust(-1) }
            Slider(value: Binding(
                get: { Double(score) },
                set: { score = min(170, max(2, Int($0.rounded()))) }
            ), in: 2...170, step: 1)
            .tint(Brand.text)
            .accessibilityLabel("Score slider")
            .accessibilityValue("\(score)")
            stepButton("+1") { adjust(1) }
            stepButton("+10") { adjust(10) }
        }
    }

    private func stepButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: { Haptics.tap(); action() }) {
            Text(label).font(Brand.mono(13, weight: .semibold))
                .foregroundStyle(Brand.text)
                .frame(width: 42, height: 34)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(Brand.hairline, lineWidth: 1))
        }
        .accessibilityLabel(label.hasPrefix("-") ? "decrease \(label.dropFirst())" : "increase \(label.dropFirst())")
    }

    private var quickPresets: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach([170, 167, 164, 161, 160, 132, 121, 100, 81, 40], id: \.self) { v in
                    Button {
                        Haptics.selection()
                        withAnimation(reduceMotion ? nil : Brand.ease(0.3)) { score = v }
                    } label: {
                        Text("\(v)").font(Brand.mono(13, weight: .medium))
                            .foregroundStyle(score == v ? .white : Brand.text)
                            .padding(.horizontal, 12).padding(.vertical, 7)
                            .background(score == v ? AnyShapeStyle(Brand.inkGradient)
                                                   : AnyShapeStyle(.ultraThinMaterial),
                                        in: Capsule())
                    }
                    .accessibilityLabel("Set score \(v)")
                }
            }
            .padding(.horizontal, 2)
        }
    }

    @ViewBuilder
    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Recommended finish")
            if let primary {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .center) {
                        RouteView(route: primary)
                        Spacer()
                    }
                    HStack(spacing: 8) {
                        Chip(text: "\(primary.count) dart\(primary.count == 1 ? "" : "s")", system: "scope")
                        Chip(text: "ends on \(primary.last?.label ?? "")",
                             system: "checkmark.circle", tint: Brand.live)
                    }
                }
                .glassCard(padding: 16)

                if showAlternateRoutes && routes.count > 1 {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "Other routes")
                        ForEach(Array(routes.dropFirst().enumerated()), id: \.offset) { _, r in
                            RouteView(route: r).glassCard(padding: 12)
                        }
                    }
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "xmark.octagon")
                        .font(.system(size: 34, weight: .light))
                        .foregroundStyle(Brand.warn)
                        .accessibilityHidden(true)
                    Text(bogeyMessage)
                        .font(.subheadline).foregroundStyle(Brand.text2)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .glassCard(padding: 22)
            }
        }
    }

    private var bogeyMessage: String {
        if dartsInHand < 3 {
            return "No finish from \(score) with \(dartsInHand) dart\(dartsInHand == 1 ? "" : "s"). Score down and set up a double."
        }
        return "\(score) is a bogey number — it can't be checked out in three darts. Leave yourself a finishable score."
    }

    private var chartLink: some View {
        NavigationLink {
            CheckoutChartView()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Full checkout chart").font(.headline).foregroundStyle(Brand.text)
                    Text("Every finish from 170 down to 2").font(.footnote).foregroundStyle(Brand.text2)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Brand.text3)
            }
            .glassCard()
        }
        .buttonStyle(.plain)
    }

    private func adjust(_ delta: Int) {
        score = min(170, max(2, score + delta))
    }
}

/// A scrollable reference chart of every checkout.
struct CheckoutChartView: View {
    private let scores = Array((2...170).reversed())

    var body: some View {
        ZStack {
            Brand.pageBackground
            List {
                ForEach(scores, id: \.self) { s in
                    if let route = CheckoutEngine.bestCheckout(s, darts: 3) {
                        HStack {
                            Text("\(s)")
                                .font(Brand.mono(16, weight: .semibold))
                                .foregroundStyle(Brand.text)
                                .frame(width: 44, alignment: .leading)
                            Text(CheckoutEngine.routeLabel(route))
                                .font(Brand.mono(15))
                                .foregroundStyle(Brand.text2)
                            Spacer()
                        }
                        .listRowBackground(Color.clear)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(s): " + route.map(\.spoken).joined(separator: ", "))
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Checkout chart")
        .navigationBarTitleDisplayMode(.inline)
    }
}

import SwiftUI
import SwiftData

/// All parameters with their latest value, status, and a sparkline.
struct ParametersView: View {
    @Bindable var tank: Tank
    @AppStorage("tempFahrenheit") private var tempF = false
    @AppStorage("salinitySG") private var salSG = false

    private var units: Units { Units(tempFahrenheit: tempF, salinitySG: salSG) }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(WaterParameter.allCases) { p in
                            NavigationLink(value: p) { row(p) }.buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16).padding(.bottom, 28)
                }
            }
            .navigationTitle("Parameters")
            .navigationDestination(for: WaterParameter.self) { p in
                ParameterHistoryView(tank: tank, parameter: p)
            }
        }
    }

    private func row(_ p: WaterParameter) -> some View {
        let latest = tank.latest(p)
        let history = tank.history(p).suffix(12).map { (date: $0.date, value: $0.value) }
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(p.name).font(.headline).foregroundStyle(Brand.text)
                if let latest {
                    HStack(spacing: 6) {
                        Circle().fill(p.status(for: latest.value).tint).frame(width: 8, height: 8)
                        Text("ideal \(Fmt.idealString(p, units)) \(Fmt.unit(p, units))")
                            .font(.caption).foregroundStyle(Brand.text3)
                    }
                } else {
                    Text("No readings").font(.caption).foregroundStyle(Brand.text3)
                }
            }
            Spacer()
            if history.count >= 2 {
                Sparkline(values: Array(history), tint: latest.map { p.status(for: $0.value).tint } ?? Brand.info)
            }
            VStack(alignment: .trailing, spacing: 2) {
                if let latest {
                    Text(Fmt.string(p, latest.value, units, withUnit: false))
                        .font(Brand.mono(18, weight: .semibold)).foregroundStyle(Brand.text)
                    Text(Fmt.unit(p, units)).font(.caption2).foregroundStyle(Brand.text3)
                } else {
                    Text("—").font(Brand.mono(18)).foregroundStyle(Brand.text3)
                }
            }
            Image(systemName: "chevron.right").font(.footnote).foregroundStyle(Brand.text3)
        }
        .glassCard()
    }
}

import SwiftUI

struct ToolsView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    NavigationLink { KickCounterView() } label: {
                        ToolCard(icon: "figure.child",
                                 title: "Kick Counter",
                                 subtitle: "Time how long it takes baby to move 10 times.")
                    }
                    NavigationLink { ContractionTimerView() } label: {
                        ToolCard(icon: "waveform.path.ecg",
                                 title: "Contraction Timer",
                                 subtitle: "Track frequency and duration with the 5-1-1 guide.")
                    }
                }
                .padding()
            }
            .background(Brand.pageBackground)
            .navigationTitle("Tools")
        }
    }
}

private struct ToolCard: View {
    let icon: String
    let title: String
    let subtitle: String
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(Color(hex: 0x9A6FB0).opacity(0.16)).frame(width: 54, height: 54)
                Image(systemName: icon).font(.title2).foregroundStyle(Color(hex: 0x9A6FB0))
            }
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline).foregroundStyle(Brand.text)
                Text(subtitle).font(.caption).foregroundStyle(Brand.text2)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(Brand.text3)
        }
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle)")
    }
}

import SwiftUI

struct ContentView: View {
    @StateObject private var vm = SkyViewModel()

    var body: some View {
        ZStack {
            OrbMistBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    SkyBandView(elevation: vm.elevation, dayLength: vm.dayLength)
                    momentsCard
                    footer
                }
                .padding(20)
            }
        }
        .onAppear { vm.tick() }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("GLOAMING").eyebrow()
                Menu {
                    Button {
                        vm.requestDeviceLocation()
                    } label: { Label("Use current location", systemImage: "location") }
                    Divider()
                    ForEach(Place.presets) { p in
                        Button(p.name) { vm.select(p) }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(vm.place.name)
                            .font(.system(.title, design: .rounded).weight(.bold))
                            .foregroundStyle(Color.orbInk)
                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.orbText3)
                    }
                }
            }
            Spacer()
            if vm.usingDeviceLocation {
                Image(systemName: "location.fill")
                    .foregroundStyle(Color.orbLive)
            }
        }
    }

    private var momentsCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(vm.moments.enumerated()), id: \.element.id) { idx, m in
                MomentRow(moment: m, isCurrent: idx == vm.currentPhaseIndex)
                if idx < vm.moments.count - 1 {
                    Divider().overlay(Color.orbInk.opacity(0.06))
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 6)
        .glassCard()
    }

    private var footer: some View {
        Text("Times computed on-device with the NOAA solar algorithm. No network, no tracking.")
            .font(.caption2)
            .foregroundStyle(Color.orbText3)
            .padding(.top, 4)
    }
}

#Preview {
    ContentView()
}

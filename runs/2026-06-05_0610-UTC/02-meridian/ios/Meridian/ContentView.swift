import SwiftUI

struct ContentView: View {
    @StateObject private var vm = MeetingViewModel()
    @State private var showAdd = false

    var body: some View {
        ZStack {
            OrbMistBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    overlapCard
                    participantsCard
                    workHoursCard
                }
                .padding(20)
            }
        }
        .sheet(isPresented: $showAdd) { AddParticipantSheet(vm: vm) }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("MERIDIAN").eyebrow()
                Text("Find the hour")
                    .font(.system(.title, design: .rounded).weight(.bold))
                    .foregroundStyle(Color.orbInk)
            }
            Spacer()
            Button { showAdd = true } label: {
                Image(systemName: "plus")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(LinearGradient(colors: [Color(red:0.227,green:0.243,blue:0.298),
                                                        Color(red:0.137,green:0.149,blue:0.184)],
                                               startPoint: .top, endPoint: .bottom),
                                in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    private var overlapCard: some View {
        let hours = vm.overlapHours()
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Circle().fill(Color.orbLive).frame(width: 7, height: 7)
                    .shadow(color: Color.orbLive.opacity(0.6), radius: 4)
                Text(hours.isEmpty ? "No shared working hour"
                     : "\(hours.count) overlapping hour\(hours.count == 1 ? "" : "s")")
                    .font(.system(.headline).weight(.semibold))
                    .foregroundStyle(Color.orbInk)
            }
            if let first = hours.first {
                Text("Best start: " + vm.participants.map { p in
                    "\(p.name) \(vm.localTimeString(p, utcHour: first))"
                }.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(Color.orbText2)
            } else {
                Text("Try widening work hours below, or drop a far-flung place.")
                    .font(.caption).foregroundStyle(Color.orbText3)
            }
            // consensus strip
            HStack(spacing: 2) {
                ForEach(0..<24, id: \.self) { h in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(vm.isOverlap(h) ? Color.orbLive : Color.white.opacity(0.3))
                        .frame(height: 10)
                }
            }
        }
        .padding(18)
        .glassCard()
    }

    private var participantsCard: some View {
        VStack(spacing: 16) {
            ForEach(vm.participants) { p in
                ParticipantRow(vm: vm, participant: p)
                    .contextMenu {
                        Button(role: .destructive) { vm.remove(p) } label: {
                            Label("Remove", systemImage: "trash")
                        }
                    }
            }
        }
        .padding(18)
        .glassCard()
    }

    private var workHoursCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("WORKING HOURS").eyebrow()
            Stepper("Start: \(hourLabel(vm.workStart))",
                    value: $vm.workStart, in: 0...(vm.workEnd - 1))
                .foregroundStyle(Color.orbInk)
            Stepper("End: \(hourLabel(vm.workEnd))",
                    value: $vm.workEnd, in: (vm.workStart + 1)...24)
                .foregroundStyle(Color.orbInk)
            Text("Each person's local day is shaded green. Tap any cell to read everyone's clock at that hour.")
                .font(.caption2).foregroundStyle(Color.orbText3)
        }
        .padding(18)
        .glassCard()
    }

    private func hourLabel(_ h: Int) -> String {
        let ampm = h < 12 ? "AM" : "PM"
        var hr = h % 12; if hr == 0 { hr = 12 }
        return h == 24 ? "12 AM" : "\(hr) \(ampm)"
    }
}

#Preview {
    ContentView()
}

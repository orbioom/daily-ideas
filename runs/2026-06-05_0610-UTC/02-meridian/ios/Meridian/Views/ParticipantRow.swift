import SwiftUI

/// A 24-cell band of one participant's local hours, work hours tinted green.
struct ParticipantRow: View {
    @ObservedObject var vm: MeetingViewModel
    let participant: Participant

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(participant.name)
                        .font(.system(.subheadline).weight(.semibold))
                        .foregroundStyle(Color.orbInk)
                    Text("\(participant.city) · \(vm.offsetLabel(participant))")
                        .font(.caption2)
                        .foregroundStyle(Color.orbText3)
                }
                Spacer()
                Text(vm.localTimeString(participant, utcHour: vm.selectedUTCHour ?? vm.currentUTCHour))
                    .font(.system(.caption, design: .monospaced).weight(.medium))
                    .foregroundStyle(Color.orbText2)
            }
            HStack(spacing: 2) {
                ForEach(0..<24, id: \.self) { h in
                    let work = vm.workable(participant, utcHour: h)
                    let isNow = h == vm.currentUTCHour
                    let isSel = h == vm.selectedUTCHour
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(work ? Color.orbLive.opacity(0.55) : Color.white.opacity(0.35))
                        .frame(height: 22)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .strokeBorder(isSel ? Color.orbInk.opacity(0.6)
                                              : (isNow ? Color.orbInk.opacity(0.3) : .clear),
                                              lineWidth: isSel ? 1.5 : 1)
                        )
                        .onTapGesture { vm.selectedUTCHour = (vm.selectedUTCHour == h) ? nil : h }
                }
            }
        }
    }
}

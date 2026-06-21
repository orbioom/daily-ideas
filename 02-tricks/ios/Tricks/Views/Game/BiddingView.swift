import SwiftUI

struct BiddingView: View {
    let vm: GameViewModel
    @State private var selectedBid: Int = 2
    @State private var isNil: Bool = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Your Bid").font(.title2.bold()).foregroundStyle(.white)
            Text("What's in your hand? Estimate your tricks.").font(.caption).foregroundStyle(.white.opacity(0.7))
            if !isNil {
                Stepper(value: $selectedBid, in: 1...13) {
                    Text("Bid: \(selectedBid)").font(.title3).foregroundStyle(.white)
                }
                .padding()
                .background(Color.black.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
            }
            Toggle("Bid Nil (risky!)", isOn: $isNil)
                .foregroundStyle(.white)
                .padding()
                .background(Color.black.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
                .tint(TricksTheme.accent)
            Button {
                vm.humanBid(amount: isNil ? 0 : selectedBid, isNil: isNil)
            } label: {
                Text("Confirm Bid: \(isNil ? "NIL" : "\(selectedBid)")")
                    .font(.headline).foregroundStyle(.white).frame(maxWidth: .infinity).padding()
                    .background(TricksTheme.accent, in: RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(20)
        .background(Color.black.opacity(0.4), in: RoundedRectangle(cornerRadius: 20))
        .padding()
    }
}

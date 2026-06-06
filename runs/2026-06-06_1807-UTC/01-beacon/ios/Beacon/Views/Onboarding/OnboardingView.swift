import SwiftUI

struct OnboardingView: View {
    var onFinish: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("myCallsign") private var myCallsign = ""
    @AppStorage("myGrid") private var myGrid = ""
    @State private var appear = false

    private let pages: [(icon: String, title: String, body: String)] = [
        ("dot.radiowaves.left.and.right", "Log every contact",
         "Capture callsign, band, mode, and signal reports in seconds — at home or in the field, fully offline."),
        ("map", "Group outings",
         "POTA parks, SOTA summits, contests — group contacts into outings and watch your activation count climb."),
        ("globe", "Know your reach",
         "Enter a contact's grid square and Beacon computes the great-circle distance and bearing instantly."),
    ]

    private var gridValid: Bool { myGrid.isEmpty || GridMath.normalize(myGrid) != nil }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(alignment: .leading, spacing: 24) {
                Eyebrow(text: "Beacon")
                Text("Your station, on the air.")
                    .font(.system(.largeTitle, design: .default, weight: .semibold))
                    .foregroundStyle(Brand.text)
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { idx, page in
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: page.icon).font(.title2).foregroundStyle(Brand.text)
                                .frame(width: 32).accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(page.title).font(.headline).foregroundStyle(Brand.text)
                                Text(page.body).font(.subheadline).foregroundStyle(Brand.text2)
                            }
                        }
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear || reduceMotion ? 0 : 16)
                        .animation(Brand.ease(0.5).delay(Double(idx) * 0.08), value: appear)
                    }
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text("Your station (optional)").font(.subheadline.weight(.semibold)).foregroundStyle(Brand.text)
                    TextField("Callsign — e.g. W1AW", text: $myCallsign)
                        .textInputAutocapitalization(.characters).autocorrectionDisabled()
                        .font(Brand.mono(16))
                    TextField("Grid — e.g. FN31pr", text: $myGrid)
                        .textInputAutocapitalization(.characters).autocorrectionDisabled()
                        .font(Brand.mono(16))
                    if !gridValid {
                        Text("That doesn't look like a valid Maidenhead locator.")
                            .font(.caption).foregroundStyle(Brand.danger)
                    }
                }
                .padding(.top, 2)
            }
            .padding(28).glassCard(padding: 24).padding(.horizontal, 20)
            Spacer()
            Button("Start logging") {
                myCallsign = myCallsign.uppercased()
                if let g = GridMath.normalize(myGrid) { myGrid = g }
                onFinish()
            }
            .buttonStyle(InkButtonStyle())
            .disabled(!gridValid)
            .padding(.horizontal, 20).padding(.bottom, 24)
        }
        .onAppear { appear = true }
    }
}

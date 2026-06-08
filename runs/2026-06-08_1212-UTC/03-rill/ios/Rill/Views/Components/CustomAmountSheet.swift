import SwiftUI

struct CustomAmountSheet: View {
    let type: DrinkType
    let onAdd: (Double) -> Void
    @Environment(\.dismiss) private var dismiss
    @AppStorage("volumeUnit") private var unitRaw = VolumeUnit.ml.rawValue

    @State private var amount: Double

    private var unit: VolumeUnit { VolumeUnit(rawValue: unitRaw) ?? .ml }

    init(type: DrinkType, onAdd: @escaping (Double) -> Void) {
        self.type = type
        self.onAdd = onAdd
        _amount = State(initialValue: type.defaultVolumeML)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                VStack(spacing: 24) {
                    VStack(spacing: 6) {
                        Image(systemName: type.symbol)
                            .font(.system(size: 44))
                            .foregroundStyle(Color(hex: type.colorHex))
                        Text(type.name).font(.title3.weight(.semibold)).foregroundStyle(Brand.text)
                    }
                    .padding(.top, 20)

                    Text(Units.string(amount, as: unit))
                        .font(.system(size: 40, design: .rounded).weight(.bold))
                        .foregroundStyle(Brand.text)
                        .accessibilityLabel("Amount \(Units.string(amount, as: unit))")

                    Slider(value: $amount,
                           in: unit == .ml ? 50...1000 : Units.toML(2, from: .floz)...Units.toML(40, from: .floz),
                           step: unit == .ml ? 10 : Units.toML(1, from: .floz))
                        .padding(.horizontal)

                    HStack(spacing: 10) {
                        ForEach(Units.increments(for: unit), id: \.self) { inc in
                            Button(Units.string(inc, as: unit)) { amount = inc }
                                .buttonStyle(GlassButtonStyle())
                        }
                    }
                    .padding(.horizontal)

                    Button("Add") {
                        onAdd(amount)
                        Haptics.tap()
                        dismiss()
                    }
                    .buttonStyle(InkButtonStyle())
                    .padding(.horizontal)

                    Spacer()
                }
            }
            .navigationTitle("Custom amount")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Cancel") { dismiss() } }
            }
            .presentationDetents([.medium, .large])
        }
    }
}

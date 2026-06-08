import SwiftUI

/// A compact month stepper used across screens.
struct MonthBar: View {
    @Binding var month: Date
    private let cal = Calendar.current

    private var isCurrentMonth: Bool {
        cal.isDate(month, equalTo: .now, toGranularity: .month)
    }

    var body: some View {
        HStack {
            Button { step(-1) } label: {
                Image(systemName: "chevron.left").font(.headline)
            }
            .accessibilityLabel("Previous month")
            Spacer()
            Text(Format.monthYear.string(from: month))
                .font(.headline).foregroundStyle(Brand.text)
            Spacer()
            Button { step(1) } label: {
                Image(systemName: "chevron.right").font(.headline)
            }
            .disabled(isCurrentMonth)
            .accessibilityLabel("Next month")
        }
        .foregroundStyle(Color(hex: 0x3E9E78))
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func step(_ delta: Int) {
        if let m = cal.date(byAdding: .month, value: delta, to: month) {
            withAnimation(Brand.ease(0.25)) { month = m }
            Haptics.selection()
        }
    }
}

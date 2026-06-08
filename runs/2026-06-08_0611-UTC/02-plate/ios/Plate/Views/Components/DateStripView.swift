import SwiftUI

/// Horizontal scrolling date strip for diary navigation.
struct DateStripView: View {
    @Binding var selectedDate: Date

    private let calendar = Calendar.current
    private let dates: [Date]

    init(selectedDate: Binding<Date>) {
        _selectedDate = selectedDate
        let today = Calendar.current.startOfDay(for: Date())
        dates = (-13...0).compactMap { offset in
            Calendar.current.date(byAdding: .day, value: offset, to: today)
        }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(dates, id: \.self) { date in
                        DateChip(date: date, isSelected: calendar.isDate(date, inSameDayAs: selectedDate))
                            .onTapGesture {
                                Haptics.selection()
                                withAnimation(Brand.ease(0.3)) {
                                    selectedDate = date
                                }
                            }
                            .id(date)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }
            .onAppear {
                let today = calendar.startOfDay(for: Date())
                proxy.scrollTo(today, anchor: .trailing)
            }
        }
    }
}

private struct DateChip: View {
    let date: Date
    let isSelected: Bool
    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 2) {
            Text(Format.weekdayLetter(date))
                .font(.caption2.weight(.medium))
                .foregroundStyle(isSelected ? .white : Brand.text3)

            Text(dayNumber)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(isSelected ? .white : Brand.text)
        }
        .frame(width: 42, height: 50)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Brand.inkGradient)
            } else {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Brand.hairline.opacity(0.5))
            }
        }
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var dayNumber: String {
        let comps = calendar.dateComponents([.day], from: date)
        return "\(comps.day ?? 0)"
    }

    private var accessibilityLabel: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

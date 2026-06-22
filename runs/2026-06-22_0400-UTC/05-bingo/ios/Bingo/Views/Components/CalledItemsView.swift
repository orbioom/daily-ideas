import SwiftUI

struct CalledItemsView: View {
    let calledItems: [String]
    let gameType: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Called (\(calledItems.count))")
                .font(.headline.bold())
                .foregroundColor(BingoTheme.gold)

            if calledItems.isEmpty {
                Text("No items called yet")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(Array(calledItems.reversed().enumerated()), id: \.offset) { _, item in
                            if gameType == "number" {
                                CalledBallChip(text: item)
                            } else {
                                WordChip(text: item)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                if gameType == "number" {
                    NumberGridDisplay(calledItems: calledItems)
                }
            }
        }
        .padding()
        .background(BingoTheme.lightNavy)
        .cornerRadius(12)
    }
}

struct WordChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(BingoTheme.navy)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(BingoTheme.gold)
            .cornerRadius(8)
    }
}

struct NumberGridDisplay: View {
    let calledItems: [String]

    let columns = ["B", "I", "N", "G", "O"]

    func numbersForColumn(_ letter: String) -> [Int] {
        calledItems
            .filter { $0.hasPrefix(letter) }
            .compactMap { Int($0.dropFirst()) }
            .sorted()
    }

    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            ForEach(columns, id: \.self) { col in
                VStack(spacing: 3) {
                    Text(col)
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(BingoTheme.gold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 3)
                        .background(BingoTheme.navy)
                        .cornerRadius(4)

                    ForEach(numbersForColumn(col), id: \.self) { num in
                        Text("\(num)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 2)
                            .background(BingoTheme.lightNavy.opacity(0.6))
                            .cornerRadius(3)
                    }
                }
            }
        }
        .padding(.top, 8)
    }
}

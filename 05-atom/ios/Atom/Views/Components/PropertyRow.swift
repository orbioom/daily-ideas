import SwiftUI

struct PropertyRow: View {
    let label: String
    let value: String
    var valueColor: Color = AtomTheme.textPrimary

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(AtomTheme.textSecondary)
                .frame(width: 140, alignment: .leading)

            Spacer()

            Text(value)
                .font(.subheadline)
                .foregroundStyle(valueColor)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 16)
    }
}

struct PropertyDivider: View {
    var body: some View {
        Divider()
            .background(AtomTheme.cellBorder)
            .padding(.horizontal, 16)
    }
}

#Preview {
    VStack {
        PropertyRow(label: "Category", value: "Transition Metal")
        PropertyDivider()
        PropertyRow(label: "Atomic Number", value: "79")
    }
    .background(AtomTheme.cardBackground)
    .preferredColorScheme(.dark)
}

import SwiftUI

/// A curated palette of subscription-brand-friendly colors.
struct ColorPickerSheet: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedHex: String

    private let palette: [String] = [
        "7C5CF0", "E50914", "1DB954", "3B9CF0", "E67E22", "9B59B6",
        "2EB0A0", "E84393", "F1C40F", "5D6D7E", "FF0000", "0061FF",
        "16A085", "E2574C", "111111", "FD79A8", "113CCF", "8A2BE2",
        "34495E", "27AE60", "C0392B", "2980B9", "8E44AD", "D35400"
    ]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 6)

    var body: some View {
        NavigationStack {
            ZStack {
                RecurTheme.appBackground(scheme).ignoresSafeArea()
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(palette, id: \.self) { hex in
                            Button {
                                selectedHex = hex
                                Haptics.selection()
                                dismiss()
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(Color.white, lineWidth: selectedHex == hex ? 3 : 0)
                                    )
                                    .overlay(
                                        Circle().strokeBorder(RecurTheme.hairline(scheme), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Color \(hex)")
                            .accessibilityAddTraits(selectedHex == hex ? [.isSelected] : [])
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Choose Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

/// A grid of useful SF Symbols for subscriptions.
struct IconPickerSheet: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedIcon: String

    private let icons: [String] = [
        "play.tv", "music.note", "laptopcomputer", "icloud", "gamecontroller",
        "newspaper", "figure.run", "graduationcap", "fork.knife", "bolt",
        "banknote", "bag", "tv", "play.rectangle", "headphones", "books.vertical",
        "wifi", "phone", "envelope", "photo", "paintbrush.pointed", "doc.text",
        "shippingbox", "sparkles.tv", "creditcard", "car", "house", "dumbbell",
        "cup.and.saucer", "globe", "shield.lefthalf.filled", "cloud", "video",
        "antenna.radiowaves.left.and.right", "square.grid.2x2"
    ]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 14), count: 5)

    var body: some View {
        NavigationStack {
            ZStack {
                RecurTheme.appBackground(scheme).ignoresSafeArea()
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(icons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                                Haptics.selection()
                                dismiss()
                            } label: {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .foregroundStyle(selectedIcon == icon ? Color.white : RecurTheme.primaryText(scheme))
                                    .frame(width: 52, height: 52)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(selectedIcon == icon ? RecurTheme.violet : RecurTheme.subtleSurface(scheme))
                                    )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(icon)
                            .accessibilityAddTraits(selectedIcon == icon ? [.isSelected] : [])
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Choose Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

import SwiftUI

/// Controls which names appear in the swipe deck. Persisted to AppStorage.
struct FilterView: View {
    @Environment(\.colorScheme) private var scheme
    @AppStorage("genderFilter") private var genderFilterRaw = ""
    @AppStorage("styleFilter") private var styleFilterRaw = ""

    private var genders: Set<NameGender> {
        Set(genderFilterRaw.split(separator: ",").compactMap { NameGender(rawValue: String($0)) })
    }
    private var styles: Set<NameStyle> {
        Set(styleFilterRaw.split(separator: ",").compactMap { NameStyle(rawValue: String($0)) })
    }

    private var matchCount: Int {
        NameCatalog.filtered(genders: genders, styles: styles, initial: nil, maxLength: nil).count
    }

    var body: some View {
        Form {
            Section {
                ForEach(NameGender.allCases) { gender in
                    toggleRow(label: gender.label, color: Theme.genderColor(gender),
                              isOn: genders.contains(gender)) {
                        toggle(gender)
                    }
                }
            } header: {
                Text("Gender")
            } footer: {
                Text("Leave all off to see every gender.")
            }

            Section("Style") {
                ForEach(NameStyle.allCases) { style in
                    toggleRow(label: style.label, color: Theme.butter,
                              isOn: styles.contains(style)) {
                        toggle(style)
                    }
                }
            }

            Section {
                Text("\(matchCount) names match this filter.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(matchCount == 0 ? Theme.blush : Theme.mint)
                Button("Clear all filters") {
                    genderFilterRaw = ""
                    styleFilterRaw = ""
                    Haptics.tap()
                }
                .disabled(genderFilterRaw.isEmpty && styleFilterRaw.isEmpty)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background(scheme))
        .navigationTitle("Filter")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func toggleRow(label: String, color: Color, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Circle().fill(color).frame(width: 12, height: 12)
                Text(label)
                    .foregroundStyle(Theme.ink(scheme))
                Spacer()
                if isOn {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Theme.blush)
                        .fontWeight(.bold)
                }
            }
        }
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    private func toggle(_ gender: NameGender) {
        var set = genders
        if set.contains(gender) { set.remove(gender) } else { set.insert(gender) }
        genderFilterRaw = set.map(\.rawValue).joined(separator: ",")
        Haptics.tap()
    }

    private func toggle(_ style: NameStyle) {
        var set = styles
        if set.contains(style) { set.remove(style) } else { set.insert(style) }
        styleFilterRaw = set.map(\.rawValue).joined(separator: ",")
        Haptics.tap()
    }
}

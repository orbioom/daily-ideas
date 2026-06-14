import SwiftUI

/// Bottom sheet to add a catalog entry to the library with a status choice.
struct CatalogAddView: View {
    let entry: CatalogEntry
    let alreadyAdded: Bool
    let onAdd: (WatchStatus) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var status: WatchStatus = .planning

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        CoverView(hue: Title.deterministicHue(for: entry.name),
                                  kind: entry.kind,
                                  initials: entry.name.coverInitials)
                            .frame(width: 150, height: 200)
                            .padding(.top, 12)

                        VStack(spacing: 6) {
                            Text(entry.name)
                                .font(Theme.display(22, .bold))
                                .foregroundStyle(Theme.ink)
                                .multilineTextAlignment(.center)
                            Text(entry.studioOrAuthor)
                                .font(Theme.rounded(14))
                                .foregroundStyle(Theme.inkSoft)
                        }

                        HStack(spacing: 8) {
                            Pill(text: "\(entry.defaultUnits) \(entry.kind.unitNounPlural)",
                                 systemImage: entry.kind.symbol, tint: Theme.violet)
                            if let season = entry.seasonLabel {
                                Pill(text: season, systemImage: "calendar", tint: Theme.cyan)
                            } else {
                                Pill(text: "\(entry.year)", systemImage: "calendar", tint: Theme.cyan)
                            }
                        }

                        if !entry.genres.isEmpty {
                            FlowRow(spacing: 6) {
                                ForEach(entry.genres, id: \.self) { g in
                                    Pill(text: g, tint: Theme.accent)
                                }
                            }
                            .padding(.horizontal, 16)
                        }

                        if alreadyAdded {
                            Label("Already in your library", systemImage: "checkmark.circle.fill")
                                .font(Theme.rounded(15, .semibold))
                                .foregroundStyle(Theme.good)
                                .padding(.vertical, 8)
                        } else {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Add as")
                                    .font(Theme.rounded(14, .semibold))
                                    .foregroundStyle(Theme.inkSoft)
                                Picker("Status", selection: $status) {
                                    ForEach(WatchStatus.allCases) { s in
                                        Text(s.label(for: entry.kind)).tag(s)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(Theme.accent)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)

                            PrimaryButton(title: "Add to Library", systemImage: "plus") {
                                onAdd(status)
                                dismiss()
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Add Title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Close") { dismiss() } }
            }
        }
        .presentationDetents([.large])
    }
}

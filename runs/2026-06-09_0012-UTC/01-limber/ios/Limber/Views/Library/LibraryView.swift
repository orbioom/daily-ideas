import SwiftUI
import SwiftData

struct LibraryView: View {
    @Query(sort: \Stretch.name) private var stretches: [Stretch]
    @State private var selectedArea: BodyArea?
    @State private var query = ""
    @State private var addingCustom = false

    private var filtered: [Stretch] {
        stretches.filter { s in
            (selectedArea == nil || s.area == selectedArea) &&
            (query.isEmpty || s.name.localizedCaseInsensitiveContains(query))
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    areaFilter
                    if filtered.isEmpty {
                        EmptyStateView(icon: "magnifyingglass",
                                       title: "Nothing here",
                                       message: "No stretches match your filter. Try another area or add your own.")
                            .glassCard()
                    } else {
                        ForEach(filtered) { stretch in
                            NavigationLink {
                                StretchDetailView(stretch: stretch)
                            } label: {
                                stretchRow(stretch)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(20)
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle("Library")
            .searchable(text: $query, prompt: "Search stretches")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap()
                        addingCustom = true
                    } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add custom stretch")
                }
            }
            .sheet(isPresented: $addingCustom) {
                StretchEditorView()
            }
        }
    }

    private var areaFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(title: "All", area: nil)
                ForEach(BodyArea.allCases) { area in
                    chip(title: area.title, area: area)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func chip(title: String, area: BodyArea?) -> some View {
        let active = selectedArea == area
        return Button {
            Haptics.selection()
            withAnimation(Brand.ease(0.25)) { selectedArea = area }
        } label: {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(active ? (area?.tint ?? Brand.text).opacity(0.2) : Color.clear,
                            in: Capsule())
                .overlay(Capsule().strokeBorder(active ? (area?.tint ?? Brand.text) : Brand.hairline, lineWidth: 1))
                .foregroundStyle(Brand.text)
        }
        .accessibilityAddTraits(active ? .isSelected : [])
    }

    private func stretchRow(_ stretch: Stretch) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(stretch.area.tint.opacity(0.18)).frame(width: 42, height: 42)
                Image(systemName: stretch.area.icon).foregroundStyle(stretch.area.tint)
            }
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(stretch.name).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                    if stretch.isCustom {
                        Text("Custom").font(.caption2).foregroundStyle(Brand.magic)
                    }
                }
                Text("\(stretch.area.title) · \(stretch.difficultyLabel)")
                    .font(.caption).foregroundStyle(Brand.text3)
            }
            Spacer()
            Text("\(stretch.defaultSeconds)s").font(Brand.mono(13)).foregroundStyle(Brand.text2)
            Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(Brand.text3)
                .accessibilityHidden(true)
        }
        .glassCard(padding: 12)
        .accessibilityElement(children: .combine)
    }
}

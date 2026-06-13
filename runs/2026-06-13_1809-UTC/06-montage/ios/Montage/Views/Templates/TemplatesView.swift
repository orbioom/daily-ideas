import SwiftUI

struct TemplatesView: View {
    @State private var category: TemplateCategory = .story

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]
    private var templates: [MontageTemplate] { TemplateLibrary.inCategory(category) }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        Picker("Format", selection: $category) {
                            ForEach(TemplateCategory.allCases) { c in Text(c.label).tag(c) }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 16).padding(.top, 8)

                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(templates) { t in
                                NavigationLink(value: t) {
                                    VStack(spacing: 8) {
                                        TemplatePreview(template: t, height: 150)
                                        Text(t.name).font(Theme.rounded(14, .bold)).foregroundStyle(Theme.ink)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16).padding(.bottom, 28)
                    }
                }
            }
            .navigationTitle("Create")
            .navigationDestination(for: MontageTemplate.self) { EditorView(template: $0) }
        }
    }
}

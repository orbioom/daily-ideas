import SwiftUI

struct EditorView: View {
    @Bindable var project: ScriptProject
    var settings: ScriptSettings

    @State private var showPreview = false
    @State private var showExport = false
    @State private var showDetail = false
    @State private var showFormatGuide = false
    @State private var saveTask: Task<Void, Never>?

    private var pageCount: Int {
        FountainParser.estimatePageCount(elements: FountainParser.parse(text: project.content))
    }

    private var wordCount: Int {
        project.content.split(separator: " ").count
    }

    var body: some View {
        VStack(spacing: 0) {
            // Format toolbar
            if settings.showElementGuide {
                FormatGuide(content: $project.content)
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                    .background(.bar)
            }

            // Main editor
            TextEditor(text: $project.content)
                .font(.custom("Courier", size: settings.fontSize))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding(.horizontal, 8)
                .onChange(of: project.content) { _, _ in
                    scheduleAutosave()
                }

            // Bottom status bar
            HStack {
                Text("\(wordCount) words")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                if settings.showPageNumbers {
                    PageCountBadge(count: pageCount)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(.bar)
        }
        .navigationTitle(project.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showPreview = true } label: {
                        Label("Preview", systemImage: "eye")
                    }
                    Button { showDetail = true } label: {
                        Label("Script Details", systemImage: "info.circle")
                    }
                    Button { showExport = true } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    Toggle(isOn: $settings.showElementGuide) {
                        Label("Format Guide", systemImage: "text.badge.checkmark")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showPreview) {
            PreviewView(project: project)
        }
        .sheet(isPresented: $showExport) {
            ExportView(project: project, hasPro: settings.hasPro)
        }
        .sheet(isPresented: $showDetail) {
            ScriptDetailView(project: project)
        }
    }

    private func scheduleAutosave() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                project.updatedAt = .now
            }
        }
    }
}

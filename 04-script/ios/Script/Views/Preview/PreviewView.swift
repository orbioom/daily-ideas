import SwiftUI
import SwiftData

struct PreviewView: View {
    let project: ScriptProject
    @Environment(\.dismiss) private var dismiss
    @Query private var allSettings: [ScriptSettings]
    @State private var showExport = false

    private var hasPro: Bool { allSettings.first?.hasPro ?? false }

    private var elements: [FountainElement] {
        FountainParser.parse(text: project.content)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Title page section
                    TitlePagePreview(project: project)

                    // Script body elements
                    ForEach(Array(elements.enumerated()), id: \.offset) { _, element in
                        FountainElementView(element: element)
                    }

                    Spacer(minLength: 60)
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(.systemBackground))
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showExport = true
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showExport) {
                ExportView(project: project, hasPro: hasPro)
            }
        }
    }
}

struct TitlePagePreview: View {
    let project: ScriptProject

    var body: some View {
        VStack(spacing: 8) {
            Spacer(minLength: 60)
            Text(project.title.isEmpty ? "UNTITLED" : project.title.uppercased())
                .font(.custom("Courier-Bold", size: 14))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            Text("Written by")
                .font(.custom("Courier", size: 12))
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
            Text(project.author.isEmpty ? "Unknown Author" : project.author)
                .font(.custom("Courier", size: 12))
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
            Text(project.draftNumber)
                .font(.custom("Courier", size: 12))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
            Spacer(minLength: 60)
            Divider()
                .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity)
    }
}

struct FountainElementView: View {
    let element: FountainElement

    var body: some View {
        Group {
            switch element.type {
            case .sceneHeading:
                Text(element.text.uppercased())
                    .font(.custom("Courier-Bold", size: 12))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 16)
                    .padding(.bottom, 4)

            case .action:
                Text(element.text)
                    .font(.custom("Courier", size: 12))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 4)

            case .character:
                Text(element.text.uppercased())
                    .font(.custom("Courier", size: 12))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 12)

            case .dialogue:
                Text(element.text)
                    .font(.custom("Courier", size: 12))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 48)
                    .padding(.bottom, 2)

            case .parenthetical:
                Text(element.text)
                    .font(.custom("Courier", size: 12))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, 80)

            case .transition:
                Text(element.text)
                    .font(.custom("Courier", size: 12))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.vertical, 8)

            case .titlePage:
                EmptyView()

            case .pageBreak:
                Divider()
                    .padding(.vertical, 16)

            case .centered:
                Text(element.text)
                    .font(.custom("Courier", size: 12))
                    .frame(maxWidth: .infinity, alignment: .center)

            default:
                Text(element.text)
                    .font(.custom("Courier", size: 12))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .foregroundColor(.primary)
    }
}

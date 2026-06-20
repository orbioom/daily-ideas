import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allSettings: [ScriptSettings]
    @State private var page = 0
    @State private var authorName = ""

    private var settings: ScriptSettings {
        if let s = allSettings.first { return s }
        let s = ScriptSettings()
        modelContext.insert(s)
        return s
    }

    var body: some View {
        TabView(selection: $page) {
            page1.tag(0)
            page2.tag(1)
            page3.tag(2)
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .background(Color(.systemBackground))
    }

    private var page1: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "doc.text.fill")
                .font(.system(size: 80))
                .foregroundStyle(.scriptAmber)
            Text("Write Your Story")
                .font(.largeTitle.bold())
            Text("A screenwriting app that stays out of your way. Fountain format. Proper screenplay formatting. PDF export.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
            Spacer()
            Button("Next →") { withAnimation { page = 1 } }
                .buttonStyle(.borderedProminent)
                .tint(.scriptAmber)
                .padding(.bottom, 40)
        }
    }

    private var page2: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "text.alignleft")
                .font(.system(size: 60))
                .foregroundStyle(.scriptAmber)
            Text("Fountain Format")
                .font(.title.bold())
            VStack(alignment: .leading, spacing: 8) {
                ForEach([
                    ("INT./EXT.", "Scene headings auto-capitalize"),
                    ("ALL CAPS", "Character names are ALL CAPS"),
                    ("(beat)", "Parentheticals in (parentheses)"),
                    ("CUT TO:", "Transitions end with TO:"),
                ], id: \.0) { pair in
                    HStack {
                        Text(pair.0)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.scriptAmber)
                            .frame(width: 100, alignment: .leading)
                        Text(pair.1)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
            Spacer()
            Button("Next →") { withAnimation { page = 2 } }
                .buttonStyle(.borderedProminent)
                .tint(.scriptAmber)
                .padding(.bottom, 40)
        }
    }

    private var page3: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "person.crop.circle")
                .font(.system(size: 60))
                .foregroundStyle(.scriptAmber)
            Text("Your Name")
                .font(.title.bold())
            Text("Pre-fills the Author field on new scripts.")
                .foregroundStyle(.secondary)
            TextField("Author name", text: $authorName)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 40)
            Spacer()
            Button("Start Writing") {
                settings.authorName = authorName
                settings.hasCompletedOnboarding = true
            }
            .buttonStyle(.borderedProminent)
            .tint(.scriptAmber)
            .padding(.bottom, 40)
        }
    }
}

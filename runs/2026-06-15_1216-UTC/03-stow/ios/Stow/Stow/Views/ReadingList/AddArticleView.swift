import SwiftUI
import SwiftData

/// Paste a URL → loading → extracted preview → save. Full error/retry states.
struct AddArticleView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    let currentSavedCount: Int

    @StateObject private var vm: AddArticleViewModel
    @FocusState private var urlFocused: Bool
    @State private var showPaywall = false

    init(currentSavedCount: Int, wordsPerMinute: Int) {
        self.currentSavedCount = currentSavedCount
        _vm = StateObject(wrappedValue: AddArticleViewModel(wordsPerMinute: wordsPerMinute))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("Add Article")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(reason: .articleLimit)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch vm.phase {
        case .input:
            inputView
        case .loading:
            loadingView
        case .preview:
            previewView
        case .failed(let message, let suggestion):
            failedView(message: message, suggestion: suggestion)
        }
    }

    // MARK: Input

    private var inputView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Paste a link")
                    .font(Theme.serif(22, .semibold))
                    .foregroundStyle(Theme.ink)

                Text("Stow will fetch the page and keep a clean, offline copy you can read anytime.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSoft)

                HStack {
                    Image(systemName: "link")
                        .foregroundStyle(Theme.inkFaint)
                    TextField("https://example.com/article", text: $vm.urlText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .submitLabel(.go)
                        .focused($urlFocused)
                        .onSubmit { submit() }
                        .accessibilityLabel("Article web address")
                }
                .padding(14)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous)
                        .strokeBorder(Theme.hairline, lineWidth: 1)
                )

                Button(action: submit) {
                    Text("Fetch article")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(vm.canSubmit ? Theme.accent : Theme.inkFaint,
                                    in: RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
                        .foregroundStyle(.white)
                }
                .disabled(!vm.canSubmit)

                if !isPro {
                    Label("Free Stow holds \(Pro.remainingFree(currentCount: currentSavedCount)) more articles.",
                          systemImage: "info.circle")
                        .font(.caption)
                        .foregroundStyle(Theme.inkSoft)
                }

                Text("Tip: on a real device, paste any article link. Offline? Your seeded articles are already on the Read tab.")
                    .font(.caption)
                    .foregroundStyle(Theme.inkFaint)
                    .padding(.top, 4)
            }
            .padding(20)
        }
        .onAppear { urlFocused = true }
    }

    // MARK: Loading

    private var loadingView: some View {
        VStack(spacing: 18) {
            ProgressView()
                .controlSize(.large)
                .tint(Theme.accent)
            Text("Fetching and cleaning the page…")
                .font(.headline)
                .foregroundStyle(Theme.ink)
            Text("Extracting the readable text on your device.")
                .font(.subheadline)
                .foregroundStyle(Theme.inkSoft)
        }
        .padding(32)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Fetching and cleaning the page")
    }

    // MARK: Preview

    @ViewBuilder
    private var previewView: some View {
        if let result = vm.result {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Ready to stow")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.good)

                    Text(result.title)
                        .font(Theme.serif(24, .bold))
                        .foregroundStyle(Theme.ink)

                    HStack(spacing: 6) {
                        if !result.siteName.isEmpty {
                            Text(result.siteName)
                        }
                        if !result.byline.isEmpty {
                            Text("· \(result.byline)")
                        }
                        Text("· \(result.estMinutes) min")
                    }
                    .font(.caption)
                    .foregroundStyle(Theme.inkSoft)

                    Divider().background(Theme.hairline)

                    ForEach(result.blocks.prefix(4)) { block in
                        Text(block.text)
                            .font(block.kind == .heading ? Theme.serif(18, .semibold) : .body)
                            .foregroundStyle(block.kind == .heading ? Theme.ink : Theme.inkSoft)
                    }
                    if result.blocks.count > 4 {
                        Text("…and \(result.blocks.count - 4) more sections")
                            .font(.caption)
                            .foregroundStyle(Theme.inkFaint)
                    }

                    HStack(spacing: 12) {
                        Button {
                            vm.reset()
                        } label: {
                            Text("Discard")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .background(Theme.surfaceAlt, in: RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
                                .foregroundStyle(Theme.ink)
                        }
                        Button {
                            save(result)
                        } label: {
                            Text("Save")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .background(Theme.accent, in: RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(20)
            }
        } else {
            // Defensive: should not happen, but never crash.
            failedView(message: "We couldn't read that page.", suggestion: "Try another link.")
        }
    }

    // MARK: Failed

    private func failedView(message: String, suggestion: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 42, weight: .light))
                .foregroundStyle(Theme.warn)
                .accessibilityHidden(true)
            Text(message)
                .font(.headline)
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(suggestion)
                .font(.subheadline)
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
            HStack(spacing: 12) {
                Button {
                    vm.reset()
                } label: {
                    Text("Edit link")
                        .font(.headline)
                        .padding(.horizontal, 20).padding(.vertical, 11)
                        .background(Theme.surfaceAlt, in: Capsule())
                        .foregroundStyle(Theme.ink)
                }
                Button {
                    Task { await vm.fetch() }
                } label: {
                    Text("Retry")
                        .font(.headline)
                        .padding(.horizontal, 20).padding(.vertical, 11)
                        .background(Theme.accent, in: Capsule())
                        .foregroundStyle(.white)
                }
            }
            .padding(.top, 6)
        }
        .padding(32)
        .onAppear { settings.haptic { Haptics.warning() } }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(message). \(suggestion)")
    }

    // MARK: Actions

    private func submit() {
        urlFocused = false
        Task { await vm.fetch() }
    }

    private func save(_ result: ExtractedArticle) {
        guard Pro.canSaveMore(currentCount: currentSavedCount, isPro: isPro) else {
            showPaywall = true
            return
        }
        let article = result.makeModel(source: .url)
        context.insert(article)
        do {
            try context.save()
            settings.haptic { Haptics.success() }
            dismiss()
        } catch {
            // Roll back and surface a recoverable error.
            context.delete(article)
            vm.phase = .failed("Couldn't save the article.", "Please try again.")
        }
    }
}

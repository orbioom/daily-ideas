import SwiftUI
import SwiftData

/// A lightweight sheet to jump the current page via a slider or exact value.
struct UpdateProgressView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    @Bindable var book: Book

    @State private var page: Double = 0
    @State private var pageText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                ProgressRing(progress: ringProgress,
                             lineWidth: 14,
                             label: "\(Int(ringProgress * 100))%")
                    .frame(width: 150, height: 150)
                    .padding(.top, 12)

                Text("Page \(Int(page)) of \(book.pageCount)")
                    .font(Theme.rounded(18, .semibold))
                    .foregroundStyle(Theme.ink)
                    .monospacedDigit()

                if book.pageCount > 0 {
                    Slider(value: $page, in: 0...Double(book.pageCount), step: 1)
                        .tint(Theme.accent)
                        .onChange(of: page) { _, newValue in
                            pageText = String(Int(newValue))
                        }
                        .accessibilityValue("Page \(Int(page))")
                }

                HStack {
                    Text("Exact page").foregroundStyle(Theme.inkSoft)
                    Spacer()
                    TextField("0", text: $pageText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 90)
                        .onChange(of: pageText) { _, newValue in
                            if let v = Int(newValue) {
                                page = Double(min(max(0, v), book.pageCount))
                            }
                        }
                }
                .padding(16)
                .cardSurface()

                Spacer()
                PrimaryButton(title: "Save progress", systemImage: "checkmark") { save() }
            }
            .padding(20)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(book.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
            }
            .onAppear {
                page = Double(min(book.currentPage, book.pageCount))
                pageText = String(Int(page))
            }
        }
    }

    private var ringProgress: Double {
        guard book.pageCount > 0 else { return 0 }
        return min(1, page / Double(book.pageCount))
    }

    private func save() {
        let newPage = min(max(0, Int(page)), book.pageCount)
        book.currentPage = newPage
        if book.shelf == .wantToRead, newPage > 0 {
            book.shelf = .reading
            if book.startedDate == nil { book.startedDate = .now }
        }
        if newPage >= book.pageCount, book.pageCount > 0, book.shelf == .reading {
            book.shelf = .finished
            book.finishedDate = .now
        }
        try? context.save()
        Haptics.success(enabled: settings.hapticsEnabled)
        dismiss()
    }
}

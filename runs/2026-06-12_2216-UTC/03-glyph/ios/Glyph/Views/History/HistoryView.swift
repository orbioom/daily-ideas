import SwiftUI
import SwiftData
import UIKit

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ScanRecord.date, order: .reverse) private var records: [ScanRecord]
    @State private var confirmingClear = false
    @State private var copiedID: PersistentIdentifier?

    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty {
                    ContentUnavailableView(
                        "No Scans Yet",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Codes you scan — by camera or from photos — are kept here on this device, so you can find that link again.")
                    )
                } else {
                    List {
                        ForEach(records) { record in
                            row(record)
                        }
                        .onDelete(perform: delete)
                    }
                }
            }
            .navigationTitle("Scan History")
            .toolbar {
                if !records.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Clear", role: .destructive) {
                            confirmingClear = true
                        }
                    }
                }
            }
            .confirmationDialog("Delete all scan history?", isPresented: $confirmingClear, titleVisibility: .visible) {
                Button("Delete All", role: .destructive) {
                    for record in records {
                        modelContext.delete(record)
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func row(_ record: ScanRecord) -> some View {
        Button {
            UIPasteboard.general.string = record.payload
            Haptics.tap()
            copiedID = record.persistentModelID
            Task {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                if copiedID == record.persistentModelID { copiedID = nil }
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: record.detectedKind.symbol)
                    .font(.body)
                    .foregroundStyle(GlyphTheme.mint)
                    .frame(width: 30)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(record.payload)
                        .font(.callout.monospaced())
                        .lineLimit(2)
                        .foregroundStyle(.primary)
                    Text("\(record.detectedKind.displayName) · \(record.fromCamera ? "Camera" : "Photo") · \(record.date.formatted(.dateTime.day().month().hour().minute()))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if copiedID == record.persistentModelID {
                    Text("Copied")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(GlyphTheme.mint)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(record.detectedKind.displayName) scan: \(record.payload)")
        .accessibilityHint("Copies the payload")
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(records[index])
        }
    }
}

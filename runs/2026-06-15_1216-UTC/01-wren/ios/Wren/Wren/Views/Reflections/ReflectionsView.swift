import SwiftUI
import SwiftData

struct ReflectionsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settings: AppSettings

    @Query(sort: \CheckIn.date, order: .reverse) private var checkIns: [CheckIn]

    @State private var showEditor = false
    @State private var showPaywall = false
    @State private var exportText: String?
    @State private var errorMessage: String?

    private var todayCheckIn: CheckIn? {
        checkIns.first { DateUtils.isSameDay($0.date, Date()) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        todayCard
                        historySection
                    }
                    .padding()
                }
            }
            .navigationTitle("Reflect")
            .toolbar {
                if settings.isPro && !checkIns.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            exportText = buildExport()
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .accessibilityLabel("Export reflections")
                        }
                    }
                } else if !checkIns.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showPaywall = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .accessibilityLabel("Export reflections (Pro)")
                        }
                    }
                }
            }
            .sheet(isPresented: $showEditor) {
                CheckInEditorView(existing: todayCheckIn)
            }
            .sheet(isPresented: $showPaywall) { PaywallView(reason: .exportReflections) }
            .sheet(item: Binding(
                get: { exportText.map { ExportPayload(text: $0) } },
                set: { exportText = $0?.text }
            )) { payload in
                ShareSheet(items: [payload.text])
            }
            .alert("Couldn't save", isPresented: Binding(
                get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: { Text(errorMessage ?? "") }
        }
    }

    private var todayCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("How are you today?", subtitle: DateUtils.fullFormatter.string(from: Date()))
            if let today = todayCheckIn {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        MoodFace(mood: today.mood, size: 40)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(MoodFace.label(today.mood))
                                .font(Theme.rounded(17, .semibold))
                                .foregroundStyle(Theme.ink)
                            Text("Checked in today")
                                .font(Theme.rounded(12))
                                .foregroundStyle(Theme.inkSoft)
                        }
                        Spacer()
                        Button("Edit") { showEditor = true }
                            .font(Theme.rounded(14, .semibold))
                            .foregroundStyle(Theme.accent)
                    }
                    if !today.note.isEmpty {
                        Text(today.note)
                            .font(Theme.rounded(14))
                            .foregroundStyle(Theme.inkSoft)
                    }
                    if let g = today.gratitude, !g.isEmpty {
                        Label(g, systemImage: "heart.fill")
                            .font(Theme.rounded(13))
                            .foregroundStyle(Theme.good)
                    }
                }
                .padding(16)
                .card(Theme.surface)
            } else {
                Button {
                    showEditor = true
                } label: {
                    HStack {
                        Image(systemName: "leaf.fill").foregroundStyle(Theme.accent)
                        Text("Take a quiet moment to check in")
                            .font(Theme.rounded(15, .medium))
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(Theme.inkFaint)
                    }
                    .padding(16)
                    .card(Theme.surface)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var historySection: some View {
        SectionHeader("Your reflections")
        let history = checkIns.filter { !DateUtils.isSameDay($0.date, Date()) }
        if history.isEmpty {
            EmptyStateView(systemImage: "book.closed",
                           title: "No past reflections yet",
                           message: "Each daily check-in is kept here, so you can look back gently.")
            .card(Theme.surface)
        } else {
            LazyVStack(spacing: 10) {
                ForEach(history) { checkIn in
                    CheckInRow(checkIn: checkIn) {
                        delete(checkIn)
                    }
                }
            }
        }
    }

    private func delete(_ checkIn: CheckIn) {
        do {
            try CareStore(context: modelContext).deleteCheckIn(checkIn)
            settings.haptic(.soft)
        } catch {
            errorMessage = "Couldn't delete that reflection."
        }
    }

    private func buildExport() -> String {
        var lines = ["Wren — Reflections export", ""]
        for c in checkIns {
            var line = "\(DateUtils.fullFormatter.string(from: c.date)) — \(MoodFace.label(c.mood)) (\(c.mood)/5)"
            if !c.note.isEmpty { line += "\n  Note: \(c.note)" }
            if let g = c.gratitude, !g.isEmpty { line += "\n  Grateful for: \(g)" }
            lines.append(line)
        }
        return lines.joined(separator: "\n")
    }
}

private struct ExportPayload: Identifiable {
    let id = UUID()
    let text: String
}

// MARK: - History row

private struct CheckInRow: View {
    let checkIn: CheckIn
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            MoodFace(mood: checkIn.mood, size: 32)
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(DateUtils.fullFormatter.string(from: checkIn.date))
                        .font(Theme.rounded(14, .semibold))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Text(MoodFace.label(checkIn.mood))
                        .font(Theme.rounded(12, .medium))
                        .foregroundStyle(MoodFace.color(checkIn.mood))
                }
                if !checkIn.note.isEmpty {
                    Text(checkIn.note)
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                        .lineLimit(2)
                }
                if let g = checkIn.gratitude, !g.isEmpty {
                    Label(g, systemImage: "heart.fill")
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.good)
                        .lineLimit(1)
                }
            }
        }
        .padding(14)
        .card(Theme.surface)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(DateUtils.fullFormatter.string(from: checkIn.date)), \(MoodFace.label(checkIn.mood))")
        .accessibilityValue(checkIn.note)
    }
}

// MARK: - Share sheet wrapper

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

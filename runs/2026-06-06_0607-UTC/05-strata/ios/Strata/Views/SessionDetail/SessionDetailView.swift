import SwiftUI
import SwiftData

/// A session's full detail: header stats, ordered attempts, and an add-attempt
/// action. Attempts can be deleted; the session itself can be edited or removed.
struct SessionDetailView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Bindable var session: Session

    @State private var showingAddAttempt = false
    @State private var showingEdit = false
    @State private var showingDeleteConfirm = false

    private var attempts: [Attempt] { session.orderedAttempts }

    var body: some View {
        ZStack {
            Brand.pageBackground

            ScrollView {
                VStack(spacing: 14) {
                    header

                    if attempts.isEmpty {
                        GlassCard {
                            VStack(spacing: 10) {
                                Image(systemName: "figure.climbing")
                                    .font(.system(size: 34, weight: .light))
                                    .foregroundStyle(Brand.text3)
                                    .accessibilityHidden(true)
                                Text("No attempts logged")
                                    .font(.headline)
                                    .foregroundStyle(Brand.text)
                                Text("Add the climbs you tried this session — Strata tracks each attempt in order.")
                                    .font(.subheadline)
                                    .foregroundStyle(Brand.text2)
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }
                    } else {
                        VStack(spacing: 10) {
                            ForEach(Array(attempts.enumerated()), id: \.element.id) { idx, attempt in
                                AttemptRow(attempt: attempt, position: idx + 1)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            delete(attempt)
                                        } label: {
                                            Label("Delete attempt", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                    }

                    InkButton(title: "Add attempt", systemImage: "plus") {
                        showingAddAttempt = true
                    }
                    .padding(.top, 4)

                    if !session.notes.isEmpty {
                        GlassCard {
                            VStack(alignment: .leading, spacing: 6) {
                                SectionLabel(text: "Notes")
                                Text(session.notes)
                                    .font(.subheadline)
                                    .foregroundStyle(Brand.text2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
        }
        .navigationTitle(session.date.formatted(date: .abbreviated, time: .omitted))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showingEdit = true } label: {
                        Label("Edit session", systemImage: "pencil")
                    }
                    Button(role: .destructive) { showingDeleteConfirm = true } label: {
                        Label("Delete session", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Session options")
            }
        }
        .sheet(isPresented: $showingAddAttempt) {
            AddAttemptView(session: session)
        }
        .sheet(isPresented: $showingEdit) {
            SessionEditView(session: session, isNew: false)
        }
        .alert("Delete this session?", isPresented: $showingDeleteConfirm) {
            Button("Delete", role: .destructive) { deleteSession() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This removes the session and all \(session.attemptCount) of its attempts. This can't be undone.")
        }
    }

    private var header: some View {
        GlassCard {
            VStack(spacing: 14) {
                if let location = session.location {
                    HStack {
                        Label(location.name, systemImage: location.kind.symbol)
                            .font(.headline)
                            .foregroundStyle(Brand.text)
                        Spacer()
                        Text(location.kind.title)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Brand.text3)
                    }
                }
                HStack(spacing: 12) {
                    StatTile(value: "\(session.attemptCount)", caption: "Attempts")
                    Divider().frame(height: 34)
                    StatTile(value: "\(session.sendCount)", caption: "Sends", tint: Brand.send)
                    Divider().frame(height: 34)
                    StatTile(value: session.durationLabel, caption: "Duration")
                }
            }
        }
    }

    private func delete(_ attempt: Attempt) {
        context.delete(attempt)
        Haptics.warning(enabled: settings.hapticsEnabled)
    }

    private func deleteSession() {
        context.delete(session)
        Haptics.warning(enabled: settings.hapticsEnabled)
        dismiss()
    }
}

/// A single attempt row inside session detail.
struct AttemptRow: View {
    @Environment(SettingsStore.self) private var settings
    var attempt: Attempt
    var position: Int

    private var grade: String {
        attempt.gradeLabel(boulderSystem: settings.boulderSystem, routeSystem: settings.routeSystem)
    }

    var body: some View {
        GlassCard(padding: 12) {
            HStack(spacing: 12) {
                Text("\(position)")
                    .font(Brand.mono(14, weight: .semibold))
                    .foregroundStyle(Brand.text3)
                    .frame(width: 22, alignment: .trailing)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(attempt.climbName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Brand.text)
                            .lineLimit(1)
                        if let climb = attempt.climb, climb.hasColor {
                            HoldColorDot(index: climb.colorIndex)
                        }
                    }
                    GradePill(label: grade)
                }
                Spacer(minLength: 8)
                OutcomeBadge(outcome: attempt.outcome, compact: true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Attempt \(position): \(attempt.climbName), grade \(grade), \(attempt.outcome.title)")
    }
}

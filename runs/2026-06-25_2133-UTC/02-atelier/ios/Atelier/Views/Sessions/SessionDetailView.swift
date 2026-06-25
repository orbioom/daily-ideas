import SwiftUI
import SwiftData

struct SessionDetailView: View {
    @Bindable var session: ArtSession
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var showingEdit = false
    @State private var showingDelete = false

    private static let df: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .long; f.timeStyle = .short; return f
    }()

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                heroSection
                detailsGrid
                if !session.skillWorked.isEmpty {
                    skillSection
                }
                if !session.notes.isEmpty {
                    notesSection
                }
            }
            .padding()
        }
        .navigationTitle(session.subject.isEmpty ? "Session" : session.subject)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button { showingEdit = true } label: {
                    Image(systemName: "pencil")
                }
                .foregroundStyle(AtelierTheme.amber)
                .accessibilityLabel("Edit session")

                Button(role: .destructive) { showingDelete = true } label: {
                    Image(systemName: "trash")
                }
                .foregroundStyle(.red)
                .accessibilityLabel("Delete session")
            }
        }
        .sheet(isPresented: $showingEdit) { SessionFormView(session: session) }
        .confirmationDialog("Delete this session?", isPresented: $showingDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                context.delete(session); try? context.save(); dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: { Text("This cannot be undone.") }
    }

    private var heroSection: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(Self.df.string(from: session.date))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                MediumBadge(medium: session.medium)
                AtelierRatingView(rating: session.rating, size: 16)
            }
            Spacer()
            VStack(spacing: 4) {
                Text(session.mood.emoji).font(.system(size: 36))
                Text(session.mood.rawValue).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 5, x: 0, y: 2)
    }

    private var detailsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            InfoCell(icon: "clock.fill", title: "Duration", value: session.durationFormatted)
            InfoCell(icon: "tag.fill", title: "Type", value: session.practiceType.rawValue)
            if !session.subject.isEmpty {
                InfoCell(icon: "pencil", title: "Subject", value: session.subject)
            }
        }
    }

    private var skillSection: some View {
        HStack {
            Label("Skill Practiced", systemImage: "list.star")
                .font(.headline)
            Spacer()
            Text(session.skillWorked)
                .font(.subheadline)
                .foregroundStyle(AtelierTheme.amber)
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Notes", systemImage: "note.text").font(.headline)
            Text(session.notes).font(.body).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Notes: \(session.notes)")
    }
}

struct InfoCell: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundStyle(AtelierTheme.amber).frame(width: 22).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption).foregroundStyle(.secondary)
                Text(value).font(.subheadline.bold())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

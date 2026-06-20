import SwiftUI
import SwiftData

struct TechniqueDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var technique: Technique

    @State private var showDeleteAlert = false
    @State private var drillAnimating = false

    var body: some View {
        ZStack {
            DojoTheme.darkBg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {

                    // Header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(DojoTheme.crimson.opacity(0.15))
                                .frame(width: 80, height: 80)
                            Image(systemName: technique.techniqueCategory.icon)
                                .font(.system(size: 34))
                                .foregroundColor(DojoTheme.crimson)
                        }

                        VStack(spacing: 6) {
                            Text(technique.name)
                                .font(.title.bold())
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)

                            Text(technique.category)
                                .font(.subheadline)
                                .foregroundColor(DojoTheme.subtleText)
                        }

                        // Favorite + Drill count row
                        HStack(spacing: 24) {
                            Button {
                                technique.isFavorite.toggle()
                            } label: {
                                Label(
                                    technique.isFavorite ? "Favorited" : "Favorite",
                                    systemImage: technique.isFavorite ? "star.fill" : "star"
                                )
                                .font(.subheadline)
                                .foregroundColor(technique.isFavorite ? DojoTheme.gold : DojoTheme.subtleText)
                            }

                            Divider()
                                .frame(height: 20)
                                .background(DojoTheme.subtleText)

                            HStack(spacing: 6) {
                                Image(systemName: "repeat")
                                    .font(.caption)
                                    .foregroundColor(DojoTheme.subtleText)
                                Text("\(technique.drillCount) drills")
                                    .font(.subheadline)
                                    .foregroundColor(DojoTheme.subtleText)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .cardStyle()
                    .padding(.horizontal)

                    // Drill button
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                            drillAnimating = true
                            technique.drillCount += 1
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            drillAnimating = false
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                            Text("Mark as Drilled")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(DojoTheme.crimson)
                        .cornerRadius(12)
                        .scaleEffect(drillAnimating ? 1.05 : 1.0)
                    }
                    .padding(.horizontal)

                    // Notes section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("NOTES")
                            .font(.caption.bold())
                            .foregroundColor(DojoTheme.subtleText)
                            .padding(.horizontal)

                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $technique.notes)
                                .frame(minHeight: 120)
                                .padding(12)
                                .foregroundColor(.white)
                                .tint(DojoTheme.crimson)
                                .scrollContentBackground(.hidden)
                                .background(DojoTheme.cardBg)
                                .cornerRadius(12)

                            if technique.notes.isEmpty {
                                Text("Add notes, key details, or setups...")
                                    .foregroundColor(DojoTheme.tertiaryText)
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 20)
                                    .allowsHitTesting(false)
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Added date
                    Text("Added \(technique.addedDate, format: .dateTime.month().day().year())")
                        .font(.caption)
                        .foregroundColor(DojoTheme.tertiaryText)

                    // Delete button
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("Delete Technique", systemImage: "trash")
                            .font(.headline)
                            .foregroundColor(DojoTheme.crimson)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(DojoTheme.crimson.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
                .padding(.top, 16)
            }
        }
        .navigationTitle(technique.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(DojoTheme.darkBg, for: .navigationBar)
        .alert("Delete Technique?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                modelContext.delete(technique)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }
}

#Preview {
    NavigationStack {
        TechniqueDetailView(technique: Technique(
            name: "Triangle Choke",
            category: TechniqueCategory.submissions.rawValue,
            notes: "Lock the triangle from guard. Control the head.",
            isFavorite: true,
            drillCount: 42
        ))
    }
    .modelContainer(for: [Technique.self], inMemory: true)
}

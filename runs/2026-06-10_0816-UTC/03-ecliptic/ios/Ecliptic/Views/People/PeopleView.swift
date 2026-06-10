import SwiftUI
import SwiftData

/// All saved charts: yours plus friends, family, anyone.
struct PeopleView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ChartProfile.createdAt) private var profiles: [ChartProfile]
    @State private var showEditor = false
    @State private var editTarget: ChartProfile?
    @State private var deleteTarget: ChartProfile?

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if profiles.isEmpty {
                    EmptyStateView(
                        icon: "person.2",
                        title: "No charts saved",
                        message: "Add yourself first, then anyone whose chart you're curious about. Everything stays on this device."
                    )
                } else {
                    List {
                        ForEach(profiles) { profile in
                            NavigationLink(value: profile) {
                                row(profile)
                            }
                            .listRowBackground(Color.clear)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    deleteTarget = profile
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                Button {
                                    editTarget = profile
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.indigo)
                            }
                            .swipeActions(edge: .leading) {
                                if !profile.isPrimary {
                                    Button {
                                        for p in profiles { p.isPrimary = false }
                                        profile.isPrimary = true
                                        Haptics.success()
                                    } label: {
                                        Label("Make primary", systemImage: "star")
                                    }
                                    .tint(.teal)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("People")
            .navigationDestination(for: ChartProfile.self) { profile in
                ZStack {
                    Brand.pageBackground
                    ChartScreen(profile: profile)
                }
                .navigationTitle(profile.name)
                .navigationBarTitleDisplayMode(.inline)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showEditor = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add chart")
                }
            }
            .sheet(isPresented: $showEditor) {
                ProfileEditorView(profile: nil)
            }
            .sheet(item: $editTarget) { profile in
                ProfileEditorView(profile: profile)
            }
            .alert("Delete this chart?", isPresented: Binding(
                get: { deleteTarget != nil },
                set: { if !$0 { deleteTarget = nil } }
            )) {
                Button("Delete", role: .destructive) {
                    if let p = deleteTarget {
                        context.delete(p)
                        Haptics.warning()
                    }
                    deleteTarget = nil
                }
                Button("Cancel", role: .cancel) { deleteTarget = nil }
            } message: {
                Text("The birth data is removed from this device.")
            }
        }
    }

    private func row(_ profile: ChartProfile) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 40, height: 40)
                    .overlay(Circle().strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: 1))
                Text(Sign.at(longitude: Astronomy.sunLongitude(jd: Astronomy.julianDay(profile.birthDate))).glyph)
                    .font(.body)
            }
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(profile.name)
                        .font(.headline)
                        .foregroundStyle(Brand.text)
                    if profile.isPrimary {
                        StatusDot()
                    }
                }
                Text(profile.birthDescription)
                    .font(.caption)
                    .foregroundStyle(Brand.text3)
            }
            Spacer()
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(profile.name)\(profile.isPrimary ? ", primary chart" : ""), born \(profile.birthDescription)")
    }
}

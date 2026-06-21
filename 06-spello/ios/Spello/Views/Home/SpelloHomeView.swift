import SwiftUI
import SwiftData

struct SpelloHomeView: View {
    @Query private var profiles: [SpelloProfile]
    @Query private var prefs: [SpelloPrefs]
    @Environment(\.modelContext) private var ctx
    @State private var showAddProfile = false
    @State private var newName = ""
    @State private var newGrade = 1

    private let accent = Color(red: 0.95, green: 0.55, blue: 0.15)

    private var activeProfile: SpelloProfile? {
        guard let id = prefs.first?.activeProfileId else { return profiles.first }
        return profiles.first(where: { $0.id == id }) ?? profiles.first
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if profiles.isEmpty {
                    emptyState
                } else {
                    profilePicker
                    if let p = activeProfile {
                        gradeCard(p)
                    }
                    Spacer()
                }
            }
            .padding()
            .navigationTitle("Spello")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddProfile = true } label: {
                        Image(systemName: "person.badge.plus")
                    }
                    .foregroundStyle(accent)
                }
            }
            .sheet(isPresented: $showAddProfile) { addProfileSheet }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 60))
                .foregroundStyle(accent)
            Text("Create a Profile").font(.title.weight(.bold))
            Text("Add a child profile to start practicing!")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Add Profile") { showAddProfile = true }
                .buttonStyle(.borderedProminent)
                .tint(accent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var profilePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(profiles) { p in
                    let isActive = p.id == (prefs.first?.activeProfileId ?? profiles.first?.id)
                    Button(action: { setActive(p) }) {
                        VStack(spacing: 4) {
                            Image(systemName: "person.circle.fill")
                                .font(.title2)
                                .foregroundStyle(isActive ? accent : .secondary)
                            Text(p.name)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(isActive ? .primary : .secondary)
                            Text("Grade \(p.gradeLevel)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(isActive ? accent.opacity(0.15) : Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay {
                            if isActive {
                                RoundedRectangle(cornerRadius: 12).stroke(accent, lineWidth: 1.5)
                            }
                        }
                    }
                }
            }
        }
    }

    private func gradeCard(_ p: SpelloProfile) -> some View {
        VStack(spacing: 12) {
            Text("Hi, \(p.name)! 👋")
                .font(.title2.weight(.bold))
            Text("Grade \(p.gradeLevel) Words")
                .font(.headline)
                .foregroundStyle(accent)
            Text("\(spelloWords[p.gradeLevel]?.count ?? 0) words in your list")
                .font(.callout)
                .foregroundStyle(.secondary)
            NavigationLink(destination: SpelloPracticeView()) {
                Label("Practice Now", systemImage: "play.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var addProfileSheet: some View {
        NavigationStack {
            Form {
                Section("Child's Name") {
                    TextField("Name", text: $newName)
                }
                Section("Grade Level") {
                    Picker("Grade", selection: $newGrade) {
                        ForEach(1...5, id: \.self) { g in
                            Text("Grade \(g)").tag(g)
                        }
                    }
                    .pickerStyle(.inline)
                }
            }
            .navigationTitle("Add Profile")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { showAddProfile = false }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        guard !newName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        let p = SpelloProfile(name: newName.trimmingCharacters(in: .whitespaces), gradeLevel: newGrade)
                        ctx.insert(p)
                        setActive(p)
                        newName = ""
                        newGrade = 1
                        showAddProfile = false
                    }
                    .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func setActive(_ p: SpelloProfile) {
        let pref = prefs.first ?? SpelloPrefs()
        if prefs.isEmpty { ctx.insert(pref) }
        pref.activeProfileId = p.id
    }
}

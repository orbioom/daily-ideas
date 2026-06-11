import SwiftUI
import SwiftData

struct TermSettingsView: View {
    @Query private var terms: [AcademicTerm]
    @Environment(\.modelContext) private var ctx
    @AppStorage("showGPAInTab") private var showGPAInTab = true
    @AppStorage("overdueAlerts") private var overdueAlerts = true
    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Display") {
                    Toggle("Show GPA on Courses tab", isOn: $showGPAInTab)
                        .tint(TermTheme.accent)
                        .accessibilityLabel("Show GPA in courses tab bar")
                    Toggle("Overdue alerts badge", isOn: $overdueAlerts)
                        .tint(TermTheme.accent)
                        .accessibilityLabel("Show badge for overdue assignments")
                }

                Section("Terms") {
                    ForEach(terms) { term in
                        HStack {
                            Text(term.name)
                            Spacer()
                            if term.isActive {
                                Text("Active")
                                    .font(.caption.bold())
                                    .foregroundStyle(TermTheme.accent)
                            }
                            Toggle("", isOn: Binding(
                                get: { term.isActive },
                                set: { newVal in
                                    if newVal {
                                        terms.forEach { $0.isActive = false }
                                    }
                                    term.isActive = newVal
                                }
                            ))
                            .labelsHidden()
                            .tint(TermTheme.accent)
                        }
                    }
                }

                Section("About") {
                    HStack { Text("Version"); Spacer(); Text("1.0").foregroundStyle(TermTheme.subtle) }
                    HStack { Text("Data storage"); Spacer(); Text("On-device only").font(.caption).foregroundStyle(TermTheme.subtle) }
                    HStack { Text("GPA scale"); Spacer(); Text("4.0 (US standard)").font(.caption).foregroundStyle(TermTheme.subtle) }
                }

                Section {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete All Data", systemImage: "trash")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(TermTheme.bg)
            .navigationTitle("Settings")
            .confirmationDialog("Delete All Data?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Delete Everything", role: .destructive) { deleteAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently remove all terms, courses, and assignments. This cannot be undone.")
            }
        }
    }

    private func deleteAll() {
        terms.forEach { ctx.delete($0) }
    }
}

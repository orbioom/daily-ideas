import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// Real, persisted preferences. Every control here changes behavior and survives
/// relaunch. Also hosts data export (CSV/JSON) and reset/clear.
struct SettingsView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var context
    @Query private var sessions: [Session]
    @Query private var climbs: [Climb]
    @Query(sort: \Location.name) private var locations: [Location]

    @State private var showingResetConfirm = false
    @State private var showingClearConfirm = false
    @State private var toast: String?
    @State private var exportDoc: TextDocument?
    @State private var exportName = "strata-export"

    var body: some View {
        @Bindable var settings = settings

        NavigationStack {
            Form {
                Section("Appearance") {
                    Picker("Theme", selection: $settings.appearance) {
                        ForEach(SettingsStore.Appearance.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    Picker("Boulder grades", selection: $settings.boulderSystem) {
                        Text("V-Scale").tag(GradeSystem.vScale)
                        Text("Font").tag(GradeSystem.font)
                    }
                    Picker("Route grades", selection: $settings.routeSystem) {
                        Text("YDS").tag(GradeSystem.yds)
                        Text("French").tag(GradeSystem.french)
                    }
                } header: {
                    Text("Grade display")
                } footer: {
                    Text("Grades are stored once and converted on display. Switch any time — your history stays intact.")
                }

                Section {
                    Picker("Default discipline", selection: $settings.defaultDiscipline) {
                        ForEach(Discipline.allCases) { d in
                            Text(d.title).tag(d)
                        }
                    }
                    Picker("Default location", selection: $settings.defaultLocationID) {
                        Text("None").tag("")
                        ForEach(locations) { location in
                            Text(location.name).tag(location.id.uuidString)
                        }
                    }
                    Toggle("Haptic feedback", isOn: $settings.hapticsEnabled)
                } header: {
                    Text("New climbs & sessions")
                } footer: {
                    Text("Defaults preselect the next climb or session you create.")
                }

                Section {
                    Button {
                        prepareExport(.csv)
                    } label: {
                        Label("Export attempts (CSV)", systemImage: "tablecells")
                    }
                    Button {
                        prepareExport(.climbsCSV)
                    } label: {
                        Label("Export climbs (CSV)", systemImage: "list.bullet.rectangle")
                    }
                    Button {
                        prepareExport(.json)
                    } label: {
                        Label("Export everything (JSON)", systemImage: "curlybraces")
                    }
                } header: {
                    Text("Export")
                } footer: {
                    Text("Save your logbook as a spreadsheet-friendly CSV or a complete JSON archive.")
                }

                Section {
                    statRow("Sessions", sessions.count, icon: "list.bullet.rectangle")
                    statRow("Climbs", climbs.count, icon: "mountain.2")
                    statRow("Attempts", sessions.reduce(0) { $0 + $1.attemptCount }, icon: "figure.climbing")
                    statRow("Locations", locations.count, icon: "mappin.and.ellipse")
                } header: {
                    Text("Your data")
                } footer: {
                    Text("Everything stays on this device, stored with SwiftData. Nothing leaves your phone unless you export it.")
                }

                Section("Manage") {
                    Button {
                        showingResetConfirm = true
                    } label: {
                        Label("Reset to sample data", systemImage: "arrow.counterclockwise")
                    }
                    Button(role: .destructive) {
                        showingClearConfirm = true
                    } label: {
                        Label("Clear all data", systemImage: "trash")
                    }
                }

                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0").font(Brand.mono(15)).foregroundStyle(Brand.text3)
                    }
                    HStack {
                        Text("Made by")
                        Spacer()
                        Text("Orbioom").foregroundStyle(Brand.text2)
                    }
                } header: {
                    Text("About")
                } footer: {
                    Text("Strata — conjured, not just coded.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle("Settings")
            .alert("Reset to sample data?", isPresented: $showingResetConfirm) {
                Button("Reset", role: .destructive) { resetToSample() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This replaces everything currently in Strata with the original sample logbook.")
            }
            .alert("Clear all data?", isPresented: $showingClearConfirm) {
                Button("Delete everything", role: .destructive) { clearAll() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Every session, climb, attempt, and location will be permanently removed. This can't be undone.")
            }
            .fileExporter(
                isPresented: Binding(
                    get: { exportDoc != nil },
                    set: { if !$0 { exportDoc = nil } }
                ),
                document: exportDoc,
                contentType: exportDoc?.contentType ?? .plainText,
                defaultFilename: exportName
            ) { result in
                switch result {
                case .success: flash("Export saved")
                case .failure: flash("Export cancelled")
                }
                exportDoc = nil
            }
            .overlay(alignment: .bottom) {
                if let toast { ToastView(message: toast) }
            }
        }
    }

    private func statRow(_ label: String, _ value: Int, icon: String) -> some View {
        HStack {
            Label(label, systemImage: icon)
            Spacer()
            Text("\(value)").font(Brand.mono(15)).foregroundStyle(Brand.text2)
        }
    }

    // MARK: - Export

    private enum ExportKind { case csv, climbsCSV, json }

    private func prepareExport(_ kind: ExportKind) {
        let bSys = settings.boulderSystem
        let rSys = settings.routeSystem
        switch kind {
        case .csv:
            let text = Exporter.attemptsCSV(sessions: sessions, boulderSystem: bSys, routeSystem: rSys)
            exportName = "strata-attempts"
            exportDoc = TextDocument(text: text, contentType: .commaSeparatedText)
        case .climbsCSV:
            let text = Exporter.climbsCSV(climbs: climbs, boulderSystem: bSys, routeSystem: rSys)
            exportName = "strata-climbs"
            exportDoc = TextDocument(text: text, contentType: .commaSeparatedText)
        case .json:
            let text = Exporter.json(sessions: sessions, climbs: climbs,
                                     boulderSystem: bSys, routeSystem: rSys)
                ?? "{}"
            exportName = "strata-export"
            exportDoc = TextDocument(text: text, contentType: .json)
        }
    }

    // MARK: - Manage

    private func resetToSample() {
        do {
            try SampleData.clear(context)
            SampleData.insert(into: context)
            Haptics.success(enabled: settings.hapticsEnabled)
            flash("Sample data restored")
        } catch {
            flash("Couldn't reset — please try again")
        }
    }

    private func clearAll() {
        do {
            try SampleData.clear(context)
            Haptics.warning(enabled: settings.hapticsEnabled)
            flash("All data cleared")
        } catch {
            flash("Couldn't clear — please try again")
        }
    }

    private func flash(_ message: String) {
        withAnimation(Brand.ease()) { toast = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(Brand.ease()) { toast = nil }
        }
    }
}

/// A lightweight in-memory text document for `.fileExporter`.
struct TextDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText, .commaSeparatedText, .json] }

    var text: String
    var contentType: UTType

    init(text: String, contentType: UTType) {
        self.text = text
        self.contentType = contentType
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            text = String(decoding: data, as: UTF8.self)
        } else {
            text = ""
        }
        contentType = .plainText
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }
}

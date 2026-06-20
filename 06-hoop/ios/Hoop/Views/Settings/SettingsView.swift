import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("defaultTeamA") private var defaultTeamA = "Home"
    @AppStorage("defaultTeamB") private var defaultTeamB = "Away"
    @AppStorage("defaultQuarterMinutes") private var defaultQuarterMinutes = 10
    @AppStorage("defaultTimeouts") private var defaultTimeouts = 5
    
    @Query private var games: [HoopGame]
    @Environment(\.modelContext) private var modelContext
    @State private var showingClearConfirm = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                HoopTheme.darkBg.ignoresSafeArea()
                
                List {
                    Section {
                        HStack {
                            Text("Team A Default")
                                .foregroundStyle(.white)
                            Spacer()
                            TextField("Home", text: $defaultTeamA)
                                .multilineTextAlignment(.trailing)
                                .foregroundStyle(HoopTheme.subtleText)
                        }
                        HStack {
                            Text("Team B Default")
                                .foregroundStyle(.white)
                            Spacer()
                            TextField("Away", text: $defaultTeamB)
                                .multilineTextAlignment(.trailing)
                                .foregroundStyle(HoopTheme.subtleText)
                        }
                    } header: {
                        Text("Default Team Names")
                            .foregroundStyle(HoopTheme.subtleText)
                    }
                    .listRowBackground(HoopTheme.cardBg)
                    
                    Section {
                        Picker("Period Length", selection: $defaultQuarterMinutes) {
                            Text("8 minutes").tag(8)
                            Text("10 minutes").tag(10)
                            Text("12 minutes").tag(12)
                        }
                        .foregroundStyle(.white)
                        
                        Stepper("Timeouts: \(defaultTimeouts)", value: $defaultTimeouts, in: 3...7)
                            .foregroundStyle(.white)
                    } header: {
                        Text("Game Defaults")
                            .foregroundStyle(HoopTheme.subtleText)
                    }
                    .listRowBackground(HoopTheme.cardBg)
                    
                    Section {
                        Button(role: .destructive) {
                            showingClearConfirm = true
                        } label: {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text("Clear Game History")
                            }
                        }
                        .disabled(games.isEmpty)
                    } header: {
                        Text("Data")
                            .foregroundStyle(HoopTheme.subtleText)
                    } footer: {
                        Text("\(games.count) game\(games.count == 1 ? "" : "s") saved")
                            .foregroundStyle(HoopTheme.subtleText)
                    }
                    .listRowBackground(HoopTheme.cardBg)
                    
                    Section {
                        HStack {
                            Text("Version")
                                .foregroundStyle(.white)
                            Spacer()
                            Text("1.0.0")
                                .foregroundStyle(HoopTheme.subtleText)
                        }
                        HStack {
                            Text("Stack")
                                .foregroundStyle(.white)
                            Spacer()
                            Text("SwiftUI · SwiftData")
                                .foregroundStyle(HoopTheme.subtleText)
                        }
                    } header: {
                        Text("About")
                            .foregroundStyle(HoopTheme.subtleText)
                    }
                    .listRowBackground(HoopTheme.cardBg)
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .alert("Clear History?", isPresented: $showingClearConfirm) {
            Button("Clear All", role: .destructive) {
                for game in games { modelContext.delete(game) }
                try? modelContext.save()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all \(games.count) saved game\(games.count == 1 ? "" : "s").")
        }
    }
}

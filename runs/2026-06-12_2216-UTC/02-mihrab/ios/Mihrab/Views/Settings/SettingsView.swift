import SwiftUI

struct SettingsView: View {
    @AppStorage("cityID") private var cityID = Gazetteer.defaultCityID
    @AppStorage("method") private var methodRaw = CalculationMethod.mwl.rawValue
    @AppStorage("hanafiAsr") private var hanafiAsr = false
    @AppStorage("use24Hour") private var use24Hour = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true

    @State private var showingPermissionDenied = false

    private var city: City { Gazetteer.city(id: cityID) ?? Gazetteer.cities[0] }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    NavigationLink {
                        CityPickerView(selectedID: $cityID)
                    } label: {
                        LabeledContent("City", value: city.displayName)
                    }
                    Picker("Method", selection: $methodRaw) {
                        ForEach(CalculationMethod.allCases) { method in
                            Text(method.displayName).tag(method.rawValue)
                        }
                    }
                    Picker("Asr juristic", selection: $hanafiAsr) {
                        Text("Standard (Shafi'i, Maliki, Hanbali)").tag(false)
                        Text("Hanafi").tag(true)
                    }
                } header: {
                    Text("Calculation")
                } footer: {
                    Text("Times are computed astronomically on this device for the chosen city — no location permission, no network. At extreme latitudes the middle-of-the-night rule fills in Fajr and Isha when the sun never reaches the required angle.")
                }

                Section("Display") {
                    Toggle("24-hour clock", isOn: $use24Hour)
                    Toggle("Haptics", isOn: $hapticsEnabled)
                }

                Section {
                    Toggle("Prayer time alerts", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { _, enabled in
                            guard enabled else {
                                Task { await NotificationScheduler.reschedule(enabled: false) }
                                return
                            }
                            Task {
                                let granted = await NotificationScheduler.requestPermission()
                                if granted {
                                    await NotificationScheduler.reschedule(enabled: true)
                                } else {
                                    notificationsEnabled = false
                                    showingPermissionDenied = true
                                }
                            }
                        }
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("A local notification at each of the five prayers. Scheduled on your device; nothing is sent to any server.")
                }

                Section {
                    LabeledContent("Qibla bearing", value: "\(Int(PrayerEngine.qiblaBearing(latitude: city.latitude, longitude: city.longitude).rounded()))° from north")
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Your data", value: "Never leaves this device")
                } header: {
                    Text("About")
                } footer: {
                    Text("Mihrab asks for no account, no location, and shows no ads. It was built so that worship never becomes someone else's data.")
                }
            }
            .navigationTitle("Settings")
            .alert("Notifications Are Off", isPresented: $showingPermissionDenied) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Allow notifications for Mihrab in the Settings app to receive prayer alerts.")
            }
        }
    }
}

struct CityPickerView: View {
    @Binding var selectedID: String
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""

    private var filtered: [City] {
        let all = Gazetteer.cities.sorted { $0.name < $1.name }
        guard !search.trimmingCharacters(in: .whitespaces).isEmpty else { return all }
        let needle = search.lowercased()
        return all.filter {
            $0.name.lowercased().contains(needle) || $0.country.lowercased().contains(needle)
        }
    }

    var body: some View {
        List {
            if filtered.isEmpty {
                ContentUnavailableView.search(text: search)
            } else {
                ForEach(filtered) { city in
                    Button {
                        Haptics.tap()
                        selectedID = city.id
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(city.name)
                                    .foregroundStyle(.primary)
                                Text(city.country)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if city.id == selectedID {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(MihrabTheme.gold)
                            }
                        }
                    }
                    .accessibilityLabel("\(city.displayName)\(city.id == selectedID ? ", selected" : "")")
                }
            }
        }
        .searchable(text: $search, prompt: "Search city or country")
        .navigationTitle("Choose City")
        .navigationBarTitleDisplayMode(.inline)
    }
}

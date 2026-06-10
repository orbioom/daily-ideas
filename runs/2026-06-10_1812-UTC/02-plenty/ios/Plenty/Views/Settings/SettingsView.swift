import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("appearance") private var appearance = "system"
    @AppStorage("morningOn") private var morningOn = false
    @AppStorage("morningHour") private var morningHour = 8
    @AppStorage("morningMinute") private var morningMinute = 0
    @AppStorage("eveningOn") private var eveningOn = false
    @AppStorage("eveningHour") private var eveningHour = 21
    @AppStorage("eveningMinute") private var eveningMinute = 0
    @State private var permissionDenied = false

    @Query private var days: [GratitudeDay]

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section {
                        reminderToggle(title: "Morning reminder", on: $morningOn,
                                       hour: $morningHour, minute: $morningMinute,
                                       id: "plenty.morning",
                                       notifTitle: "Good morning",
                                       notifBody: "Take a minute to name three things you're grateful for.")
                        reminderToggle(title: "Evening reminder", on: $eveningOn,
                                       hour: $eveningHour, minute: $eveningMinute,
                                       id: "plenty.evening",
                                       notifTitle: "Wind down",
                                       notifBody: "Reflect on three good things from today.")
                    } header: { Text("Reminders") } footer: {
                        if permissionDenied {
                            Text("Notifications are off for Plenty. Enable them in the Settings app.")
                                .foregroundStyle(Brand.danger)
                        }
                    }

                    Section("Appearance") {
                        Picker("Theme", selection: $appearance) {
                            Text("System").tag("system")
                            Text("Light").tag("light")
                            Text("Dark").tag("dark")
                        }
                    }

                    Section("Feedback") {
                        Toggle("Haptics", isOn: $hapticsEnabled)
                            .onChange(of: hapticsEnabled) { _, v in Haptics.enabled = v }
                    }

                    Section {
                        HStack {
                            Text("Days recorded")
                            Spacer()
                            Text("\(days.filter { $0.hasAnyContent }.count)")
                                .foregroundStyle(Brand.text3).font(Brand.mono(15))
                        }
                    } header: { Text("About") } footer: {
                        Text("Plenty stores everything on your device only. Your reflections are private.")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
        }
    }

    @ViewBuilder
    private func reminderToggle(title: String, on: Binding<Bool>, hour: Binding<Int>, minute: Binding<Int>,
                                id: String, notifTitle: String, notifBody: String) -> some View {
        let timeBinding = Binding<Date>(
            get: { Calendar.current.date(from: DateComponents(hour: hour.wrappedValue, minute: minute.wrappedValue)) ?? .now },
            set: { newValue in
                let c = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                hour.wrappedValue = c.hour ?? 8
                minute.wrappedValue = c.minute ?? 0
                if on.wrappedValue {
                    Reminders.schedule(id: id, title: notifTitle, body: notifBody,
                                       hour: hour.wrappedValue, minute: minute.wrappedValue)
                }
            }
        )
        Toggle(title, isOn: on)
            .onChange(of: on.wrappedValue) { _, isOn in
                if isOn {
                    Task {
                        let granted = await Reminders.requestAuthorization()
                        await MainActor.run {
                            if granted {
                                permissionDenied = false
                                Reminders.schedule(id: id, title: notifTitle, body: notifBody,
                                                   hour: hour.wrappedValue, minute: minute.wrappedValue)
                            } else {
                                permissionDenied = true
                                on.wrappedValue = false
                            }
                        }
                    }
                } else {
                    Reminders.cancel(id: id)
                }
            }
        if on.wrappedValue {
            DatePicker("Time", selection: timeBinding, displayedComponents: .hourAndMinute)
        }
    }
}

import SwiftUI
import SwiftData

struct AppointmentsView: View {
    @Query(sort: \TattooAppointment.date) private var appointments: [TattooAppointment]
    @Environment(\.modelContext) private var modelContext
    @State private var showAdd = false

    var upcoming: [TattooAppointment] { appointments.filter { !$0.isCompleted && $0.date >= Date() } }
    var past: [TattooAppointment] { appointments.filter { $0.isCompleted || $0.date < Date() } }

    var body: some View {
        ZStack {
            InkTheme.background.ignoresSafeArea()
            if appointments.isEmpty {
                emptyState
            } else {
                List {
                    if !upcoming.isEmpty {
                        Section {
                            ForEach(upcoming) { apt in
                                AppointmentRow(appointment: apt)
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            modelContext.delete(apt)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                        Button {
                                            apt.isCompleted = true
                                        } label: {
                                            Label("Done", systemImage: "checkmark")
                                        }
                                        .tint(.green)
                                    }
                            }
                        } header: {
                            Text("Upcoming").foregroundStyle(InkTheme.textSecondary)
                        }
                        .listRowBackground(InkTheme.surface)
                    }

                    if !past.isEmpty {
                        Section {
                            ForEach(past) { apt in
                                AppointmentRow(appointment: apt)
                                    .swipeActions {
                                        Button(role: .destructive) {
                                            modelContext.delete(apt)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        } header: {
                            Text("Completed / Past").foregroundStyle(InkTheme.textSecondary)
                        }
                        .listRowBackground(InkTheme.surface)
                    }

                    summarySection
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Appointments")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(InkTheme.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAdd = true } label: {
                    Image(systemName: "plus").foregroundStyle(InkTheme.accent)
                }
            }
        }
        .sheet(isPresented: $showAdd) { AddAppointmentView() }
    }

    var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 52))
                .foregroundStyle(InkTheme.textSecondary)
            Text("No Appointments")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(InkTheme.textPrimary)
            Text("Book a tattoo session and track it here.")
                .font(.system(size: 15))
                .foregroundStyle(InkTheme.textSecondary)
            Button { showAdd = true } label: {
                Text("Add Appointment")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(InkTheme.accent, in: Capsule())
            }
        }
    }

    var summarySection: some View {
        let totalSpent = past.reduce(0) { $0 + $1.totalCost }
        let totalDeposits = appointments.reduce(0) { $0 + $1.depositPaid }
        return Section {
            HStack {
                Text("Total Spent").foregroundStyle(InkTheme.textSecondary)
                Spacer()
                Text("$\(Int(totalSpent))").foregroundStyle(InkTheme.accentOrange)
                    .font(.system(size: 16, weight: .bold))
            }
            HStack {
                Text("Deposits Paid").foregroundStyle(InkTheme.textSecondary)
                Spacer()
                Text("$\(Int(totalDeposits))").foregroundStyle(InkTheme.textPrimary)
            }
            HStack {
                Text("Sessions").foregroundStyle(InkTheme.textSecondary)
                Spacer()
                Text("\(appointments.count)").foregroundStyle(InkTheme.textPrimary)
            }
        } header: {
            Text("Summary").foregroundStyle(InkTheme.textSecondary)
        }
        .listRowBackground(InkTheme.surface)
    }
}

struct AppointmentRow: View {
    let appointment: TattooAppointment

    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 4) {
                Text(dayString)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(appointment.isCompleted ? InkTheme.textSecondary : InkTheme.accent)
                Text(monthString)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(InkTheme.textSecondary)
            }
            .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(appointment.title.isEmpty ? "Tattoo Session" : appointment.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(appointment.isCompleted ? InkTheme.textSecondary : InkTheme.textPrimary)
                HStack(spacing: 8) {
                    if !appointment.artistName.isEmpty {
                        Text(appointment.artistName)
                            .font(.system(size: 13))
                            .foregroundStyle(InkTheme.textSecondary)
                    }
                    if appointment.estimatedHours > 0 {
                        Text("· \(appointment.estimatedHours, specifier: "%.1f")h")
                            .font(.system(size: 13))
                            .foregroundStyle(InkTheme.textSecondary)
                    }
                }
                if appointment.totalCost > 0 {
                    Text("$\(Int(appointment.totalCost))")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(InkTheme.accentOrange)
                }
            }

            Spacer()

            if appointment.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 4)
    }

    var dayString: String {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f.string(from: appointment.date)
    }

    var monthString: String {
        let f = DateFormatter()
        f.dateFormat = "MMM"
        return f.string(from: appointment.date).uppercased()
    }
}

struct AddAppointmentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var date = Date()
    @State private var artistName = ""
    @State private var studio = ""
    @State private var placement = BodyPlacement.forearm
    @State private var estimatedHours = 2.0
    @State private var depositPaid = ""
    @State private var totalCost = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            ZStack {
                InkTheme.background.ignoresSafeArea()
                Form {
                    Section {
                        TextField("Session Title", text: $title)
                        DatePicker("Date & Time", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    } header: {
                        Text("Session").foregroundStyle(InkTheme.textSecondary)
                    }
                    .listRowBackground(InkTheme.surface)
                    .foregroundStyle(InkTheme.textPrimary)

                    Section {
                        TextField("Artist Name", text: $artistName)
                        TextField("Studio", text: $studio)
                        Picker("Placement", selection: $placement) {
                            ForEach(BodyPlacement.allCases, id: \.self) { p in
                                Text(p.rawValue).tag(p)
                            }
                        }
                    } header: {
                        Text("Artist & Location").foregroundStyle(InkTheme.textSecondary)
                    }
                    .listRowBackground(InkTheme.surface)
                    .foregroundStyle(InkTheme.textPrimary)

                    Section {
                        HStack {
                            Text("Est. Hours").foregroundStyle(InkTheme.textSecondary)
                            Spacer()
                            Stepper("\(estimatedHours, specifier: "%.1f")h", value: $estimatedHours, in: 0.5...12, step: 0.5)
                                .foregroundStyle(InkTheme.textPrimary)
                        }
                        TextField("Deposit Paid ($)", text: $depositPaid).keyboardType(.decimalPad)
                        TextField("Total Cost ($)", text: $totalCost).keyboardType(.decimalPad)
                        TextField("Notes", text: $notes, axis: .vertical).lineLimit(3...6)
                    } header: {
                        Text("Details").foregroundStyle(InkTheme.textSecondary)
                    }
                    .listRowBackground(InkTheme.surface)
                    .foregroundStyle(InkTheme.textPrimary)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("New Appointment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(InkTheme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundStyle(InkTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .foregroundStyle(InkTheme.accent)
                }
            }
        }
    }

    func save() {
        let apt = TattooAppointment(
            title: title, date: date, artistName: artistName, studio: studio,
            estimatedHours: estimatedHours,
            depositPaid: Double(depositPaid) ?? 0,
            totalCost: Double(totalCost) ?? 0,
            notes: notes,
            placement: placement.rawValue
        )
        modelContext.insert(apt)
        dismiss()
    }
}

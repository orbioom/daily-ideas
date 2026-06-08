import SwiftUI
import SwiftData
import Charts

struct CareView: View {
    let pregnancy: Pregnancy
    @Environment(\.modelContext) private var context

    @Query(sort: \WeightEntry.date) private var weights: [WeightEntry]
    @Query(sort: \SymptomEntry.date, order: .reverse) private var symptoms: [SymptomEntry]
    @Query(sort: \Appointment.date) private var appointments: [Appointment]

    @State private var sheet: CareSheet?

    private enum CareSheet: Identifiable {
        case weight, symptom, appointment
        var id: Int { hashValue }
    }

    var body: some View {
        NavigationStack {
            List {
                weightSection
                symptomsSection
                appointmentsSection
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle("Care")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Log weight", systemImage: "scalemass") { sheet = .weight }
                        Button("Log symptom", systemImage: "heart.text.square") { sheet = .symptom }
                        Button("Add appointment", systemImage: "calendar.badge.plus") { sheet = .appointment }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add entry")
                }
            }
            .sheet(item: $sheet) { which in
                switch which {
                case .weight: WeightEditorView(suggested: weights.last?.kg ?? pregnancy.prePregnancyWeightKg)
                case .symptom: SymptomEditorView()
                case .appointment: AppointmentEditorView()
                }
            }
        }
    }

    // MARK: Weight

    @ViewBuilder private var weightSection: some View {
        Section("Weight") {
            if weights.count >= 2 {
                Chart(weights) { w in
                    LineMark(x: .value("Date", w.date), y: .value("kg", w.kg))
                        .foregroundStyle(Color(hex: 0x9A6FB0))
                        .interpolationMethod(.catmullRom)
                    PointMark(x: .value("Date", w.date), y: .value("kg", w.kg))
                        .foregroundStyle(Color(hex: 0x9A6FB0))
                }
                .chartYScale(domain: .automatic(includesZero: false))
                .frame(height: 160)
                .listRowBackground(Color.white.opacity(0.001))
                .accessibilityLabel("Weight trend chart")
            } else if weights.isEmpty {
                Text("No weight entries yet. Tap + to log your weight.")
                    .font(.subheadline).foregroundStyle(Brand.text2)
                    .listRowBackground(Color.white.opacity(0.001))
            }
            ForEach(weights.reversed()) { w in
                HStack {
                    Text(String(format: "%.1f kg", w.kg)).foregroundStyle(Brand.text)
                    Spacer()
                    Text(Format.shortDate.string(from: w.date)).font(.caption).foregroundStyle(Brand.text3)
                }
                .listRowBackground(Color.white.opacity(0.001))
            }
            .onDelete { offsets in delete(weights.reversed().map { $0 }, at: offsets) }
        }
    }

    // MARK: Symptoms

    @ViewBuilder private var symptomsSection: some View {
        Section("Symptoms") {
            if symptoms.isEmpty {
                Text("Nothing logged yet.").font(.subheadline).foregroundStyle(Brand.text2)
                    .listRowBackground(Color.white.opacity(0.001))
            }
            ForEach(symptoms) { s in
                HStack(spacing: 12) {
                    Image(systemName: s.symptom.icon).foregroundStyle(Color(hex: 0x9A6FB0)).frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(s.symptom.title).foregroundStyle(Brand.text)
                        if !s.note.isEmpty {
                            Text(s.note).font(.caption).foregroundStyle(Brand.text3).lineLimit(1)
                        }
                    }
                    Spacer()
                    SeverityDots(severity: s.severity)
                    Text(Format.relativeDay(s.date, relativeTo: .now, calendar: .current))
                        .font(.caption2).foregroundStyle(Brand.text3)
                }
                .listRowBackground(Color.white.opacity(0.001))
            }
            .onDelete { offsets in delete(symptoms, at: offsets) }
        }
    }

    // MARK: Appointments

    @ViewBuilder private var appointmentsSection: some View {
        Section("Appointments") {
            if appointments.isEmpty {
                Text("No appointments yet.").font(.subheadline).foregroundStyle(Brand.text2)
                    .listRowBackground(Color.white.opacity(0.001))
            }
            ForEach(appointments) { a in
                Button {
                    a.isDone.toggle(); Haptics.tap(); try? context.save()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: a.isDone ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(a.isDone ? Brand.live : Brand.text3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(a.title).foregroundStyle(Brand.text)
                                .strikethrough(a.isDone, color: Brand.text3)
                            Text(a.date.formatted(date: .abbreviated, time: .shortened) +
                                 (a.location.isEmpty ? "" : " · \(a.location)"))
                                .font(.caption).foregroundStyle(Brand.text3)
                        }
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.white.opacity(0.001))
            }
            .onDelete { offsets in delete(appointments, at: offsets) }
        }
    }

    private func delete<T: PersistentModel>(_ items: [T], at offsets: IndexSet) {
        for i in offsets { context.delete(items[i]) }
        try? context.save()
        Haptics.warning()
    }
}

struct SeverityDots: View {
    let severity: Int
    var body: some View {
        HStack(spacing: 3) {
            ForEach(1...3, id: \.self) { i in
                Circle()
                    .fill(i <= severity ? Color(hex: 0x9A6FB0) : Brand.hairline)
                    .frame(width: 6, height: 6)
            }
        }
        .accessibilityLabel("Severity \(severity) of 3")
    }
}

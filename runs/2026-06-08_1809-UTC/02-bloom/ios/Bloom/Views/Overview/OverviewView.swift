import SwiftUI
import SwiftData

struct OverviewView: View {
    @Bindable var pregnancy: Pregnancy
    @Environment(\.modelContext) private var context

    @Query(sort: \WeightEntry.date) private var weights: [WeightEntry]
    @Query(sort: \SymptomEntry.date, order: .reverse) private var symptoms: [SymptomEntry]
    @Query(sort: \Appointment.date) private var appointments: [Appointment]

    @State private var showSettings = false

    private var age: PregnancyEngine.Age { PregnancyEngine.age(dueDate: pregnancy.dueDate) }
    private var weekInfo: WeekInfo { WeekCatalog.info(for: age.displayWeek) }
    private var progress: Double { PregnancyEngine.progress(dueDate: pregnancy.dueDate) }
    private var daysLeft: Int { PregnancyEngine.daysRemaining(dueDate: pregnancy.dueDate) }

    private var nextAppointment: Appointment? {
        appointments.first { $0.date >= Calendar.current.startOfDay(for: .now) && !$0.isDone }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    heroCard
                    sizeCard
                    if let next = nextAppointment { appointmentCard(next) }
                    weightCard
                    recentSymptomsCard
                }
                .padding()
            }
            .background(Brand.pageBackground)
            .navigationTitle(greeting)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: { Image(systemName: "gearshape") }
                        .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView(pregnancy: pregnancy) }
        }
    }

    private var greeting: String {
        pregnancy.babyName.isEmpty ? "Bloom" : pregnancy.babyName
    }

    private var heroCard: some View {
        VStack(spacing: 14) {
            RingGauge(progress: progress) {
                VStack(spacing: 2) {
                    Text("Week")
                        .font(.caption).foregroundStyle(Brand.text3)
                    Text("\(age.weeks)")
                        .font(.system(size: 54, weight: .bold, design: .rounded))
                        .foregroundStyle(Brand.text)
                    Text("\(age.days) days")
                        .font(Brand.mono(12)).foregroundStyle(Brand.text2)
                }
            }
            .frame(width: 190, height: 190)

            Text(PregnancyEngine.trimesterName(PregnancyEngine.trimester(week: age.weeks)))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color(hex: 0x9A6FB0))

            HStack(spacing: 0) {
                stat("\(max(0, daysLeft))", "days to go")
                Rectangle().fill(Brand.hairline).frame(width: 1, height: 30)
                stat(Format.percent(progress), "complete")
                Rectangle().fill(Brand.hairline).frame(width: 1, height: 30)
                stat(Format.shortDate.string(from: pregnancy.dueDate).replacingOccurrences(of: ", \(Calendar.current.component(.year, from: pregnancy.dueDate))", with: ""), "due date")
            }
        }
        .frame(maxWidth: .infinity)
        .glassCard(padding: 20)
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.headline).foregroundStyle(Brand.text)
            Text(label).font(.caption2).foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private var sizeCard: some View {
        NavigationLink {
            WeekDetailView(week: age.displayWeek, pregnancy: pregnancy)
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Color(hex: 0x9A6FB0).opacity(0.16)).frame(width: 64, height: 64)
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(Color(hex: 0x9A6FB0))
                }
                .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text("This week, baby is about a")
                        .font(.caption).foregroundStyle(Brand.text3)
                    Text(weekInfo.fruit)
                        .font(.title3.weight(.bold)).foregroundStyle(Brand.text)
                    Text("\(weekInfo.lengthString) · \(weekInfo.weightString)")
                        .font(Brand.mono(12)).foregroundStyle(Brand.text2)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Brand.text3)
            }
            .glassCard()
        }
        .buttonStyle(.plain)
    }

    private func appointmentCard(_ a: Appointment) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .font(.title2).foregroundStyle(Color(hex: 0x9A6FB0))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Eyebrow(text: "Next appointment")
                Text(a.title).font(.headline).foregroundStyle(Brand.text)
                Text(a.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption).foregroundStyle(Brand.text2)
            }
            Spacer()
        }
        .glassCard()
    }

    private var weightCard: some View {
        let delta = weightDelta
        return HStack(spacing: 12) {
            Image(systemName: "scalemass")
                .font(.title2).foregroundStyle(Color(hex: 0x9A6FB0))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Eyebrow(text: "Weight")
                if let latest = weights.last {
                    Text(String(format: "%.1f kg", latest.kg))
                        .font(.headline).foregroundStyle(Brand.text)
                    if let delta {
                        Text(String(format: "%+.1f kg since start", delta))
                            .font(.caption).foregroundStyle(Brand.text2)
                    }
                } else {
                    Text("No entries yet").font(.subheadline).foregroundStyle(Brand.text2)
                }
            }
            Spacer()
        }
        .glassCard()
    }

    private var weightDelta: Double? {
        guard let last = weights.last else { return nil }
        let baseline = pregnancy.prePregnancyWeightKg > 0 ? pregnancy.prePregnancyWeightKg : weights.first?.kg
        guard let baseline else { return nil }
        return last.kg - baseline
    }

    private var recentSymptomsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "Recent symptoms")
            if symptoms.isEmpty {
                Text("Log how you're feeling from the Care tab.")
                    .font(.subheadline).foregroundStyle(Brand.text2)
            } else {
                ForEach(symptoms.prefix(3)) { s in
                    HStack(spacing: 10) {
                        Image(systemName: s.symptom.icon).foregroundStyle(Color(hex: 0x9A6FB0)).frame(width: 22)
                        Text(s.symptom.title).foregroundStyle(Brand.text)
                        Spacer()
                        Text(Format.relativeDay(s.date, relativeTo: .now, calendar: .current))
                            .font(.caption).foregroundStyle(Brand.text3)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }
}

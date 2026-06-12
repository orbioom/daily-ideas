import SwiftUI

struct LearnView: View {
    @AppStorage("rcEnabled") private var rcEnabled = false
    @AppStorage("rcCount") private var rcCount = 5
    @AppStorage("rcStart") private var rcStart = 9
    @AppStorage("rcEnd") private var rcEnd = 22
    @State private var scheduling = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    reminderCard
                    ForEach(TechniqueLibrary.all) { TechniqueCard(guide: $0) }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(Theme.bgPrimary.ignoresSafeArea())
            .navigationTitle("Learn")
        }
    }

    private var reminderCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Reality check reminders", systemImage: "bell.badge.fill")
                .font(.headline).foregroundStyle(Theme.accent)
            Text("Gentle nudges through the day to question reality — the habit that carries into your dreams.")
                .font(.subheadline).foregroundStyle(Theme.textSecondary)
            Toggle("Enable reminders", isOn: $rcEnabled)
                .tint(Theme.accent)
                .onChange(of: rcEnabled) { _, on in
                    if on { Task { await apply() } } else { ReminderScheduler.cancelAll() }
                }
            if rcEnabled {
                Stepper(value: $rcCount, in: 1...10) {
                    HStack { Text("Per day"); Spacer(); Text("\(rcCount)").foregroundStyle(Theme.accent) }
                }
                .onChange(of: rcCount) { _, _ in Task { await apply() } }
                HStack {
                    Text("Between")
                    Spacer()
                    Picker("Start", selection: $rcStart) {
                        ForEach(5..<13, id: \.self) { Text("\($0):00").tag($0) }
                    }.labelsHidden()
                    Text("and")
                    Picker("End", selection: $rcEnd) {
                        ForEach(15..<24, id: \.self) { Text("\($0):00").tag($0) }
                    }.labelsHidden()
                }
                .font(.subheadline)
                .onChange(of: rcStart) { _, _ in Task { await apply() } }
                .onChange(of: rcEnd) { _, _ in Task { await apply() } }
                if scheduling {
                    HStack(spacing: 8) { ProgressView().controlSize(.small); Text("Updating reminders…").font(.caption).foregroundStyle(Theme.textSecondary) }
                }
            }
        }
        .reverieCard()
    }

    @MainActor
    private func apply() async {
        guard rcEnabled else { return }
        scheduling = true
        await ReminderScheduler.reschedule(count: rcCount, startHour: rcStart, endHour: rcEnd)
        scheduling = false
    }
}

struct TechniqueCard: View {
    let guide: TechniqueGuide
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
                Haptics.tap()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: guide.symbol).font(.title3).foregroundStyle(Theme.accent).frame(width: 30)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(guide.name).font(.headline).foregroundStyle(Theme.textPrimary)
                        Text(guide.abbreviation).font(.caption).foregroundStyle(Theme.accent)
                    }
                    Spacer()
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.caption).foregroundStyle(Theme.textSecondary)
                }
            }
            .buttonStyle(.plain)
            Text(guide.summary).font(.subheadline).foregroundStyle(Theme.textSecondary)
            if expanded {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(guide.steps.indices, id: \.self) { i in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(i + 1)")
                                .font(.caption.weight(.bold)).foregroundStyle(.white)
                                .frame(width: 20, height: 20)
                                .background(Theme.accent, in: Circle())
                            Text(guide.steps[i]).font(.subheadline).foregroundStyle(Theme.textPrimary)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .reverieCard()
    }
}

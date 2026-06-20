import SwiftUI
import SwiftData

struct BeltProgressView: View {
    @Query(sort: \BeltRecord.awardedDate) private var beltRecords: [BeltRecord]
    @Query private var sessions: [TrainingSession]

    @State private var showingRecordPromotion = false

    private var currentRecord: BeltRecord? {
        BeltEngine.currentBelt(from: beltRecords)
    }

    private var currentBelt: BjjBelt {
        currentRecord?.bjjBelt ?? .white
    }

    private var progress: Double {
        BeltEngine.progressToNextBelt(currentBelt: currentBelt, sessionCount: sessions.count)
    }

    private var sessionsRemaining: Int {
        BeltEngine.sessionsUntilNextBelt(currentBelt: currentBelt, sessionCount: sessions.count)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DojoTheme.darkBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        // Current belt card
                        CurrentBeltCard(
                            record: currentRecord,
                            belt: currentBelt,
                            progress: progress,
                            sessionsRemaining: sessionsRemaining
                        )
                        .padding(.horizontal)

                        // Stats row
                        HStack(spacing: 12) {
                            BeltStatCard(
                                value: "\(BeltEngine.totalSessions(sessions))",
                                label: "Total Sessions",
                                icon: "figure.martial.arts",
                                color: DojoTheme.crimson
                            )
                            BeltStatCard(
                                value: "\(BeltEngine.totalHours(sessions))h",
                                label: "Mat Time",
                                icon: "clock.fill",
                                color: DojoTheme.gold
                            )
                            BeltStatCard(
                                value: "\(BeltEngine.streakDays(sessions))",
                                label: "Day Streak",
                                icon: "flame.fill",
                                color: .orange
                            )
                        }
                        .padding(.horizontal)

                        // Record promotion button
                        Button {
                            showingRecordPromotion = true
                        } label: {
                            Label("Record Promotion", systemImage: "medal.fill")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(DojoTheme.gold.opacity(0.2))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(DojoTheme.gold.opacity(0.5), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal)

                        // Belt history timeline
                        if beltRecords.count > 0 {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("BELT HISTORY")
                                    .font(.caption.bold())
                                    .foregroundColor(DojoTheme.subtleText)
                                    .padding(.horizontal)

                                VStack(spacing: 0) {
                                    ForEach(beltRecords.reversed()) { record in
                                        BeltHistoryRow(record: record, isLatest: record == beltRecords.last)
                                    }
                                }
                                .cardStyle()
                                .padding(.horizontal)
                            }
                        }

                        // Belt progression guide
                        VStack(alignment: .leading, spacing: 12) {
                            Text("BJJ BELT PROGRESSION")
                                .font(.caption.bold())
                                .foregroundColor(DojoTheme.subtleText)
                                .padding(.horizontal)

                            VStack(spacing: 0) {
                                ForEach(BjjBelt.allCases, id: \.self) { belt in
                                    BeltProgressionRow(belt: belt, isCurrent: belt == currentBelt)
                                }
                            }
                            .cardStyle()
                            .padding(.horizontal)
                        }

                        Spacer(minLength: 32)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Belt Progress")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(DojoTheme.darkBg, for: .navigationBar)
            .sheet(isPresented: $showingRecordPromotion) {
                RecordPromotionView()
            }
        }
        .tint(DojoTheme.crimson)
    }
}

// MARK: - Current Belt Card

struct CurrentBeltCard: View {
    let record: BeltRecord?
    let belt: BjjBelt
    let progress: Double
    let sessionsRemaining: Int

    var body: some View {
        VStack(spacing: 20) {
            // Belt label
            HStack {
                Text("Current Belt")
                    .font(.caption.bold())
                    .foregroundColor(DojoTheme.subtleText)
                Spacer()
                if let record = record {
                    Text("Since \(record.awardedDate, format: .dateTime.month().year())")
                        .font(.caption)
                        .foregroundColor(DojoTheme.subtleText)
                }
            }

            // Belt bar with stripes
            VStack(spacing: 12) {
                ZStack(alignment: .trailing) {
                    // Main belt
                    RoundedRectangle(cornerRadius: 6)
                        .fill(DojoTheme.beltColor(belt))
                        .frame(height: 40)

                    // Stripes
                    HStack(spacing: 4) {
                        ForEach(0..<(record?.stripes ?? 0), id: \.self) { _ in
                            Rectangle()
                                .fill(DojoTheme.gold)
                                .frame(width: 14, height: 40)
                        }
                    }
                    .padding(.trailing, 8)

                    // Belt name
                    Text(belt.rawValue.uppercased())
                        .font(.headline.bold())
                        .foregroundColor(DojoTheme.beltTextColor(belt))
                        .frame(maxWidth: .infinity)
                }

                // Stripe indicators
                HStack(spacing: 6) {
                    Text("Stripes")
                        .font(.caption)
                        .foregroundColor(DojoTheme.subtleText)
                    HStack(spacing: 4) {
                        ForEach(0..<belt.stripeMax, id: \.self) { i in
                            Circle()
                                .fill(i < (record?.stripes ?? 0) ? DojoTheme.gold : DojoTheme.elevatedBg)
                                .frame(width: 16, height: 16)
                        }
                    }
                    Spacer()
                    Text("\(record?.stripes ?? 0)/\(belt.stripeMax)")
                        .font(.caption)
                        .foregroundColor(DojoTheme.subtleText)
                }
            }

            // Progress to next belt
            if let nextBelt = belt.next {
                VStack(spacing: 8) {
                    HStack {
                        Text("Progress to \(nextBelt.rawValue)")
                            .font(.caption)
                            .foregroundColor(DojoTheme.subtleText)
                        Spacer()
                        Text(String(format: "%.0f%%", progress * 100))
                            .font(.caption.bold())
                            .foregroundColor(DojoTheme.crimson)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(DojoTheme.elevatedBg)
                                .frame(height: 8)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(DojoTheme.crimson)
                                .frame(width: geo.size.width * progress, height: 8)
                        }
                    }
                    .frame(height: 8)

                    if sessionsRemaining > 0 {
                        Text("~\(sessionsRemaining) more sessions estimated")
                            .font(.caption)
                            .foregroundColor(DojoTheme.subtleText)
                    }
                }
            } else {
                Text("Black Belt — the journey never ends.")
                    .font(.subheadline.italic())
                    .foregroundColor(DojoTheme.gold)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(20)
        .cardStyle()
    }
}

// MARK: - Stats

struct BeltStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            Text(value)
                .font(.title2.bold())
                .foregroundColor(.white)
            Text(label)
                .font(.caption2)
                .foregroundColor(DojoTheme.subtleText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .cardStyle()
    }
}

// MARK: - Belt History Row

struct BeltHistoryRow: View {
    let record: BeltRecord
    let isLatest: Bool

    var body: some View {
        HStack(spacing: 14) {
            // Belt color indicator
            RoundedRectangle(cornerRadius: 3)
                .fill(DojoTheme.beltColor(record.bjjBelt))
                .frame(width: 6, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(record.bjjBelt.rawValue)
                        .font(.headline)
                        .foregroundColor(.white)
                    if record.stripes > 0 {
                        HStack(spacing: 2) {
                            ForEach(0..<record.stripes, id: \.self) { _ in
                                Rectangle()
                                    .fill(DojoTheme.gold)
                                    .frame(width: 6, height: 14)
                                    .cornerRadius(1)
                            }
                        }
                    }
                    if isLatest {
                        Text("Current")
                            .font(.caption.bold())
                            .foregroundColor(DojoTheme.crimson)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(DojoTheme.crimson.opacity(0.15))
                            .cornerRadius(4)
                    }
                }
                HStack(spacing: 12) {
                    Text(record.awardedDate, format: .dateTime.month(.wide).year())
                        .font(.caption)
                        .foregroundColor(DojoTheme.subtleText)
                    if !record.instructor.isEmpty {
                        Text("by \(record.instructor)")
                            .font(.caption)
                            .foregroundColor(DojoTheme.subtleText)
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.clear)
    }
}

// MARK: - Belt Progression Row

struct BeltProgressionRow: View {
    let belt: BjjBelt
    let isCurrent: Bool

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 3)
                .fill(DojoTheme.beltColor(belt))
                .frame(width: 6, height: 36)

            Text(belt.rawValue)
                .font(.subheadline)
                .foregroundColor(isCurrent ? .white : DojoTheme.subtleText)
                .fontWeight(isCurrent ? .bold : .regular)

            Spacer()

            if belt.minMonths > 0 {
                Text("Min \(belt.minMonths)mo")
                    .font(.caption)
                    .foregroundColor(DojoTheme.subtleText)
            }

            if isCurrent {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(DojoTheme.crimson)
                    .font(.subheadline)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        if belt != BjjBelt.allCases.last {
            Divider()
                .background(DojoTheme.elevatedBg)
                .padding(.leading, 26)
        }
    }
}

// MARK: - Record Promotion Sheet

struct RecordPromotionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage("dojoCurrentBelt") private var currentBeltRaw = BjjBelt.white.rawValue

    @State private var selectedBelt: BjjBelt = .blue
    @State private var stripes = 0
    @State private var awardedDate = Date()
    @State private var instructor = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            ZStack {
                DojoTheme.darkBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        FormSection(title: "Belt") {
                            VStack(spacing: 0) {
                                ForEach(BjjBelt.allCases, id: \.self) { belt in
                                    Button {
                                        selectedBelt = belt
                                        stripes = 0
                                    } label: {
                                        HStack(spacing: 14) {
                                            RoundedRectangle(cornerRadius: 3)
                                                .fill(DojoTheme.beltColor(belt))
                                                .frame(width: 6, height: 28)
                                            Text(belt.rawValue)
                                                .foregroundColor(.white)
                                            Spacer()
                                            if selectedBelt == belt {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(DojoTheme.crimson)
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                    }
                                    if belt != BjjBelt.allCases.last {
                                        Divider().background(DojoTheme.elevatedBg).padding(.leading, 26)
                                    }
                                }
                            }
                        }

                        FormSection(title: "Stripes") {
                            CounterRow(
                                label: "Stripe Count",
                                value: $stripes,
                                min: 0,
                                max: selectedBelt.stripeMax,
                                valueColor: DojoTheme.gold
                            )
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }

                        FormSection(title: "Date Awarded") {
                            DatePicker("", selection: $awardedDate, displayedComponents: [.date])
                                .datePickerStyle(.compact)
                                .tint(DojoTheme.crimson)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                        }

                        FormSection(title: "Instructor") {
                            TextField("Professor name", text: $instructor)
                                .padding(14)
                                .foregroundColor(.white)
                                .tint(DojoTheme.crimson)
                        }

                        FormSection(title: "Notes") {
                            TextEditor(text: $notes)
                                .frame(minHeight: 80)
                                .padding(12)
                                .foregroundColor(.white)
                                .tint(DojoTheme.crimson)
                                .scrollContentBackground(.hidden)
                        }

                        Button("Save Promotion") {
                            let record = BeltRecord(
                                belt: selectedBelt.rawValue,
                                stripes: stripes,
                                awardedDate: awardedDate,
                                instructor: instructor,
                                notes: notes
                            )
                            modelContext.insert(record)
                            currentBeltRaw = selectedBelt.rawValue
                            dismiss()
                        }
                        .buttonStyle(CrimsonButtonStyle())
                        .padding(.horizontal)
                        .padding(.bottom, 32)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Record Promotion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(DojoTheme.darkBg, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(DojoTheme.crimson)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    BeltProgressView()
        .modelContainer(for: [BeltRecord.self, TrainingSession.self], inMemory: true)
}

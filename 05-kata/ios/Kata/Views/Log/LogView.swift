import SwiftUI
import SwiftData

struct LogView: View {
    @Query(sort: \WODResult.date, order: .reverse) private var results: [WODResult]
    @Environment(\.modelContext) private var modelContext
    @State private var showAddSheet = false
    @State private var searchText = ""
    @State private var selectedType: WODType? = nil

    var filtered: [WODResult] {
        results.filter { r in
            let matchSearch = searchText.isEmpty || r.wodName.localizedCaseInsensitiveContains(searchText)
            let matchType = selectedType == nil || r.wodType == selectedType!.rawValue
            return matchSearch && matchType
        }
    }

    var body: some View {
        ZStack {
            KataTheme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                typeFilter
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                if filtered.isEmpty {
                    emptyState
                } else {
                    List {
                        statsHeader
                        ForEach(filtered) { result in
                            ResultRow(result: result)
                                .swipeActions {
                                    Button(role: .destructive) {
                                        modelContext.delete(result)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(.insetGrouped)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search WODs")
        .navigationTitle("WOD Log")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(KataTheme.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAddSheet = true } label: {
                    Image(systemName: "plus").foregroundStyle(KataTheme.accent)
                }
            }
        }
        .sheet(isPresented: $showAddSheet) { LogWODView() }
    }

    var typeFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(label: "All", type: nil)
                ForEach(WODType.allCases, id: \.self) { t in
                    filterChip(label: t.rawValue, type: t)
                }
            }
        }
    }

    func filterChip(label: String, type: WODType?) -> some View {
        Button {
            withAnimation { selectedType = type }
        } label: {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(selectedType == type ? .black : KataTheme.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selectedType == type ? KataTheme.accent : KataTheme.surface, in: Capsule())
        }
    }

    var statsHeader: some View {
        Section {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                statChip(value: "\(results.count)", label: "WODs")
                statChip(value: "\(results.filter { $0.rx }.count)", label: "RX")
                statChip(value: streak, label: "Streak")
            }
            .padding(.vertical, 4)
        }
        .listRowBackground(KataTheme.surface)
    }

    func statChip(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(KataTheme.accent)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(KataTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(KataTheme.background.opacity(0.6), in: RoundedRectangle(cornerRadius: 10))
    }

    var streak: String {
        guard !results.isEmpty else { return "0" }
        var count = 0
        var current = Calendar.current.startOfDay(for: Date())
        for result in results.sorted(by: { $0.date > $1.date }) {
            let day = Calendar.current.startOfDay(for: result.date)
            if day == current || day == Calendar.current.date(byAdding: .day, value: -1, to: current)! {
                count += 1
                current = day
            } else { break }
        }
        return "\(count)d"
    }

    var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.clipboard.fill")
                .font(.system(size: 52))
                .foregroundStyle(KataTheme.textSecondary)
            Text("No WODs Logged")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(KataTheme.textPrimary)
            Text("Log your first WOD to start tracking progress.")
                .font(.system(size: 15))
                .foregroundStyle(KataTheme.textSecondary)
                .multilineTextAlignment(.center)
            Button { showAddSheet = true } label: {
                Text("Log WOD")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(KataTheme.accent, in: Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ResultRow: View {
    let result: WODResult

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(result.wodName.isEmpty ? "Custom WOD" : result.wodName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(KataTheme.textPrimary)
                Spacer()
                Text(result.scoreDisplay)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(KataTheme.accent)
            }
            HStack(spacing: 10) {
                Text(result.wodType)
                    .font(.system(size: 12))
                    .foregroundStyle(KataTheme.textSecondary)
                if result.rx {
                    Text("RX")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(KataTheme.correctGreen, in: Capsule())
                } else if result.scaled {
                    Text("Scaled")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(KataTheme.accentYellow, in: Capsule())
                }
                Spacer()
                Text(result.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 12))
                    .foregroundStyle(KataTheme.textSecondary)
            }
            if !result.notes.isEmpty {
                Text(result.notes)
                    .font(.system(size: 13))
                    .foregroundStyle(KataTheme.textSecondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
        .listRowBackground(KataTheme.surface)
    }
}

struct LogWODView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var prefillName: String = ""
    var prefillType: WODType = .forTime

    @State private var name = ""
    @State private var wodType = WODType.forTime
    @State private var minutes = ""
    @State private var seconds = ""
    @State private var rounds = ""
    @State private var reps = ""
    @State private var notes = ""
    @State private var rx = true
    @State private var rating = 3
    @State private var date = Date()

    var body: some View {
        NavigationStack {
            ZStack {
                KataTheme.background.ignoresSafeArea()
                Form {
                    Section {
                        TextField("WOD Name", text: $name)
                        DatePicker("Date", selection: $date, displayedComponents: .date)
                        Picker("Type", selection: $wodType) {
                            ForEach(WODType.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                        }
                    } header: { Text("WOD").foregroundStyle(KataTheme.textSecondary) }
                    .listRowBackground(KataTheme.surface)
                    .foregroundStyle(KataTheme.textPrimary)

                    Section {
                        if wodType == .forTime || wodType == .emom || wodType == .tabata {
                            HStack {
                                Text("Time").foregroundStyle(KataTheme.textSecondary)
                                Spacer()
                                TextField("MM", text: $minutes).keyboardType(.numberPad).frame(width: 44).multilineTextAlignment(.center)
                                Text(":").foregroundStyle(KataTheme.textSecondary)
                                TextField("SS", text: $seconds).keyboardType(.numberPad).frame(width: 44).multilineTextAlignment(.center)
                            }
                        }
                        if wodType == .amrap || wodType == .emom {
                            HStack {
                                Text("Rounds").foregroundStyle(KataTheme.textSecondary)
                                Spacer()
                                TextField("0", text: $rounds).keyboardType(.numberPad).frame(width: 60).multilineTextAlignment(.trailing)
                            }
                            HStack {
                                Text("+ Reps").foregroundStyle(KataTheme.textSecondary)
                                Spacer()
                                TextField("0", text: $reps).keyboardType(.numberPad).frame(width: 60).multilineTextAlignment(.trailing)
                            }
                        }
                        Toggle("RX", isOn: $rx).tint(KataTheme.accent)
                    } header: { Text("Result").foregroundStyle(KataTheme.textSecondary) }
                    .listRowBackground(KataTheme.surface)
                    .foregroundStyle(KataTheme.textPrimary)

                    Section {
                        HStack {
                            Text("Effort").foregroundStyle(KataTheme.textSecondary)
                            Spacer()
                            HStack(spacing: 4) {
                                ForEach(1...5, id: \.self) { i in
                                    Image(systemName: i <= rating ? "flame.fill" : "flame")
                                        .foregroundStyle(i <= rating ? KataTheme.accent : KataTheme.textSecondary.opacity(0.4))
                                        .onTapGesture { rating = i }
                                }
                            }
                        }
                        TextField("Notes", text: $notes, axis: .vertical).lineLimit(3...6)
                    } header: { Text("Feeling").foregroundStyle(KataTheme.textSecondary) }
                    .listRowBackground(KataTheme.surface)
                    .foregroundStyle(KataTheme.textPrimary)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Log WOD")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(KataTheme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundStyle(KataTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .foregroundStyle(KataTheme.accent)
                        .disabled(name.isEmpty)
                }
            }
            .onAppear {
                name = prefillName
                wodType = prefillType
            }
        }
    }

    func save() {
        let m = Int(minutes) ?? 0
        let s = Int(seconds) ?? 0
        let totalSeconds = m * 60 + s
        let result = WODResult(
            date: date,
            wodName: name,
            wodType: wodType.rawValue,
            timeSeconds: totalSeconds,
            rounds: Int(rounds) ?? 0,
            reps: Int(reps) ?? 0,
            notes: notes,
            rx: rx,
            scaled: !rx,
            rating: rating
        )
        modelContext.insert(result)
        dismiss()
    }
}

import SwiftUI
import SwiftData

struct WODView: View {
    @State private var selectedWOD: BuiltInWOD? = nil
    @State private var showCustom = false
    @State private var showTimer = false
    @State private var timerWOD: BuiltInWOD? = nil
    @State private var searchText = ""

    var filteredWODs: [BuiltInWOD] {
        guard !searchText.isEmpty else { return BuiltInWOD.all }
        return BuiltInWOD.all.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.type.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ZStack {
            KataTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    heroSection
                    benchmarkSection
                }
                .padding(16)
            }
        }
        .searchable(text: $searchText, prompt: "Search WODs")
        .navigationTitle("WODs")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(KataTheme.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showCustom = true } label: {
                    Label("Custom WOD", systemImage: "plus")
                        .foregroundStyle(KataTheme.accent)
                }
            }
        }
        .sheet(item: $selectedWOD) { wod in
            WODDetailSheet(wod: wod, onStart: { timerWOD = wod; showTimer = true })
        }
        .fullScreenCover(isPresented: $showTimer) {
            WODTimerView(wod: timerWOD)
        }
        .sheet(isPresented: $showCustom) {
            CustomWODSheet()
        }
    }

    var heroSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Hero WODs")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(KataTheme.textSecondary)
            ForEach(filteredWODs.filter { $0.isHero }) { wod in
                WODCard(wod: wod, isHero: true)
                    .onTapGesture { selectedWOD = wod }
            }
        }
    }

    var benchmarkSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Benchmark Girls & Others")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(KataTheme.textSecondary)
            ForEach(filteredWODs.filter { !$0.isHero }) { wod in
                WODCard(wod: wod, isHero: false)
                    .onTapGesture { selectedWOD = wod }
            }
        }
    }
}

struct WODCard: View {
    let wod: BuiltInWOD
    let isHero: Bool

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(wod.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(KataTheme.textPrimary)
                    if isHero {
                        Text("HERO")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(KataTheme.accentYellow, in: Capsule())
                    }
                }
                Text(wod.type.rawValue)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(KataTheme.accent)
                Text(wod.description)
                    .font(.system(size: 13))
                    .foregroundStyle(KataTheme.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundStyle(KataTheme.textSecondary)
        }
        .padding(14)
        .background(KataTheme.surface, in: RoundedRectangle(cornerRadius: 14))
    }
}

struct WODDetailSheet: View {
    let wod: BuiltInWOD
    let onStart: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showLogSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                KataTheme.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(wod.type.rawValue)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(KataTheme.accent)
                            Text(wod.type.description)
                                .font(.system(size: 14))
                                .foregroundStyle(KataTheme.textSecondary)
                            if let tc = wod.timeCap {
                                Text("Time cap: \(tc/60) min")
                                    .font(.system(size: 13))
                                    .foregroundStyle(KataTheme.textSecondary)
                            }
                        }
                        .padding(14)
                        .background(KataTheme.surface, in: RoundedRectangle(cornerRadius: 12))

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Movements")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(KataTheme.textSecondary)
                            ForEach(Array(wod.movements.enumerated()), id: \.offset) { _, m in
                                HStack(spacing: 10) {
                                    Circle()
                                        .fill(KataTheme.accent)
                                        .frame(width: 6, height: 6)
                                    Text(m)
                                        .font(.system(size: 15))
                                        .foregroundStyle(KataTheme.textPrimary)
                                }
                            }
                        }
                        .padding(14)
                        .background(KataTheme.surface, in: RoundedRectangle(cornerRadius: 12))

                        HStack(spacing: 12) {
                            Button {
                                dismiss()
                                onStart()
                            } label: {
                                Label("Start Timer", systemImage: "timer")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.black)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(KataTheme.accent, in: RoundedRectangle(cornerRadius: 14))
                            }
                            Button {
                                showLogSheet = true
                            } label: {
                                Label("Log Result", systemImage: "pencil")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(KataTheme.accent)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(KataTheme.accent.opacity(0.15), in: RoundedRectangle(cornerRadius: 14))
                                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(KataTheme.accent.opacity(0.4), lineWidth: 1))
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle(wod.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(KataTheme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(KataTheme.textSecondary)
                }
            }
            .sheet(isPresented: $showLogSheet) {
                LogWODView(prefillName: wod.name, prefillType: wod.type)
            }
        }
    }
}

struct WODTimerView: View {
    let wod: BuiltInWOD?
    @State private var timerVM = TimerViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            KataTheme.background.ignoresSafeArea()
            VStack(spacing: 32) {
                HStack {
                    Button { timerVM.reset(); dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(KataTheme.textSecondary)
                    }
                    Spacer()
                    if let w = wod {
                        Text(w.name)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(KataTheme.textPrimary)
                    }
                    Spacer()
                    Color.clear.frame(width: 28, height: 28)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                Spacer()

                ZStack {
                    Circle()
                        .stroke(KataTheme.surface, lineWidth: 12)
                        .frame(width: 260, height: 260)
                    Circle()
                        .trim(from: 0, to: progressFraction)
                        .stroke(timerColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .frame(width: 260, height: 260)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: timerVM.elapsed)

                    VStack(spacing: 8) {
                        Text(timerVM.displayTime)
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                            .foregroundStyle(timerColor)
                        Text(statusLabel)
                            .font(.system(size: 16))
                            .foregroundStyle(KataTheme.textSecondary)
                    }
                }

                if let w = wod {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(w.movements, id: \.self) { m in
                                Text(m)
                                    .font(.system(size: 13))
                                    .foregroundStyle(KataTheme.textSecondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(KataTheme.surface, in: Capsule())
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }

                HStack(spacing: 20) {
                    if timerVM.state == .idle {
                        Button {
                            timerVM.start(timeCap: wod?.timeCap ?? 0, mode: wod?.type ?? .forTime)
                        } label: {
                            Text("Start")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.black)
                                .frame(width: 160, height: 56)
                                .background(KataTheme.accent, in: Capsule())
                        }
                    } else if timerVM.state == .running || timerVM.state == .countdown {
                        Button { timerVM.pause() } label: {
                            Image(systemName: "pause.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(KataTheme.textPrimary)
                                .frame(width: 64, height: 64)
                                .background(KataTheme.surface, in: Circle())
                        }
                        Button { timerVM.stop() } label: {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(.white)
                                .frame(width: 64, height: 64)
                                .background(KataTheme.warningRed, in: Circle())
                        }
                    } else if timerVM.state == .paused {
                        Button { timerVM.resume() } label: {
                            Image(systemName: "play.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(.black)
                                .frame(width: 64, height: 64)
                                .background(KataTheme.accent, in: Circle())
                        }
                        Button { timerVM.stop() } label: {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(.white)
                                .frame(width: 64, height: 64)
                                .background(KataTheme.warningRed, in: Circle())
                        }
                    } else {
                        Button { timerVM.reset() } label: {
                            Text("Reset")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(KataTheme.textPrimary)
                                .frame(width: 120, height: 52)
                                .background(KataTheme.surface, in: Capsule())
                        }
                    }
                }
                Spacer()
            }
        }
    }

    var progressFraction: CGFloat {
        guard let cap = wod?.timeCap, cap > 0 else { return min(1, CGFloat(timerVM.elapsed) / 600) }
        return min(1, CGFloat(timerVM.elapsed) / CGFloat(cap))
    }

    var timerColor: Color {
        if timerVM.state == .countdown { return KataTheme.accentYellow }
        if timerVM.timeCapReached { return KataTheme.warningRed }
        return KataTheme.accent
    }

    var statusLabel: String {
        switch timerVM.state {
        case .idle: return "Ready"
        case .countdown: return "Get ready..."
        case .running: return "GO"
        case .paused: return "Paused"
        case .done: return timerVM.timeCapReached ? "Time cap!" : "Done!"
        }
    }
}

struct CustomWODSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var name = ""
    @State private var wodType = WODType.forTime
    @State private var movementsText = ""
    @State private var notes = ""
    @State private var timeSeconds = 0
    @State private var rounds = 0
    @State private var reps = 0
    @State private var rx = true

    var body: some View {
        NavigationStack {
            ZStack {
                KataTheme.background.ignoresSafeArea()
                Form {
                    Section {
                        TextField("WOD Name", text: $name)
                        Picker("Type", selection: $wodType) {
                            ForEach(WODType.allCases, id: \.self) { t in
                                Text(t.rawValue).tag(t)
                            }
                        }
                        TextField("Movements (one per line)", text: $movementsText, axis: .vertical)
                            .lineLimit(4...10)
                    } header: {
                        Text("WOD").foregroundStyle(KataTheme.textSecondary)
                    }
                    .listRowBackground(KataTheme.surface)
                    .foregroundStyle(KataTheme.textPrimary)

                    Section {
                        Toggle("RX", isOn: $rx).tint(KataTheme.accent)
                        TextField("Notes", text: $notes, axis: .vertical).lineLimit(3...6)
                    } header: {
                        Text("Result").foregroundStyle(KataTheme.textSecondary)
                    }
                    .listRowBackground(KataTheme.surface)
                    .foregroundStyle(KataTheme.textPrimary)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Log Custom WOD")
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
        }
    }

    func save() {
        let result = WODResult(
            wodName: name, wodType: wodType.rawValue,
            movements: movementsText, notes: notes, rx: rx, scaled: !rx
        )
        modelContext.insert(result)
        dismiss()
    }
}

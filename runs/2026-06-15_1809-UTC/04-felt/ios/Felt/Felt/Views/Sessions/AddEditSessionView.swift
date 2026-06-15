import SwiftUI
import SwiftData

/// Add or edit a session. Pass `nil` to add, or an existing `Session` to edit.
struct AddEditSessionView: View {
    let session: Session?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    @State private var date = Date()
    @State private var format: SessionFormat = .cash
    @State private var gameType: GameType = .nlhe
    @State private var location = ""
    @State private var stakes = ""
    @State private var hours = 2
    @State private var minutes = 0
    @State private var buyInText = ""
    @State private var cashOutText = ""
    @State private var entriesText = ""
    @State private var placeText = ""
    @State private var notes = ""
    @State private var tag = ""

    @State private var validationMessage: String?

    private var isEditing: Bool { session != nil }
    private var sym: String { settings.currencySymbol }

    private var buyIn: Decimal { Money.parse(buyInText) ?? 0 }
    private var cashOut: Decimal { Money.parse(cashOutText) ?? 0 }
    private var liveProfit: Decimal { cashOut - buyIn }
    private var durationMinutes: Int { max(0, hours) * 60 + max(0, min(59, minutes)) }

    var body: some View {
        NavigationStack {
            Form {
                if let validationMessage {
                    Section {
                        Label(validationMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(Theme.rounded(13, .medium))
                            .foregroundStyle(Theme.bad)
                    }
                }

                Section("Format") {
                    Picker("Format", selection: $format) {
                        ForEach(SessionFormat.allCases) { f in
                            Text(f.rawValue).tag(f)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("Game", selection: $gameType) {
                        ForEach(GameType.allCases) { g in
                            Text(g.rawValue).tag(g)
                        }
                    }
                }

                Section("Where & when") {
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    TextField("Location (e.g. Bellagio)", text: $location)
                    TextField(format == .tournament ? "Buy-in label (e.g. $400 Daily)" : "Stakes (e.g. 1/2)", text: $stakes)
                }

                Section("Duration") {
                    HStack {
                        Stepper(value: $hours, in: 0...48) {
                            Text("\(hours) h").font(Theme.mono(15))
                        }
                    }
                    HStack {
                        Stepper(value: $minutes, in: 0...59, step: 5) {
                            Text("\(minutes) m").font(Theme.mono(15))
                        }
                    }
                }

                Section(format == .tournament ? "Investment & prize" : "Buy-in & cash-out") {
                    HStack {
                        Text(format == .tournament ? "Total invested" : "Buy-in")
                        Spacer()
                        TextField("0", text: $buyInText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(Theme.mono(16))
                    }
                    HStack {
                        Text(format == .tournament ? "Prize won" : "Cash-out")
                        Spacer()
                        TextField("0", text: $cashOutText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(Theme.mono(16))
                    }
                    HStack {
                        Text("Profit").font(Theme.rounded(15, .semibold))
                        Spacer()
                        MoneyText(value: liveProfit, symbol: sym, size: 17, signed: true)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Live profit \(Money.string(liveProfit, symbol: sym, signed: true))")
                }

                if format == .tournament {
                    Section("Tournament details") {
                        HStack {
                            Text("Entries")
                            Spacer()
                            TextField("Optional", text: $entriesText)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                        }
                        HStack {
                            Text("Your place")
                            Spacer()
                            TextField("Optional", text: $placeText)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }

                Section("Notes") {
                    TextField("Tag (e.g. Weekend)", text: $tag)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(isEditing ? "Edit session" : "New session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                }
            }
            .onAppear(perform: loadIfEditing)
        }
    }

    private func loadIfEditing() {
        if let session {
            date = session.date
            format = session.format
            gameType = session.gameType
            location = session.location
            stakes = session.stakes
            hours = max(0, session.durationMinutes) / 60
            minutes = max(0, session.durationMinutes) % 60
            buyInText = session.buyIn == 0 ? "" : Money.plain(session.buyIn, fractionDigits: 2)
            cashOutText = session.cashOut == 0 ? "" : Money.plain(session.cashOut, fractionDigits: 2)
            entriesText = session.tournamentEntries.map(String.init) ?? ""
            placeText = session.tournamentPlace.map(String.init) ?? ""
            notes = session.notes
            tag = session.tag
        } else {
            gameType = settings.defaultGameType
        }
    }

    private func save() {
        // Validation: require both amounts to be parseable when entered, and non-negative.
        if buyInText.trimmingCharacters(in: .whitespaces).isEmpty && cashOutText.trimmingCharacters(in: .whitespaces).isEmpty {
            validationMessage = "Enter at least a buy-in or cash-out amount."
            return
        }
        if !buyInText.isEmpty && Money.parse(buyInText) == nil {
            validationMessage = "The buy-in isn't a valid number."
            return
        }
        if !cashOutText.isEmpty && Money.parse(cashOutText) == nil {
            validationMessage = "The cash-out isn't a valid number."
            return
        }
        if buyIn < 0 || cashOut < 0 {
            validationMessage = "Amounts can't be negative."
            return
        }

        let entries = entriesText.isEmpty ? nil : Int(entriesText)
        let place = placeText.isEmpty ? nil : Int(placeText)
        let trimmedLoc = location.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedStakes = stakes.trimmingCharacters(in: .whitespacesAndNewlines)

        if let session {
            session.date = date
            session.format = format
            session.gameType = gameType
            session.location = trimmedLoc
            session.stakes = trimmedStakes
            session.durationMinutes = durationMinutes
            session.buyIn = buyIn
            session.cashOut = cashOut
            session.tournamentEntries = format == .tournament ? entries : nil
            session.tournamentPlace = format == .tournament ? place : nil
            session.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            session.tag = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            let new = Session(date: date,
                              format: format,
                              gameType: gameType,
                              location: trimmedLoc,
                              stakes: trimmedStakes,
                              durationMinutes: durationMinutes,
                              buyIn: buyIn,
                              cashOut: cashOut,
                              tournamentEntries: format == .tournament ? entries : nil,
                              tournamentPlace: format == .tournament ? place : nil,
                              notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                              tag: tag.trimmingCharacters(in: .whitespacesAndNewlines))
            modelContext.insert(new)
        }

        try? modelContext.save()
        Haptics.success(enabled: settings.hapticsEnabled)
        dismiss()
    }
}

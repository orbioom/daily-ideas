import SwiftUI
import SwiftData

/// Full specifications for a single motor plus a short thrust-profile note.
/// Custom motors expose an Edit button.
struct MotorDetailView: View {
    @Bindable var motor: Motor
    @State private var showingEdit = false

    /// Peak-to-average ratio gives a rough sense of the burn shape.
    private var thrustProfileNote: String {
        let burn = motor.burnTimeS
        guard burn > 0 else { return "Burn data unavailable." }
        if motor.manufacturer.lowercased().contains("aerotech") {
            return "Composite propellant — a fast, hot burn with a sharp initial spike then a steady tail. Expect a brisk kick off the pad."
        }
        if motor.avgThrustN >= 9 {
            return "Black-powder motor with a high-thrust, short burn — a punchy boost good for heavier birds."
        }
        return "Black-powder motor with a moderate, even burn — gentle and predictable, ideal for lighter rockets."
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerCard
                specsCard
                profileCard
            }
            .padding(16)
        }
        .background(Brand.pageBackground)
        .navigationTitle(motor.designation.isEmpty ? "Motor" : motor.designation)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if motor.isCustom {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit") { showingEdit = true }
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            MotorEditView(motor: motor)
        }
    }

    private var headerCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Eyebrow(text: motor.manufacturer)
                    Spacer()
                    Badge(text: "Class \(motor.impulseClass)", color: Brand.info)
                    if motor.isCustom {
                        Badge(text: "custom", color: Brand.magic)
                    }
                }
                Text(motor.designation)
                    .font(Brand.mono(40, weight: .bold))
                    .foregroundStyle(Brand.text)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    StatTile(value: "\(Format.number(motor.totalImpulseNs, decimals: 1)) N·s", label: "Total impulse")
                    StatTile(value: Format.newtons(motor.avgThrustN, decimals: 1), label: "Avg thrust")
                    StatTile(value: Format.seconds(motor.burnTimeS), label: "Burn time")
                    StatTile(value: Format.mm(motor.diameterMm, decimals: 0), label: "Diameter")
                }
            }
        }
    }

    private var specsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Eyebrow(text: "Masses & delays")
                InfoRow(label: "Propellant mass", value: Format.grams(motor.propMassG, decimals: 1), mono: true)
                InfoRow(label: "Total mass", value: Format.grams(motor.totalMassG, decimals: 1), mono: true)
                InfoRow(label: "Casing diameter", value: Format.mm(motor.diameterMm, decimals: 0), mono: true)
                InfoRow(label: "Ejection delays",
                        value: motor.delays.isEmpty ? "—" : motor.delays.map { Format.number($0, decimals: 0) }.joined(separator: ", ") + " s",
                        mono: true)
            }
        }
    }

    private var profileCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Eyebrow(text: "Thrust profile")
                Text(thrustProfileNote)
                    .font(.footnote)
                    .foregroundStyle(Brand.text2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

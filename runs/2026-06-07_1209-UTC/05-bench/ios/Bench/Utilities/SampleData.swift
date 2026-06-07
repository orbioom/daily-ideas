import Foundation
import SwiftData

/// Seeds a starter parts bin and a couple of saved calculations.
enum SampleData {
    static func seed(into context: ModelContext) {
        let parts: [(String, ComponentKind, String, String, Int)] = [
            ("Carbon film resistor", .resistor, "220 Ω", "Through-hole", 84),
            ("Carbon film resistor", .resistor, "1 kΩ", "Through-hole", 120),
            ("Carbon film resistor", .resistor, "10 kΩ", "Through-hole", 96),
            ("Ceramic capacitor", .capacitor, "100 nF", "0.1\" radial", 60),
            ("Electrolytic capacitor", .capacitor, "10 µF", "Radial", 25),
            ("NE555", .ic, "Timer", "DIP-8", 8),
            ("ATmega328P", .ic, "MCU", "DIP-28", 3),
            ("2N2222", .transistor, "NPN", "TO-92", 14),
            ("1N4148", .diode, "Signal", "DO-35", 50),
            ("5mm LED", .led, "Red", "Through-hole", 40),
            ("Tactile button", .connector, "6mm", "Through-hole", 18),
        ]
        for p in parts {
            context.insert(Component(name: p.0, kind: p.1, value: p.2, package: p.3, quantity: p.4))
        }

        if let led = EE.ledResistor(supply: 5, forward: 2.0, currentmA: 20) {
            let calc = SavedCalc(
                tool: "LED resistor",
                title: "5V red LED @ 20mA",
                summary: "R ≈ \(EE.eng(led.standard, unit: "Ω"))",
                detail: "Supply 5 V · Vf 2.0 V · 20 mA\nExact \(EE.eng(led.resistance, unit: "Ω")) → nearest \(EE.eng(led.standard, unit: "Ω"))\nResistor power ≈ \(EE.eng(led.power, unit: "W"))")
            context.insert(calc)
        }
        if let a = EE.ne555Astable(r1: 1000, r2: 10000, c: 10e-6) {
            let calc = SavedCalc(
                tool: "555 astable",
                title: "Blinker R1=1k R2=10k C=10µF",
                summary: "f ≈ \(EE.eng(a.freq, unit: "Hz"))",
                detail: "f ≈ \(EE.eng(a.freq, unit: "Hz"))\nDuty \(String(format: "%.1f", a.duty))%\ntHigh \(EE.duration(a.tHigh)) · tLow \(EE.duration(a.tLow))")
            context.insert(calc)
        }
    }
}

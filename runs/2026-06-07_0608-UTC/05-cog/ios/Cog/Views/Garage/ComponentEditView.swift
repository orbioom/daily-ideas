import SwiftUI
import SwiftData

struct ComponentEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("cog.miles") private var miles = false
    let bike: Bike
    let existing: Component?

    @State private var name = ""
    @State private var category = "Drivetrain"
    @State private var lifespanDistance = 0.0   // in display units
    @State private var lifespanDays = 0
    @State private var installedAt = 0.0        // in display units
    @State private var installedDate = Date()
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if existing == nil { presetCard }
                    basicsCard
                    lifeCard
                    if existing != nil { replaceCard }
                    notesCard
                }
                .padding()
            }
            .navigationTitle(existing == nil ? "New Component" : name)
            .navigationBarTitleDisplayMode(.inline)
            .background(Brand.pageBackground)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: load)
        }
    }

    private var presetCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(text: "Quick add")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(WearEngine.presets, id: \.name) { p in
                        Button {
                            name = p.name; category = p.category
                            lifespanDistance = Units.kmTo(p.km, miles: miles)
                            lifespanDays = p.days
                            Haptics.selection()
                        } label: {
                            Text(p.name).font(.caption.weight(.medium)).foregroundStyle(Brand.text2)
                                .padding(.horizontal, 12).padding(.vertical, 7)
                                .background(Brand.hairline.opacity(0.5), in: Capsule())
                        }
                    }
                }
            }
        }
        .glassCard()
    }

    private var basicsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Component name", text: $name).font(.headline).foregroundStyle(Brand.text)
            Divider().overlay(Brand.hairline)
            HStack {
                Text("Category").foregroundStyle(Brand.text2); Spacer()
                Picker("Category", selection: $category) { ForEach(WearEngine.categories, id: \.self) { Text($0).tag($0) } }.tint(Brand.text)
            }
            Divider().overlay(Brand.hairline)
            HStack {
                Text("Installed at (\(Units.label(miles: miles)))").foregroundStyle(Brand.text2)
                Spacer()
                TextField("0", value: $installedAt, format: .number).keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing).font(Brand.mono(15)).foregroundStyle(Brand.text).frame(width: 90)
            }
            Divider().overlay(Brand.hairline)
            DatePicker("Installed date", selection: $installedDate, displayedComponents: .date)
                .tint(Brand.text).foregroundStyle(Brand.text2)
        }
        .font(.subheadline).glassCard()
    }

    private var lifeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Expected life")
            HStack {
                Text("Distance (\(Units.label(miles: miles)))").foregroundStyle(Brand.text2)
                Spacer()
                TextField("0 = none", value: $lifespanDistance, format: .number).keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing).font(Brand.mono(15)).foregroundStyle(Brand.text).frame(width: 100)
            }
            Divider().overlay(Brand.hairline)
            Stepper("Time: \(lifespanDays == 0 ? "none" : "\(lifespanDays) days")", value: $lifespanDays, in: 0...3650, step: 30)
                .foregroundStyle(Brand.text2)
            Text("Set either or both. Wear uses whichever is further along.")
                .font(.caption2).foregroundStyle(Brand.text3)
        }
        .font(.subheadline).glassCard()
    }

    private var replaceCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Maintenance")
            Button {
                replace()
            } label: {
                Label("Replace — reset wear to 0", systemImage: "arrow.triangle.2.circlepath").frame(maxWidth: .infinity)
            }
            .buttonStyle(GlassButtonStyle())
            Button(role: .destructive) {
                if let c = existing { context.delete(c); try? context.save(); Haptics.warning(); dismiss() }
            } label: { Label("Remove component", systemImage: "trash").frame(maxWidth: .infinity) }
            .buttonStyle(GlassButtonStyle())
        }
        .glassCard()
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(text: "Notes")
            TextField("Brand, model, part number…", text: $notes, axis: .vertical)
                .lineLimit(2...5).font(.subheadline).foregroundStyle(Brand.text)
        }.glassCard()
    }

    private func load() {
        installedAt = Units.kmTo(bike.odometerKm, miles: miles)
        guard let c = existing else { return }
        name = c.name; category = c.category
        lifespanDistance = Units.kmTo(c.lifespanKm, miles: miles)
        lifespanDays = c.lifespanDays
        installedAt = Units.kmTo(c.installedAtKm, miles: miles)
        installedDate = c.installedDate
        notes = c.notes
    }

    private func replace() {
        guard let c = existing else { return }
        c.installedAtKm = bike.odometerKm
        c.installedDate = Date()
        let svc = ServiceRecord(date: Date(), componentName: c.name, action: "Replaced",
                                atKm: bike.odometerKm, notes: "Reset via component screen")
        svc.bike = bike
        context.insert(svc)
        try? context.save(); Haptics.success(); dismiss()
    }

    private func save() {
        let t = name.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        let c: Component
        if let existing { c = existing } else {
            c = Component(name: t, installedAtKm: Units.toKm(installedAt, miles: miles))
            c.bike = bike
            context.insert(c)
        }
        c.name = t; c.category = category
        c.lifespanKm = max(0, Units.toKm(lifespanDistance, miles: miles))
        c.lifespanDays = max(0, lifespanDays)
        c.installedAtKm = Units.toKm(installedAt, miles: miles)
        c.installedDate = installedDate
        c.notes = notes
        try? context.save(); Haptics.success(); dismiss()
    }
}

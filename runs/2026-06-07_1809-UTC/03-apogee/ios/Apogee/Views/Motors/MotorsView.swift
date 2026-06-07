import SwiftUI
import SwiftData

/// The Motors tab: the catalog grouped by NAR impulse class. Catalog motors are
/// read-only; custom motors (isCustom) can be edited or deleted. New custom
/// motors are added with the + button.
struct MotorsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Motor.totalImpulseNs) private var motors: [Motor]
    @State private var showingNew = false

    /// Motors grouped by impulse class, in ascending impulse order.
    private var grouped: [(key: String, motors: [Motor])] {
        let order = ["1/2A/A", "A", "B", "C", "D", "E", "F", "G"]
        let dict = Dictionary(grouping: motors) { $0.impulseClass }
        return order.compactMap { key in
            guard let group = dict[key], !group.isEmpty else { return nil }
            return (key, group.sorted { $0.totalImpulseNs < $1.totalImpulseNs })
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                content
            }
            .navigationTitle("Motors")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap()
                        showingNew = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add custom motor")
                }
            }
            .sheet(isPresented: $showingNew) {
                MotorEditView(motor: nil)
            }
        }
    }

    @ViewBuilder private var content: some View {
        if motors.isEmpty {
            EmptyStateView(
                icon: "flame",
                title: "No motors",
                message: "Add a custom motor with +, or erase and reseed from Settings to restore the catalog.")
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    ForEach(grouped, id: \.key) { section in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                SectionTitle(text: "Class \(section.key)")
                                Spacer()
                                Text("\(section.motors.count)")
                                    .font(Brand.mono(12, weight: .medium))
                                    .foregroundStyle(Brand.text3)
                            }
                            ForEach(section.motors) { motor in
                                NavigationLink {
                                    MotorDetailView(motor: motor)
                                } label: {
                                    MotorRow(motor: motor)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    if motor.isCustom {
                                        Button(role: .destructive) {
                                            delete(motor)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
    }

    private func delete(_ motor: Motor) {
        Haptics.warning()
        withAnimation(Brand.ease()) {
            context.delete(motor)
            try? context.save()
        }
    }
}

private struct MotorRow: View {
    let motor: Motor
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(motor.designation)
                        .font(.headline)
                        .foregroundStyle(Brand.text)
                    if motor.isCustom {
                        Badge(text: "custom", color: Brand.magic)
                    }
                }
                Text(motor.manufacturer)
                    .font(Brand.mono(11))
                    .foregroundStyle(Brand.text3)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Format.newtons(motor.avgThrustN, decimals: 0)) avg")
                    .font(Brand.mono(12, weight: .medium))
                    .foregroundStyle(Brand.text2)
                Text("\(Format.number(motor.totalImpulseNs, decimals: 1)) N·s · \(Format.seconds(motor.burnTimeS))")
                    .font(Brand.mono(10))
                    .foregroundStyle(Brand.text3)
            }
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Brand.text3)
                .accessibilityHidden(true)
        }
        .glassCard(padding: 14)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(motor.designation) by \(motor.manufacturer), \(Format.number(motor.totalImpulseNs, decimals: 1)) newton seconds, average thrust \(Format.newtons(motor.avgThrustN, decimals: 0))")
    }
}

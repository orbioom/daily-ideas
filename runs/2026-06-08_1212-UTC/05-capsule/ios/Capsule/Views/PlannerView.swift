import SwiftUI
import SwiftData

struct PlannerView: View {
    @Environment(\.modelContext) private var context
    @Query private var plans: [OutfitPlan]
    @Query(sort: \Outfit.createdAt, order: .reverse) private var outfits: [Outfit]

    @State private var selectedDay = Calendar.current.startOfDay(for: .now)
    @State private var showPicker = false

    private let calendar = Calendar.current
    private let engine = WardrobeEngine()

    /// Next 14 days for the strip.
    private var days: [Date] {
        (0..<14).compactMap { calendar.date(byAdding: .day, value: $0, to: calendar.startOfDay(for: .now)) }
    }

    private func plan(for day: Date) -> OutfitPlan? {
        plans.first { calendar.isDate($0.date, inSameDayAs: day) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(spacing: 16) {
                        dayStrip
                        selectedDayCard
                        upcomingCard
                    }
                    .padding()
                }
            }
            .navigationTitle("Planner")
            .sheet(isPresented: $showPicker) {
                OutfitPickerSheet(outfits: outfits) { chosen in
                    assign(chosen, to: selectedDay)
                }
            }
        }
    }

    private var dayStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(days, id: \.self) { day in
                    let isSel = calendar.isDate(day, inSameDayAs: selectedDay)
                    let hasPlan = plan(for: day) != nil
                    Button {
                        withAnimation(Brand.ease(0.2)) { selectedDay = day }
                        Haptics.selection()
                    } label: {
                        VStack(spacing: 4) {
                            Text(Format.weekdayShort.string(from: day))
                                .font(Brand.mono(10)).foregroundStyle(isSel ? .white : Brand.text3)
                            Text(Format.dayOfMonth.string(from: day))
                                .font(.headline).foregroundStyle(isSel ? .white : Brand.text)
                            Circle().fill(hasPlan ? (isSel ? Color.white : Color.accentColor) : .clear)
                                .frame(width: 5, height: 5)
                        }
                        .frame(width: 48, height: 66)
                        .background(RoundedRectangle(cornerRadius: 14)
                            .fill(isSel ? Color.accentColor : Color.clear))
                        .overlay(RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Brand.glassStroke.opacity(isSel ? 0 : 0.4), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(Format.dayFull.string(from: day))\(hasPlan ? ", outfit planned" : "")")
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private var selectedDayCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Format.dayFull.string(from: selectedDay))
                .font(.headline).foregroundStyle(Brand.text)
            if let p = plan(for: selectedDay), let outfit = p.outfit {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(outfit.name).font(.subheadline.weight(.semibold)).foregroundStyle(Brand.text)
                        Spacer()
                        if p.worn {
                            Label("Worn", systemImage: "checkmark.seal.fill")
                                .font(.caption).foregroundStyle(Brand.live)
                        }
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(outfit.items.prefix(8)) { item in
                                ItemSwatch(colorHex: item.colorHex, symbol: item.category.symbol, size: 52, corner: 12)
                            }
                        }
                    }
                    HStack(spacing: 10) {
                        if !p.worn {
                            Button {
                                markWorn(p, outfit: outfit)
                            } label: { Label("Wore it", systemImage: "checkmark") }
                                .buttonStyle(InkButtonStyle())
                        }
                        Button {
                            context.delete(p); Haptics.warning()
                        } label: { Label("Clear", systemImage: "xmark") }
                            .buttonStyle(GlassButtonStyle())
                    }
                }
            } else {
                Button {
                    if outfits.isEmpty { return }
                    showPicker = true
                } label: {
                    Label(outfits.isEmpty ? "Create an outfit first" : "Plan an outfit", systemImage: "plus")
                }
                .buttonStyle(InkButtonStyle())
                .disabled(outfits.isEmpty)
            }
        }
        .glassCard()
    }

    private var upcomingCard: some View {
        let upcoming = plans
            .filter { $0.outfit != nil && $0.date >= calendar.startOfDay(for: .now) }
            .sorted { $0.date < $1.date }
        return Group {
            if upcoming.isEmpty {
                EmptyStateView(icon: "calendar", title: "Nothing planned",
                               message: "Pick a day above and assign an outfit to plan ahead.")
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Upcoming").font(.headline).foregroundStyle(Brand.text)
                    ForEach(upcoming.prefix(8)) { p in
                        HStack {
                            Text(Format.dayFull.string(from: p.date)).font(.subheadline).foregroundStyle(Brand.text2)
                            Spacer()
                            Text(p.outfit?.name ?? "").font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                            if p.worn {
                                Image(systemName: "checkmark.seal.fill").font(.caption).foregroundStyle(Brand.live)
                            }
                        }
                    }
                }
                .glassCard()
            }
        }
    }

    private func assign(_ outfit: Outfit, to day: Date) {
        if let existing = plan(for: day) {
            existing.outfit = outfit
            existing.worn = false
        } else {
            context.insert(OutfitPlan(date: calendar.startOfDay(for: day), outfit: outfit))
        }
        Haptics.success()
    }

    private func markWorn(_ plan: OutfitPlan, outfit: Outfit) {
        for pair in engine.wearLogs(for: outfit, on: plan.date) {
            context.insert(WearLog(date: pair.date, item: pair.item))
        }
        plan.worn = true
        Haptics.success()
    }
}

struct OutfitPickerSheet: View {
    let outfits: [Outfit]
    let onPick: (Outfit) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                List {
                    ForEach(outfits) { o in
                        Button {
                            onPick(o); dismiss()
                        } label: {
                            HStack {
                                Text(o.name.isEmpty ? "Untitled" : o.name).foregroundStyle(Brand.text)
                                Spacer()
                                Text("\(o.items.count) pieces").font(.caption).foregroundStyle(Brand.text3)
                            }
                        }
                        .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Choose outfit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Cancel") { dismiss() } } }
        }
    }
}

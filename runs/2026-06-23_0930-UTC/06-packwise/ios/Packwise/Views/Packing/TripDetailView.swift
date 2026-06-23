import SwiftUI
import SwiftData

/// Screen 3 — the packing checklist for a single trip.
struct TripDetailView: View {
    @Bindable var trip: Trip
    @Environment(\.modelContext) private var context
    @Query private var allSettings: [AppSettings]
    @AppStorage("activeTripID") private var activeTripID: String = ""

    @State private var showingAddItem = false
    @State private var showingEdit = false
    @State private var showingTemplatePicker = false
    @State private var showingRegenerateConfirm = false
    @State private var collapsed: Set<String> = []
    @State private var showCompletedBanner = false

    private var settings: AppSettings? { allSettings.first }
    private var hapticsOn: Bool { settings?.hapticsEnabled ?? true }
    private var style: PackingStyle { settings?.packingStyle ?? .normal }

    private var sortedItems: [PackItem] {
        trip.items.sorted {
            if $0.category.sortIndex != $1.category.sortIndex {
                return $0.category.sortIndex < $1.category.sortIndex
            }
            if $0.sortOrder != $1.sortOrder { return $0.sortOrder < $1.sortOrder }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    private var categoriesPresent: [PackCategory] {
        let present = Set(trip.items.map(\.category))
        return PackCategory.allCases
            .filter { present.contains($0) }
            .sorted { $0.sortIndex < $1.sortIndex }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Space.lg) {
                header
                if trip.items.isEmpty {
                    EmptyStateView(
                        symbol: "tray",
                        title: "This list is empty",
                        message: "Add an item or apply a template to start packing.",
                        actionTitle: "Add an item",
                        action: { showingAddItem = true }
                    )
                    .padding(.top, Theme.Space.xl)
                } else {
                    ForEach(categoriesPresent) { category in
                        categorySection(category)
                    }
                }
            }
            .padding(Theme.Space.lg)
        }
        .background(Theme.background)
        .navigationTitle(trip.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        activeTripID = trip.id.uuidString
                    } label: {
                        Label("Set as active trip", systemImage: "checklist")
                    }
                    Button {
                        showingAddItem = true
                    } label: {
                        Label("Add item", systemImage: "plus")
                    }
                    Button {
                        showingTemplatePicker = true
                    } label: {
                        Label("Apply template", systemImage: "square.stack.3d.up")
                    }
                    Button {
                        showingEdit = true
                    } label: {
                        Label("Edit trip", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        showingRegenerateConfirm = true
                    } label: {
                        Label("Regenerate list", systemImage: "arrow.triangle.2.circlepath")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Trip options")
            }
        }
        .sheet(isPresented: $showingAddItem) {
            AddItemSheet { name, qty, category in
                addItem(name: name, quantity: qty, category: category)
            }
        }
        .sheet(isPresented: $showingEdit) {
            EditTripSheet(trip: trip)
        }
        .sheet(isPresented: $showingTemplatePicker) {
            TemplatePickerSheet { template in
                apply(template)
            }
        }
        .confirmationDialog(
            "Regenerate this list?",
            isPresented: $showingRegenerateConfirm,
            titleVisibility: .visible
        ) {
            Button("Regenerate", role: .destructive) { regenerate() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This replaces all generated items with a fresh list. Custom items you added are kept.")
        }
        .overlay(alignment: .top) {
            if showCompletedBanner {
                completedBanner
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(spacing: Theme.Space.lg) {
            HStack(spacing: Theme.Space.lg) {
                ProgressRing(progress: trip.progress, size: 92,
                             tint: trip.isComplete ? Theme.success : Theme.primary)
                VStack(alignment: .leading, spacing: Theme.Space.xs) {
                    Label(trip.destination, systemImage: "mappin.and.ellipse")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.textPrimary)
                    Text(trip.dateRangeText)
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                    Text("\(trip.packedCount) of \(trip.totalCount) packed")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Theme.textSecondary)
                        .monospacedDigit()
                }
                Spacer()
            }

            HStack(spacing: Theme.Space.sm) {
                StatPill(value: "\(trip.nights)", label: "Nights", tint: trip.tripType.tint)
                StatPill(value: "\(trip.travelerCount)", label: "Travelers", tint: Theme.primary)
                StatPill(value: "\(trip.totalCount)", label: "Items", tint: Theme.secondary)
            }

            if activeTripID == trip.id.uuidString {
                Label("Active trip — shown on the Packing tab", systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Theme.success)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .card()
    }

    // MARK: Category section

    private func categorySection(_ category: PackCategory) -> some View {
        let items = sortedItems.filter { $0.category == category }
        let packed = items.filter(\.isPacked).count
        let isCollapsed = collapsed.contains(category.rawValue)

        return VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if isCollapsed { collapsed.remove(category.rawValue) }
                    else { collapsed.insert(category.rawValue) }
                }
            } label: {
                HStack(spacing: Theme.Space.md) {
                    IconBadge(symbol: category.symbol, tint: category.tint, size: 34)
                    Text(category.title)
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Text("\(packed)/\(items.count)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.textSecondary)
                        .monospacedDigit()
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Theme.textSecondary)
                        .rotationEffect(.degrees(isCollapsed ? -90 : 0))
                        .accessibilityHidden(true)
                }
                .padding(Theme.Space.md)
            }
            .buttonStyle(.plain)
            .accessibilityHint(isCollapsed ? "Expands this category" : "Collapses this category")

            if !isCollapsed {
                VStack(spacing: 0) {
                    ForEach(items) { item in
                        PackItemRow(item: item, hapticsOn: hapticsOn) {
                            toggle(item)
                        }
                        if item.id != items.last?.id {
                            Divider().background(Theme.hairline)
                                .padding(.leading, Theme.Space.xl + Theme.Space.lg)
                        }
                    }
                }
            }
        }
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .strokeBorder(Theme.hairline, lineWidth: 1)
        )
    }

    private var completedBanner: some View {
        Label("All packed — you're ready to go!", systemImage: "checkmark.seal.fill")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, Theme.Space.lg)
            .padding(.vertical, Theme.Space.md)
            .background(Theme.success)
            .clipShape(Capsule())
            .padding(.top, Theme.Space.sm)
            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
    }

    // MARK: Actions

    private func toggle(_ item: PackItem) {
        item.isPacked.toggle()
        try? context.save()
        Haptics.impact(.light, enabled: hapticsOn)
        if trip.isComplete {
            Haptics.notify(.success, enabled: hapticsOn)
            withAnimation { showCompletedBanner = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
                withAnimation { showCompletedBanner = false }
            }
        }
    }

    private func addItem(name: String, quantity: Int, category: PackCategory) {
        let order = (trip.items.map(\.sortOrder).max() ?? 0) + 1
        let item = PackItem(name: name, quantity: quantity, category: category,
                            isCustom: true, sortOrder: order)
        item.trip = trip
        trip.items.append(item)
        context.insert(item)
        try? context.save()
        Haptics.impact(.medium, enabled: hapticsOn)
    }

    private func apply(_ template: Template) {
        let existing = Set(trip.items.map { $0.name.lowercased() })
        var order = (trip.items.map(\.sortOrder).max() ?? 0) + 1
        for ti in template.items where !existing.contains(ti.name.lowercased()) {
            let item = PackItem(name: ti.name, quantity: ti.quantity,
                                category: ti.category, isCustom: true, sortOrder: order)
            item.trip = trip
            trip.items.append(item)
            context.insert(item)
            order += 1
        }
        try? context.save()
        Haptics.notify(.success, enabled: hapticsOn)
    }

    private func regenerate() {
        // Keep custom items, remove generated ones.
        let custom = trip.items.filter(\.isCustom)
        for item in trip.items where !item.isCustom {
            context.delete(item)
        }
        let generated = PackingEngine.generate(
            tripType: trip.tripType,
            nights: trip.nights,
            travelers: trip.travelerCount,
            activities: trip.activities,
            style: style
        )
        let customNames = Set(custom.map { $0.name.lowercased() })
        var order = 0
        for g in generated where !customNames.contains(g.name.lowercased()) {
            let item = PackItem(name: g.name, quantity: g.quantity,
                                category: g.category, sortOrder: order)
            item.trip = trip
            trip.items.append(item)
            context.insert(item)
            order += 1
        }
        try? context.save()
        Haptics.notify(.success, enabled: hapticsOn)
    }
}

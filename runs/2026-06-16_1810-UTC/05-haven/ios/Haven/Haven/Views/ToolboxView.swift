import SwiftUI
import SwiftData
import UIKit

/// Coping items (favorites first), reassurance management, the safety-plan entry,
/// and a "Call my person" action. Adding custom items is Pro-gated past a free cap.
struct ToolboxView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.modelContext) private var context

    @Query(sort: [SortDescriptor(\CopingItem.sortOrder)]) private var coping: [CopingItem]
    @Query private var reassurance: [ReassuranceCard]

    @AppStorage(PrefKey.isPro) private var isPro = false
    @AppStorage(PrefKey.hapticsEnabled) private var hapticsEnabled = true
    @AppStorage(PrefKey.emergencyContactName) private var contactName = ""
    @AppStorage(PrefKey.emergencyContactPhone) private var contactPhone = ""

    @State private var showAddCoping = false
    @State private var showAddReassurance = false
    @State private var showPaywall = false
    @State private var showReassuranceDeck = false
    @State private var noContactAlert = false

    private var sortedCoping: [CopingItem] {
        coping.sorted { lhs, rhs in
            if lhs.isFavorite != rhs.isFavorite { return lhs.isFavorite && !rhs.isFavorite }
            return lhs.sortOrder < rhs.sortOrder
        }
    }

    private var customCopingCount: Int { coping.filter { $0.isCustom }.count }
    private var customReassuranceCount: Int { reassurance.filter { $0.isCustom }.count }

    var body: some View {
        NavigationStack {
            ZStack {
                HavenBackground()
                ScrollView {
                    VStack(spacing: 22) {
                        callPersonCard
                        copingSection
                        reassuranceSection
                        safetyPlanLink
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Toolbox")
            .sheet(isPresented: $showAddCoping) { AddCopingView() }
            .sheet(isPresented: $showAddReassurance) { AddReassuranceView() }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showReassuranceDeck) { ReassuranceDeckView() }
            .alert("No safe person yet", isPresented: $noContactAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Add a name and phone number in Settings to enable one-tap calling.")
            }
        }
    }

    // MARK: Call my person

    private var callPersonCard: some View {
        HavenCard {
            HStack(spacing: 14) {
                Image(systemName: "phone.circle.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(HavenTheme.accent)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Call my person")
                        .font(.headline)
                        .foregroundStyle(HavenTheme.primaryText(scheme))
                    Text(contactName.isEmpty ? "No one added yet" : contactName)
                        .font(.subheadline)
                        .foregroundStyle(HavenTheme.secondaryText(scheme))
                }
                Spacer()
                Button("Call") { callPerson() }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20).padding(.vertical, 10)
                    .background(HavenTheme.sosGradient)
                    .clipShape(Capsule())
                    .accessibilityLabel(contactName.isEmpty ? "Call my person" : "Call \(contactName)")
            }
        }
    }

    private func callPerson() {
        guard let url = PhoneURL.make(from: contactPhone) else { noContactAlert = true; return }
        UIApplication.shared.open(url)
    }

    // MARK: Coping

    private var copingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionTitle(text: "Coping reminders", systemImage: "sparkles")
                Spacer()
                addButton {
                    if isPro || customCopingCount < Limits.freeCustomCopingCap {
                        showAddCoping = true
                    } else {
                        showPaywall = true
                    }
                }
            }
            if sortedCoping.isEmpty {
                EmptyStateView(icon: "sparkles", title: "Your toolkit is empty",
                               message: "Add a reminder or action that helps you feel steady.")
            } else {
                ForEach(sortedCoping) { item in
                    copingRow(item)
                }
            }
        }
    }

    private func copingRow(_ item: CopingItem) -> some View {
        HavenCard(padding: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: item.copingKind.systemImage)
                    .font(.title3)
                    .foregroundStyle(HavenTheme.accentDeep)
                    .frame(width: 30)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(HavenTheme.primaryText(scheme))
                    if !item.detail.isEmpty {
                        Text(item.detail)
                            .font(.caption)
                            .foregroundStyle(HavenTheme.secondaryText(scheme))
                    }
                }
                Spacer()
                Button {
                    toggleFavorite(item)
                } label: {
                    Image(systemName: item.isFavorite ? "star.fill" : "star")
                        .foregroundStyle(item.isFavorite ? HavenTheme.warmAmber : HavenTheme.secondaryText(scheme))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.isFavorite ? "Remove \(item.title) from favorites" : "Add \(item.title) to favorites")
            }
        }
        .contextMenu {
            Button {
                toggleFavorite(item)
            } label: {
                Label(item.isFavorite ? "Unfavorite" : "Favorite",
                      systemImage: item.isFavorite ? "star.slash" : "star")
            }
            if item.isCustom {
                Button(role: .destructive) { delete(item) } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func toggleFavorite(_ item: CopingItem) {
        item.isFavorite.toggle()
        if hapticsEnabled { Haptics.selection() }
        try? context.save()
    }

    private func delete(_ item: CopingItem) {
        context.delete(item)
        try? context.save()
    }

    // MARK: Reassurance

    private var reassuranceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionTitle(text: "Reassurance cards", systemImage: "quote.bubble")
                Spacer()
                addButton {
                    if isPro || customReassuranceCount < Limits.freeCustomReassuranceCap {
                        showAddReassurance = true
                    } else {
                        showPaywall = true
                    }
                }
            }
            HavenCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("\(reassurance.count) calming reminders")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(HavenTheme.primaryText(scheme))
                    Text("Swipe through gentle lines whenever you need them.")
                        .font(.caption)
                        .foregroundStyle(HavenTheme.secondaryText(scheme))
                    Button {
                        showReassuranceDeck = true
                    } label: {
                        Text("Open the deck")
                    }
                    .havenPillButton(filled: false)
                }
            }
        }
    }

    // MARK: Safety plan

    private var safetyPlanLink: some View {
        NavigationLink {
            SafetyPlanView()
        } label: {
            HavenCard {
                HStack(spacing: 12) {
                    Image(systemName: "list.bullet.clipboard")
                        .font(.title3)
                        .foregroundStyle(HavenTheme.accent)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("My safety plan")
                            .font(.headline)
                            .foregroundStyle(HavenTheme.primaryText(scheme))
                        Text("Warning signs, reasons to stay safe, who to call.")
                            .font(.caption)
                            .foregroundStyle(HavenTheme.secondaryText(scheme))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(HavenTheme.secondaryText(scheme))
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens your personal safety plan")
    }

    private func addButton(_ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "plus.circle.fill")
                .font(.title2)
                .foregroundStyle(HavenTheme.accent)
        }
        .accessibilityLabel("Add custom item")
    }
}

// MARK: - Add custom coping

struct AddCopingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @Environment(\.modelContext) private var context
    @Query private var existing: [CopingItem]

    @State private var title = ""
    @State private var detail = ""
    @State private var kind: CopingKind = .statement

    private var canSave: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                HavenBackground()
                Form {
                    Section("What helps you?") {
                        TextField("A reminder or action", text: $title, axis: .vertical)
                            .accessibilityLabel("Title")
                        TextField("A little more detail (optional)", text: $detail, axis: .vertical)
                            .accessibilityLabel("Detail")
                    }
                    Section("Type") {
                        Picker("Type", selection: $kind) {
                            ForEach(CopingKind.allCases) { k in
                                Text(k.label).tag(k)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("New reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }.disabled(!canSave)
                }
            }
        }
    }

    private func save() {
        guard canSave else { return }
        let order = (existing.map(\.sortOrder).max() ?? 0) + 1
        let item = CopingItem(
            title: title.trimmingCharacters(in: .whitespaces),
            detail: detail.trimmingCharacters(in: .whitespaces),
            kind: kind, isCustom: true, sortOrder: order
        )
        context.insert(item)
        try? context.save()
        dismiss()
    }
}

// MARK: - Add custom reassurance

struct AddReassuranceView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var text = ""
    private var canSave: Bool { !text.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                HavenBackground()
                Form {
                    Section("A kind line for yourself") {
                        TextField("Something gentle and true", text: $text, axis: .vertical)
                            .lineLimit(3...6)
                            .accessibilityLabel("Reassurance text")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("New card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) { Button("Save") { save() }.disabled(!canSave) }
            }
        }
    }

    private func save() {
        guard canSave else { return }
        context.insert(ReassuranceCard(text: text.trimmingCharacters(in: .whitespaces), isCustom: true))
        try? context.save()
        dismiss()
    }
}

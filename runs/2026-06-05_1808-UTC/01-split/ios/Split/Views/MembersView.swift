import SwiftUI
import SwiftData

/// Manage a group's members: add, rename, and remove. Removal is guarded when a
/// member is referenced by any expense or settlement, to keep balances intact.
struct MembersView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var context

    @Bindable var group: SplitGroup

    @State private var newName = ""
    @State private var renameTarget: Member?
    @State private var renameText = ""
    @State private var removeTarget: Member?
    @State private var blockedMessage: String?
    @State private var toast: String?

    var body: some View {
        ZStack {
            Brand.pageBackground

            Form {
                Section {
                    HStack {
                        TextField("Add a member", text: $newName)
                            .accessibilityLabel("New member name")
                            .onSubmit(addMember)
                        Button(action: addMember) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundStyle(canAdd ? Brand.live : Brand.text3)
                        }
                        .disabled(!canAdd)
                        .accessibilityLabel("Add member")
                    }
                } header: {
                    Text("Add")
                } footer: {
                    if let blockedMessage {
                        Text(blockedMessage).foregroundStyle(Brand.owe)
                    }
                }

                Section("Members") {
                    if group.members.isEmpty {
                        Text("No members yet. Add the people sharing these costs.")
                            .font(.subheadline)
                            .foregroundStyle(Brand.text3)
                    } else {
                        ForEach(group.orderedMembers) { member in
                            HStack(spacing: 12) {
                                MemberAvatar(member: member, size: 30)
                                Text(member.name)
                                    .foregroundStyle(Brand.text)
                                Spacer()
                                Text(usageSummary(member))
                                    .font(.caption)
                                    .foregroundStyle(Brand.text3)
                            }
                            .contentShape(Rectangle())
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    attemptRemove(member)
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                                Button {
                                    renameTarget = member
                                    renameText = member.name
                                } label: {
                                    Label("Rename", systemImage: "pencil")
                                }
                                .tint(Brand.text2)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(member.name), \(usageSummary(member))")
                            .accessibilityHint("Swipe left to rename or remove")
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Members")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Rename member", isPresented: renameBinding) {
            TextField("Name", text: $renameText)
            Button("Save") { commitRename() }
            Button("Cancel", role: .cancel) { renameTarget = nil }
        }
        .alert("Can't remove this member", isPresented: removeBlockedBinding, presenting: removeTarget) { _ in
            Button("OK", role: .cancel) { removeTarget = nil }
        } message: { member in
            Text("\(member.name) is part of existing expenses or payments. Remove or reassign those first.")
        }
        .overlay(alignment: .bottom) {
            if let toast { ToastView(message: toast) }
        }
    }

    // MARK: - Logic

    private var canAdd: Bool {
        !newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func addMember() {
        let clean = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        let duplicate = group.members.contains {
            $0.name.compare(clean, options: .caseInsensitive) == .orderedSame
        }
        if duplicate {
            blockedMessage = "There's already a member named \"\(clean)\"."
            return
        }
        blockedMessage = nil
        let hue = group.members.count
        let member = Member(name: clean, colorHue: hue)
        member.group = group
        group.members.append(member)
        context.insert(member)
        newName = ""
        Haptics.success(enabled: settings.hapticsEnabled)
    }

    private func commitRename() {
        guard let member = renameTarget else { return }
        let clean = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { renameTarget = nil; return }
        let duplicate = group.members.contains {
            $0.id != member.id &&
            $0.name.compare(clean, options: .caseInsensitive) == .orderedSame
        }
        if duplicate {
            blockedMessage = "There's already a member named \"\(clean)\"."
            renameTarget = nil
            return
        }
        member.name = clean
        renameTarget = nil
        Haptics.success(enabled: settings.hapticsEnabled)
        flash("Renamed")
    }

    private func attemptRemove(_ member: Member) {
        if isReferenced(member) {
            removeTarget = member
            return
        }
        context.delete(member)
        Haptics.warning(enabled: settings.hapticsEnabled)
        flash("Member removed")
    }

    /// True if the member is the payer, a participant, or part of any settlement.
    private func isReferenced(_ member: Member) -> Bool {
        let inExpenses = group.expenses.contains { expense in
            expense.payer?.id == member.id ||
            expense.shares.contains { $0.member?.id == member.id }
        }
        let inSettlements = group.settlements.contains {
            $0.fromMember?.id == member.id || $0.toMember?.id == member.id
        }
        return inExpenses || inSettlements
    }

    private func usageSummary(_ member: Member) -> String {
        let count = group.expenses.filter {
            $0.payer?.id == member.id || $0.shares.contains { $0.member?.id == member.id }
        }.count
        if count == 0 { return "no expenses" }
        return "\(count) expense\(count == 1 ? "" : "s")"
    }

    // MARK: - Bindings

    private var renameBinding: Binding<Bool> {
        Binding(get: { renameTarget != nil },
                set: { if !$0 { renameTarget = nil } })
    }

    private var removeBlockedBinding: Binding<Bool> {
        Binding(get: { removeTarget != nil },
                set: { if !$0 { removeTarget = nil } })
    }

    private func flash(_ message: String) {
        withAnimation(Brand.ease()) { toast = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(Brand.ease()) { toast = nil }
        }
    }
}

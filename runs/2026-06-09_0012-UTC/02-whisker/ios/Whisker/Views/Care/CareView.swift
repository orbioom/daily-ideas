import SwiftUI
import SwiftData

struct CareView: View {
    @Environment(\.modelContext) private var context
    @Query private var pets: [Pet]

    private var due: [PetEngine.DueTask] { PetEngine.dueTasks(for: pets) }

    private var sections: [(PetEngine.Bucket, [PetEngine.DueTask])] {
        let buckets: [PetEngine.Bucket] = [.overdue, .today, .soon, .later]
        return buckets.compactMap { b in
            let items = due.filter { $0.bucket == b }
            return items.isEmpty ? nil : (b, items)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if pets.filter({ !$0.isArchived }).isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "pawprint",
                                       title: "No pets yet",
                                       message: "Add a pet in the Pets tab to start tracking their care.")
                            .glassCard().padding(20)
                    }
                } else if due.isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "checkmark.seal.fill",
                                       title: "All caught up",
                                       message: "No care tasks yet. Add some from each pet's profile.")
                            .glassCard().padding(20)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            ForEach(sections, id: \.0.rawValue) { bucket, items in
                                sectionView(bucket, items)
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle("Care")
        }
    }

    private func sectionView(_ bucket: PetEngine.Bucket, _ items: [PetEngine.DueTask]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                StatusDot(color: bucketColor(bucket))
                Eyebrow(text: PetEngine.bucketLabel(bucket))
                Spacer()
                Text("\(items.count)").font(Brand.mono(13)).foregroundStyle(Brand.text3)
            }
            ForEach(items) { item in
                taskRow(item)
            }
        }
        .glassCard()
    }

    private func taskRow(_ item: PetEngine.DueTask) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(item.task.kind.tint.opacity(0.18)).frame(width: 40, height: 40)
                Image(systemName: item.task.kind.icon).foregroundStyle(item.task.kind.tint)
            }
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.task.title).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                HStack(spacing: 6) {
                    PetAvatar(pet: item.pet, size: 16)
                    Text(item.pet.name).font(.caption).foregroundStyle(Brand.text2)
                    Text("· \(PetEngine.dueLabel(item.daysUntil))")
                        .font(.caption)
                        .foregroundStyle(item.bucket == .overdue ? Brand.danger : Brand.text3)
                }
            }
            Spacer()
            Button {
                Haptics.success()
                item.task.lastDone = Calendar.current.startOfDay(for: .now)
                try? context.save()
            } label: {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Brand.live)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Mark \(item.task.title) done for \(item.pet.name)")
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private func bucketColor(_ b: PetEngine.Bucket) -> Color {
        switch b {
        case .overdue: return Brand.danger
        case .today: return Brand.warn
        case .soon: return Brand.info
        case .later: return Brand.text3
        }
    }
}

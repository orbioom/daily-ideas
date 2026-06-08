import SwiftUI
import SwiftData

struct TemplatesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \BlockTemplate.defaultStartMinute) private var templates: [BlockTemplate]

    @State private var editing: BlockTemplate?
    @State private var showingNew = false
    @State private var banner: String?

    private let cal = Calendar.current

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Brand.pageBackground
                if templates.isEmpty {
                    EmptyStateView(icon: "square.stack.3d.up",
                                   title: "No routines yet",
                                   message: "Save blocks you schedule again and again, then add them to any day in a tap.")
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(templates) { t in
                                TemplateCard(template: t,
                                             onAddToday: { addToToday(t) },
                                             onApplyWeek: { applyToWeekdays(t) },
                                             onEdit: { editing = t },
                                             onDelete: { delete(t) })
                            }
                        }
                        .padding()
                    }
                }
                if let banner {
                    Text(banner)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(Brand.live, in: Capsule())
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .navigationTitle("Routines")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingNew = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("New routine")
                }
            }
            .sheet(item: $editing) { t in TemplateEditorView(mode: .edit(t)) }
            .sheet(isPresented: $showingNew) { TemplateEditorView(mode: .create) }
        }
    }

    private func flash(_ message: String) {
        withAnimation(Brand.ease(0.25)) { banner = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(Brand.ease(0.25)) { banner = nil }
        }
    }

    private func addToToday(_ t: BlockTemplate) {
        let block = t.makeBlock(on: .now)
        context.insert(block)
        try? context.save()
        Haptics.success()
        flash("Added to today")
    }

    private func applyToWeekdays(_ t: BlockTemplate) {
        // Monday–Friday of the week containing today.
        let today = cal.startOfDay(for: .now)
        let weekday = cal.component(.weekday, from: today) // 1=Sun
        // distance back to Monday (2)
        let backToMonday = ((weekday + 5) % 7)
        guard let monday = cal.date(byAdding: .day, value: -backToMonday, to: today) else { return }
        var count = 0
        for offset in 0..<5 {
            guard let day = cal.date(byAdding: .day, value: offset, to: monday) else { continue }
            context.insert(t.makeBlock(on: day))
            count += 1
        }
        try? context.save()
        Haptics.success()
        flash("Added to \(count) weekdays")
    }

    private func delete(_ t: BlockTemplate) {
        context.delete(t)
        try? context.save()
        Haptics.warning()
    }
}

private struct TemplateCard: View {
    let template: BlockTemplate
    let onAddToday: () -> Void
    let onApplyWeek: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: template.category.icon)
                    .foregroundStyle(template.category.color)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(template.title)
                        .font(.headline)
                        .foregroundStyle(Brand.text)
                    Text("\(ScheduleEngine.clockString(minuteOfDay: template.defaultStartMinute)) · \(ScheduleEngine.durationString(template.durationMinutes))")
                        .font(Brand.mono(11))
                        .foregroundStyle(Brand.text3)
                }
                Spacer()
                Menu {
                    Button("Edit", systemImage: "pencil", action: onEdit)
                    Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(Brand.text3)
                }
                .accessibilityLabel("More options")
            }
            HStack(spacing: 10) {
                Button(action: onAddToday) {
                    Label("Today", systemImage: "plus")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(template.category.color.opacity(0.16), in: RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(template.category.color)
                }
                Button(action: onApplyWeek) {
                    Label("Weekdays", systemImage: "calendar")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(Brand.text)
                }
            }
            .buttonStyle(.plain)
        }
        .glassCard()
    }
}

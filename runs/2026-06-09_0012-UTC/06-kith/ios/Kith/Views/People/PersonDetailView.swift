import SwiftUI
import SwiftData

struct PersonDetailView: View {
    @Bindable var person: Person
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var editing = false
    @State private var loggingInteraction = false
    @State private var addingDate = false
    @State private var editingInteraction: Interaction?
    @State private var editingDate: ImportantDate?
    @State private var confirmDelete = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                header
                quickLog
                if person.cadenceDays > 0 { cadenceCard }
                datesCard
                interactionsCard
                if !person.howWeMet.isEmpty || !person.notes.isEmpty { notesCard }
                Button(role: .destructive) { confirmDelete = true } label: {
                    Label("Delete person", systemImage: "trash").frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyle()).tint(Brand.danger)
            }
            .padding(20)
        }
        .scrollContentBackground(.hidden)
        .background(Brand.pageBackground)
        .navigationTitle(person.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.selection(); person.isFavorite.toggle(); try? context.save()
                } label: { Image(systemName: person.isFavorite ? "star.fill" : "star") }
                    .accessibilityLabel(person.isFavorite ? "Remove favorite" : "Mark favorite")
            }
            ToolbarItem(placement: .topBarTrailing) { Button("Edit") { editing = true } }
        }
        .sheet(isPresented: $editing) { PersonEditorView(person: person) }
        .sheet(isPresented: $loggingInteraction) { InteractionSheet(person: person) }
        .sheet(isPresented: $addingDate) { ImportantDateSheet(person: person, date: nil) }
        .sheet(item: $editingInteraction) { InteractionSheet(person: person, interaction: $0) }
        .sheet(item: $editingDate) { ImportantDateSheet(person: person, date: $0) }
        .alert("Delete \(person.name)?", isPresented: $confirmDelete) {
            Button("Delete", role: .destructive) { context.delete(person); try? context.save(); dismiss() }
            Button("Cancel", role: .cancel) {}
        } message: { Text("This removes the person and all their history.") }
    }

    private var header: some View {
        VStack(spacing: 10) {
            PersonAvatar(person: person, size: 84)
            Label(person.relationship.title, systemImage: person.relationship.icon)
                .font(.subheadline).foregroundStyle(Brand.text2)
            Text(Format.sinceLabel(KithEngine.daysSinceContact(for: person)))
                .font(.caption).foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity)
        .glassCard()
    }

    private var quickLog: some View {
        let cols = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
        let quick: [InteractionType] = [.call, .text, .met, .video]
        return VStack(spacing: 10) {
            LazyVGrid(columns: cols, spacing: 10) {
                ForEach(quick) { type in
                    Button {
                        Haptics.success()
                        let i = Interaction(date: .now, type: type)
                        i.person = person
                        context.insert(i); try? context.save()
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: type.icon).font(.title3).foregroundStyle(type.tint)
                            Text(type.title).font(.caption2).foregroundStyle(Brand.text2)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: 1))
                    }
                    .accessibilityLabel("Log \(type.title)")
                }
            }
            Button { Haptics.tap(); loggingInteraction = true } label: {
                Label("Log with a note", systemImage: "square.and.pencil")
            }
            .buttonStyle(GlassButtonStyle())
        }
    }

    private var cadenceCard: some View {
        let due = KithEngine.nextReachOut(for: person)
        let days = due.map { Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: .now), to: Calendar.current.startOfDay(for: $0)).day ?? 0 }
        return GlassCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Eyebrow(text: "Keep in touch")
                    Text("Every \(person.cadenceDays) days").font(.subheadline).foregroundStyle(Brand.text)
                }
                Spacer()
                if let days {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(KithEngine.dueLabel(days))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(days < 0 ? Brand.danger : (days == 0 ? Brand.warn : Brand.live))
                        Text("next reach-out").font(.caption2).foregroundStyle(Brand.text3)
                    }
                }
            }
        }
    }

    private var datesCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Eyebrow(text: "Important dates")
                    Spacer()
                    Button { Haptics.tap(); addingDate = true } label: { Image(systemName: "plus.circle") }
                        .accessibilityLabel("Add important date")
                }
                if person.dates.isEmpty {
                    Text("Add a birthday or anniversary so you never miss it.")
                        .font(.subheadline).foregroundStyle(Brand.text3)
                } else {
                    ForEach(person.dates.sorted { KithEngine.nextOccurrence(of: $0) < KithEngine.nextOccurrence(of: $1) }) { d in
                        Button { Haptics.tap(); editingDate = d } label: {
                            HStack(spacing: 12) {
                                Image(systemName: d.kind.icon).foregroundStyle(person.color.color).frame(width: 24)
                                    .accessibilityHidden(true)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(d.title).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                                    Text(Format.monthDay.string(from: KithEngine.nextOccurrence(of: d)))
                                        .font(.caption).foregroundStyle(Brand.text3)
                                }
                                Spacer()
                                Text(KithEngine.occasionLabel(daysUntil(d)))
                                    .font(.caption).foregroundStyle(Brand.text2)
                            }
                            .padding(.vertical, 2)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func daysUntil(_ d: ImportantDate) -> Int {
        let occ = KithEngine.nextOccurrence(of: d)
        return Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: .now),
                                               to: Calendar.current.startOfDay(for: occ)).day ?? 0
    }

    private var interactionsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Eyebrow(text: "History")
                if person.interactions.isEmpty {
                    Text("No interactions logged yet. Use the buttons above.")
                        .font(.subheadline).foregroundStyle(Brand.text3)
                } else {
                    ForEach(person.interactions.sorted { $0.date > $1.date }) { i in
                        Button { Haptics.tap(); editingInteraction = i } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle().fill(i.type.tint.opacity(0.18)).frame(width: 34, height: 34)
                                    Image(systemName: i.type.icon).font(.caption).foregroundStyle(i.type.tint)
                                }
                                .accessibilityHidden(true)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(i.type.title).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                                    Text(i.note.isEmpty ? Format.relativeDay(i.date) : "\(i.note)")
                                        .font(.caption).foregroundStyle(Brand.text3).lineLimit(2)
                                }
                                Spacer()
                                Text(Format.relativeDay(i.date)).font(.caption2).foregroundStyle(Brand.text3)
                            }
                            .padding(.vertical, 2)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var notesCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                if !person.howWeMet.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Eyebrow(text: "How we met")
                        Text(person.howWeMet).font(.subheadline).foregroundStyle(Brand.text2)
                    }
                }
                if !person.notes.isEmpty {
                    if !person.howWeMet.isEmpty { Divider().overlay(Brand.hairline) }
                    VStack(alignment: .leading, spacing: 4) {
                        Eyebrow(text: "Notes")
                        Text(person.notes).font(.subheadline).foregroundStyle(Brand.text2)
                    }
                }
            }
        }
    }
}

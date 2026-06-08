import SwiftUI
import SwiftData

struct ItineraryView: View {
    @Bindable var trip: Trip
    @Environment(\.modelContext) private var context
    @State private var editingActivity: Activity?

    private let engine = TripEngine()
    private let calendar = Calendar.current

    var body: some View {
        ZStack {
            Brand.pageBackground
            if trip.activities.isEmpty {
                EmptyStateView(
                    icon: "calendar.badge.plus",
                    title: "Nothing planned yet",
                    message: "Add flights, sights, meals, and activities. They'll line up by day and time automatically."
                )
                .safeAreaInset(edge: .bottom) { addBar }
            } else {
                ScrollView {
                    VStack(spacing: 18) {
                        ForEach(engine.days(trip), id: \.self) { day in
                            daySection(day)
                        }
                    }
                    .padding()
                }
                .safeAreaInset(edge: .bottom) { addBar }
            }
        }
        .navigationTitle("Itinerary")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingActivity) { act in
            ActivityEditorView(activity: act, trip: trip)
        }
    }

    private var addBar: some View {
        Button {
            Haptics.tap()
            editingActivity = newActivity(on: defaultDay)
        } label: {
            Label("Add plan", systemImage: "plus")
        }
        .buttonStyle(InkButtonStyle())
        .padding()
        .background(.ultraThinMaterial)
    }

    private var defaultDay: Date {
        let today = calendar.startOfDay(for: .now)
        let days = engine.days(trip)
        return days.first(where: { calendar.isDate($0, inSameDayAs: today) }) ?? days.first ?? trip.startDate
    }

    private func daySection(_ day: Date) -> some View {
        let acts = engine.activities(trip, on: day)
        let dayNum = (calendar.dateComponents([.day], from: calendar.startOfDay(for: trip.startDate), to: day).day ?? 0) + 1
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Day \(dayNum)")
                        .font(.headline).foregroundStyle(Brand.text)
                    Text(Format.dayFull.string(from: day))
                        .font(.caption).foregroundStyle(Brand.text3)
                }
                Spacer()
                Button {
                    Haptics.tap()
                    editingActivity = newActivity(on: day)
                } label: {
                    Image(systemName: "plus.circle.fill").foregroundStyle(Color.accentColor)
                }
                .accessibilityLabel("Add plan on day \(dayNum)")
            }
            if acts.isEmpty {
                Text("No plans this day").font(.subheadline).foregroundStyle(Brand.text3)
                    .padding(.vertical, 6)
            } else {
                ForEach(acts) { act in
                    activityRow(act)
                }
            }
        }
        .glassCard()
    }

    private func activityRow(_ act: Activity) -> some View {
        Button { editingActivity = act } label: {
            HStack(alignment: .top, spacing: 12) {
                VStack(spacing: 2) {
                    if act.hasTime {
                        Text(act.startTime, format: .dateTime.hour().minute())
                            .font(Brand.mono(12, weight: .medium))
                            .foregroundStyle(Brand.text2)
                    } else {
                        Text("–").font(Brand.mono(12)).foregroundStyle(Brand.text3)
                    }
                }
                .frame(width: 52, alignment: .leading)

                Image(systemName: act.category.symbol)
                    .font(.subheadline)
                    .foregroundStyle(Color(hex: act.category.colorHex))
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 3) {
                    Text(act.title.isEmpty ? "Untitled" : act.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Brand.text)
                    if !act.location.isEmpty {
                        Text(act.location).font(.caption).foregroundStyle(Brand.text3)
                    }
                    HStack(spacing: 8) {
                        if act.cost > 0 {
                            Text(Money.string(act.cost, code: trip.currencyCode))
                                .font(Brand.mono(11)).foregroundStyle(Brand.text2)
                        }
                        if act.booked {
                            Label("Booked", systemImage: "checkmark.seal.fill")
                                .font(.caption2).foregroundStyle(Brand.live)
                        }
                    }
                }
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .swipeActions {
            Button(role: .destructive) {
                context.delete(act); Haptics.warning()
            } label: { Label("Delete", systemImage: "trash") }
        }
        .accessibilityLabel(accessLabel(act))
    }

    private func accessLabel(_ act: Activity) -> String {
        var parts = [act.title]
        if act.hasTime { parts.append(Format.shortTime.string(from: act.startTime)) }
        parts.append(act.category.label)
        if act.booked { parts.append("booked") }
        return parts.joined(separator: ", ")
    }

    private func newActivity(on day: Date) -> Activity {
        let when = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: day) ?? day
        let act = Activity(title: "", startTime: when, trip: trip)
        context.insert(act)
        return act
    }
}

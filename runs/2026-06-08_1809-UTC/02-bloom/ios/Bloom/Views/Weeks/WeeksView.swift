import SwiftUI

struct WeeksView: View {
    let pregnancy: Pregnancy

    private var currentWeek: Int {
        PregnancyEngine.age(dueDate: pregnancy.dueDate).displayWeek
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(WeekCatalog.all) { info in
                        NavigationLink {
                            WeekDetailView(week: info.week, pregnancy: pregnancy)
                        } label: {
                            WeekRow(info: info,
                                    isCurrent: info.week == currentWeek,
                                    isPast: info.week < currentWeek)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .background(Brand.pageBackground)
            .navigationTitle("Weekly Guide")
        }
    }
}

private struct WeekRow: View {
    let info: WeekInfo
    let isCurrent: Bool
    let isPast: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(isCurrent ? Color(hex: 0x9A6FB0) : Color(hex: 0x9A6FB0).opacity(0.14))
                    .frame(width: 46, height: 46)
                Text("\(info.week)")
                    .font(.headline)
                    .foregroundStyle(isCurrent ? .white : Color(hex: 0x9A6FB0))
            }
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("Week \(info.week)").font(.headline).foregroundStyle(Brand.text)
                    if isCurrent {
                        Text("NOW").font(Brand.mono(9, weight: .bold))
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Brand.live, in: Capsule())
                            .foregroundStyle(.white)
                    }
                }
                Text(info.fruit).font(.subheadline).foregroundStyle(Brand.text2)
            }
            Spacer()
            Image(systemName: isPast ? "checkmark.circle.fill" : "chevron.right")
                .foregroundStyle(isPast ? Brand.live : Brand.text3)
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(isCurrent ? Color(hex: 0x9A6FB0).opacity(0.6) : Brand.glassStroke.opacity(0.5),
                              lineWidth: isCurrent ? 1.5 : 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Week \(info.week), \(info.fruit)\(isCurrent ? ", current week" : "")")
    }
}

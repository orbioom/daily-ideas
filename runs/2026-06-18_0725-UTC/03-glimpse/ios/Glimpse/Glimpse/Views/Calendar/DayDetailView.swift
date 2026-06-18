import SwiftUI
import SwiftData

/// Shows all moments logged for a single day (reached from the calendar).
struct DayDetailView: View {
    let dayKey: String

    @Query private var moments: [Moment]

    init(dayKey: String) {
        self.dayKey = dayKey
        _moments = Query(
            filter: #Predicate<Moment> { $0.dayKey == dayKey },
            sort: \Moment.createdAt,
            order: .reverse
        )
    }

    private static let titleFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, d MMMM yyyy"
        return f
    }()

    private var navTitle: String {
        if let date = DayKey.date(from: dayKey) {
            return Self.titleFormatter.string(from: date)
        }
        return "Day"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if moments.isEmpty {
                    EmptyStateView(
                        symbol: "calendar.badge.exclamationmark",
                        title: "Nothing here yet",
                        message: "There's no moment recorded for this day."
                    )
                    .padding(.top, 40)
                } else {
                    ForEach(moments) { moment in
                        NavigationLink {
                            MomentDetailView(moment: moment)
                        } label: {
                            MomentCard(moment: moment)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(navTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}

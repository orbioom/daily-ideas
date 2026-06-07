import SwiftUI
import SwiftData

struct TableDetailView: View {
    @Bindable var table: ApneaTable
    @State private var startSession = false

    private var schedule: [ApneaRound] { table.schedule }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    StatTile(value: "\(table.rounds)", label: "Rounds")
                    StatTile(value: TableEngine.clock(table.longestHold), label: "Longest hold", accent: Brand.text)
                    StatTile(value: TableEngine.clock(table.totalSeconds), label: "Total")
                }

                VStack(alignment: .leading, spacing: 8) {
                    Label(table.type.rawValue + " table", systemImage: table.type.symbol)
                        .font(.headline).foregroundStyle(Brand.text)
                    Text(table.type.subtitle).font(.subheadline).foregroundStyle(Brand.text2)
                }.frame(maxWidth: .infinity, alignment: .leading).glassCard()

                VStack(alignment: .leading, spacing: 0) {
                    SectionTitle(text: "Schedule").padding(.bottom, 8)
                    ForEach(schedule) { r in
                        HStack {
                            Text("\(r.index)").font(Brand.mono(15, weight: .semibold))
                                .foregroundStyle(Brand.text).frame(width: 26, alignment: .leading)
                            Label(TableEngine.clock(r.holdSeconds), systemImage: "lungs.fill")
                                .font(Brand.mono(14)).foregroundStyle(Brand.text)
                            Spacer()
                            if r.restSeconds > 0 {
                                Label("rest " + TableEngine.clock(r.restSeconds), systemImage: "wind")
                                    .font(Brand.mono(13)).foregroundStyle(Brand.text3)
                            } else {
                                Text("final hold").font(.caption).foregroundStyle(Brand.live)
                            }
                        }
                        .padding(.vertical, 8)
                        if r.id != schedule.last?.id { Divider().overlay(Brand.hairline) }
                    }
                }.glassCard()

                Button { startSession = true } label: {
                    Label("Start session", systemImage: "play.fill").frame(maxWidth: .infinity)
                }.buttonStyle(InkButtonStyle())
            }
            .padding()
        }
        .navigationTitle(table.name)
        .navigationBarTitleDisplayMode(.inline)
        .background(Brand.pageBackground)
        .navigationDestination(isPresented: $startSession) {
            SessionView(table: table)
        }
    }
}

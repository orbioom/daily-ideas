import SwiftUI
import SwiftData

struct RoutinesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Routine.createdAt) private var routines: [Routine]
    @State private var showingBuilder = false

    private var sorted: [Routine] {
        routines.sorted {
            if $0.isFavorite != $1.isFavorite { return $0.isFavorite && !$1.isFavorite }
            return $0.createdAt < $1.createdAt
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if routines.isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "list.bullet.rectangle.portrait",
                                       title: "No routines",
                                       message: "Create your first routine, or restore the built-ins by reinstalling.")
                            .glassCard()
                            .padding(20)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 14) {
                            ForEach(sorted) { routine in
                                NavigationLink {
                                    RoutineDetailView(routine: routine)
                                } label: {
                                    RoutineRow(routine: routine)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle("Routines")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap()
                        showingBuilder = true
                    } label: { Image(systemName: "plus") }
                        .accessibilityLabel("New routine")
                }
            }
            .sheet(isPresented: $showingBuilder) {
                RoutineBuilderView(routine: nil)
            }
        }
    }
}

struct RoutineRow: View {
    let routine: Routine
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(routine.name)
                    .font(.headline)
                    .foregroundStyle(Brand.text)
                if routine.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(Brand.warn)
                        .accessibilityLabel("Favorite")
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Brand.text3)
                    .accessibilityHidden(true)
            }
            if !routine.summary.isEmpty {
                Text(routine.summary)
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
                    .lineLimit(2)
            }
            HStack(spacing: 16) {
                Label(MobilityEngine.secondsString(routine.totalSeconds), systemImage: "clock")
                Label("\(routine.stretchCount)", systemImage: "figure.flexibility")
                if routine.isBuiltIn {
                    Text("Built-in").font(.caption2).foregroundStyle(Brand.text3)
                }
            }
            .font(.footnote)
            .foregroundStyle(Brand.text3)
        }
        .glassCard()
        .accessibilityElement(children: .combine)
    }
}

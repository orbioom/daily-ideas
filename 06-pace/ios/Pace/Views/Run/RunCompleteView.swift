import SwiftUI
import MapKit

struct RunCompleteView: View {
    let session: RunSession
    @AppStorage("pace_use_km") private var useKm = true
    @Environment(\.modelContext) private var modelContext
    @Environment(RunEngine.self) private var engine

    @State private var starRating = 0
    @State private var notes = ""
    @State private var showShareSheet = false
    @State private var shareText = ""
    @State private var dismiss = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: session.activityType.systemImage)
                            .font(.system(size: 60))
                            .foregroundStyle(PaceTheme.accent)

                        Text("\(session.activityType.rawValue) Complete!")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text(session.date, style: .time)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)

                    // Key metrics
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        MetricCard(
                            title: useKm ? "Distance" : "Distance",
                            value: session.distanceFormatted(useKm: useKm),
                            icon: "ruler.fill",
                            color: PaceTheme.accent
                        )
                        MetricCard(
                            title: "Time",
                            value: session.durationFormatted,
                            icon: "clock.fill",
                            color: .blue
                        )
                        MetricCard(
                            title: "Avg Pace",
                            value: "\(session.paceFormatted(useKm: useKm))/\(useKm ? "km" : "mi")",
                            icon: "speedometer",
                            color: .orange
                        )
                        MetricCard(
                            title: "Elevation",
                            value: String(format: "+%.0f m", session.elevationGainMeters),
                            icon: "arrow.up.right",
                            color: .purple
                        )
                        MetricCard(
                            title: "Calories",
                            value: String(format: "%.0f kcal", session.calories),
                            icon: "flame.fill",
                            color: .red
                        )
                        MetricCard(
                            title: "Max Speed",
                            value: String(format: "%.1f km/h", session.maxSpeedMps * 3.6),
                            icon: "bolt.fill",
                            color: .yellow
                        )
                    }
                    .padding(.horizontal)

                    // Mini map
                    if session.points.count > 1 {
                        RouteMapView(points: session.points)
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal)
                    }

                    // Rating
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How did it feel?")
                            .font(.headline)

                        HStack(spacing: 12) {
                            ForEach(1...5, id: \.self) { star in
                                Button(action: { starRating = star }) {
                                    Image(systemName: star <= starRating ? "star.fill" : "star")
                                        .font(.title)
                                        .foregroundStyle(star <= starRating ? .yellow : .gray)
                                }
                                .accessibilityLabel("\(star) star\(star == 1 ? "" : "s")")
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.headline)
                        TextField("How did the run go?", text: $notes, axis: .vertical)
                            .lineLimit(3...6)
                            .padding()
                            .background(PaceTheme.surface, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)

                    // Action buttons
                    VStack(spacing: 12) {
                        Button(action: saveAndDismiss) {
                            Text("Save \(session.activityType.rawValue)")
                                .font(.headline)
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(PaceTheme.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        Button(action: { prepareShare() }) {
                            Label("Share", systemImage: "square.and.arrow.up")
                                .font(.headline)
                                .foregroundStyle(PaceTheme.accent)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(PaceTheme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: [shareText])
            }
            .fullScreenCover(isPresented: $dismiss) {
                ContentView()
            }
        }
    }

    private func saveAndDismiss() {
        session.notes = notes
        if starRating > 0 {
            session.notes = "Rating: \(starRating)/5\(notes.isEmpty ? "" : "\n\(notes)")"
        }
        try? modelContext.save()
        engine.resetToReady()
        dismiss = true
    }

    private func prepareShare() {
        shareText = """
        Just finished a \(session.activityType.rawValue.lowercased()) with Pace! 🏃

        Distance: \(session.distanceFormatted(useKm: useKm))
        Time: \(session.durationFormatted)
        Pace: \(session.paceFormatted(useKm: useKm))/\(useKm ? "km" : "mi")
        Elevation: +\(String(format: "%.0f", session.elevationGainMeters))m

        Tracked with Pace — privacy-first GPS tracker
        """
        showShareSheet = true
    }
}

private struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(PaceTheme.surface, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct RouteMapView: View {
    let points: [RoutePoint]

    private var coordinates: [CLLocationCoordinate2D] {
        points.sorted { $0.timestamp < $1.timestamp }.map { $0.coordinate }
    }

    private var region: MapCameraPosition {
        guard !coordinates.isEmpty else {
            return .automatic
        }
        if coordinates.count == 1 {
            return .camera(MapCamera(centerCoordinate: coordinates[0], distance: 500))
        }
        let minLat = coordinates.map { $0.latitude }.min() ?? 0
        let maxLat = coordinates.map { $0.latitude }.max() ?? 0
        let minLon = coordinates.map { $0.longitude }.min() ?? 0
        let maxLon = coordinates.map { $0.longitude }.max() ?? 0
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.4, 0.002),
            longitudeDelta: max((maxLon - minLon) * 1.4, 0.002)
        )
        return .region(MKCoordinateRegion(center: center, span: span))
    }

    var body: some View {
        Map(position: .constant(region)) {
            if coordinates.count > 1 {
                MapPolyline(coordinates: coordinates)
                    .stroke(PaceTheme.accent, lineWidth: 3)
            }
            if let first = coordinates.first {
                Annotation("Start", coordinate: first) {
                    Circle()
                        .fill(.green)
                        .frame(width: 10, height: 10)
                }
            }
            if let last = coordinates.last, coordinates.count > 1 {
                Annotation("End", coordinate: last) {
                    Circle()
                        .fill(.red)
                        .frame(width: 10, height: 10)
                }
            }
        }
        .mapStyle(.standard)
        .disabled(true)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uvc: UIActivityViewController, context: Context) {}
}

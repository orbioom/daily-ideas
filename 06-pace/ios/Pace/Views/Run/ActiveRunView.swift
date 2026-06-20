import SwiftUI
import MapKit

struct ActiveRunView: View {
    @Environment(RunEngine.self) private var engine
    @Environment(\.modelContext) private var modelContext
    @AppStorage("pace_use_km") private var useKm = true

    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var polylineCoords: [CLLocationCoordinate2D] = []
    @State private var showFinishConfirm = false
    @State private var completedSession: RunSession? = nil
    @State private var showComplete = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // Map with route polyline
            Map(position: $cameraPosition) {
                UserAnnotation()
                if polylineCoords.count > 1 {
                    MapPolyline(coordinates: polylineCoords)
                        .stroke(PaceTheme.accent, lineWidth: 4)
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
            .ignoresSafeArea()

            // Metrics overlay
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 20) {
                    // Top metrics row
                    HStack(spacing: 0) {
                        RunMetricTile(
                            label: "TIME",
                            value: engine.elapsedFormatted,
                            icon: "clock.fill"
                        )
                        .frame(maxWidth: .infinity)

                        Divider()
                            .frame(height: 60)

                        RunMetricTile(
                            label: useKm ? "KM" : "MILES",
                            value: useKm
                                ? String(format: "%.2f", engine.distanceMeters / 1000)
                                : String(format: "%.2f", engine.distanceMeters / 1609.344),
                            icon: "ruler.fill"
                        )
                        .frame(maxWidth: .infinity)
                    }

                    // Bottom metrics row
                    HStack(spacing: 0) {
                        RunMetricTile(
                            label: "PACE /\(useKm ? "KM" : "MI")",
                            value: engine.paceFormatted,
                            icon: "speedometer"
                        )
                        .frame(maxWidth: .infinity)

                        Divider()
                            .frame(height: 60)

                        RunMetricTile(
                            label: "ELEVATION",
                            value: String(format: "+%.0f m", engine.elevationGainMeters),
                            icon: "arrow.up.right"
                        )
                        .frame(maxWidth: .infinity)
                    }

                    Divider()

                    // Controls
                    HStack(spacing: 40) {
                        if engine.state == .running {
                            Button(action: { engine.pauseRun() }) {
                                VStack(spacing: 4) {
                                    Image(systemName: "pause.circle.fill")
                                        .font(.system(size: 60))
                                        .foregroundStyle(PaceTheme.accent)
                                    Text("Pause")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .accessibilityLabel("Pause run")
                        } else if engine.state == .paused {
                            Button(action: { engine.resumeRun() }) {
                                VStack(spacing: 4) {
                                    Image(systemName: "play.circle.fill")
                                        .font(.system(size: 60))
                                        .foregroundStyle(PaceTheme.accent)
                                    Text("Resume")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .accessibilityLabel("Resume run")
                        }

                        Button(action: { showFinishConfirm = true }) {
                            VStack(spacing: 4) {
                                Image(systemName: "stop.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundStyle(.red)
                                Text("Finish")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .accessibilityLabel("Finish run")
                    }
                    .padding(.bottom, 8)
                }
                .padding(20)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle(engine.activityType.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { showFinishConfirm = true }) {
                    Text("End")
                        .foregroundStyle(.red)
                }
            }
        }
        .onChange(of: engine.route) { _, newRoute in
            polylineCoords = newRoute.map { $0.coordinate }
            if let last = newRoute.last {
                withAnimation(.easeInOut(duration: 0.5)) {
                    cameraPosition = .camera(MapCamera(
                        centerCoordinate: last.coordinate,
                        distance: 500,
                        heading: last.course >= 0 ? last.course : 0,
                        pitch: 45
                    ))
                }
            }
        }
        .alert("Finish \(engine.activityType.rawValue)?", isPresented: $showFinishConfirm) {
            Button("Finish", role: .destructive) { finishRun() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will save your \(engine.activityType.rawValue.lowercased()) and return to the home screen.")
        }
        .fullScreenCover(isPresented: $showComplete) {
            if let session = completedSession {
                RunCompleteView(session: session)
            }
        }
        .onAppear {
            if engine.state == .ready {
                engine.startRun()
            }
        }
    }

    private func finishRun() {
        if let session = engine.finishRun() {
            modelContext.insert(session)
            try? modelContext.save()
            completedSession = session
            showComplete = true
        }
    }
}

import SwiftUI

struct PreRunView: View {
    @Environment(RunEngine.self) private var engine
    @State private var showActiveRun = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                // Activity type picker
                VStack(alignment: .leading, spacing: 12) {
                    Text("Activity")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    @Bindable var bindableEngine = engine
                    HStack(spacing: 12) {
                        ForEach(ActivityType.allCases, id: \.self) { type in
                            ActivityTypeButton(
                                type: type,
                                isSelected: engine.activityType == type,
                                action: { bindableEngine.activityType = type }
                            )
                        }
                    }
                }
                .padding(.horizontal)

                // Location status
                VStack(spacing: 16) {
                    switch engine.state {
                    case .idle, .requestingPermission:
                        LocationPermissionCard(engine: engine)

                    case .ready, .running, .paused, .finished:
                        GPSReadyCard(engine: engine)
                    }

                    if let error = engine.locationError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                .padding(.horizontal)

                Spacer()

                // Start button
                NavigationLink(destination: ActiveRunView(), isActive: $showActiveRun) {
                    EmptyView()
                }

                Button(action: {
                    if engine.state == .ready {
                        showActiveRun = true
                    } else if engine.state == .idle {
                        engine.requestPermission()
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: startButtonIcon)
                            .font(.title2)
                        Text(startButtonLabel)
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(startButtonEnabled ? PaceTheme.accent : Color.gray.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                .disabled(!startButtonEnabled)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .navigationTitle("New Activity")
            .onChange(of: engine.state) { _, newState in
                if newState == .ready && showActiveRun == false {
                    // ready to show start button
                }
            }
        }
    }

    private var startButtonEnabled: Bool {
        engine.state == .ready
    }

    private var startButtonLabel: String {
        switch engine.state {
        case .idle: return "Enable Location"
        case .requestingPermission: return "Requesting..."
        case .ready: return "Start \(engine.activityType.rawValue)"
        case .running: return "Running..."
        case .paused: return "Paused"
        case .finished: return "Start \(engine.activityType.rawValue)"
        }
    }

    private var startButtonIcon: String {
        switch engine.state {
        case .idle: return "location.fill"
        case .requestingPermission: return "location.fill"
        default: return "play.fill"
        }
    }
}

private struct ActivityTypeButton: View {
    let type: ActivityType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: type.systemImage)
                    .font(.title2)
                Text(type.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundStyle(isSelected ? .black : PaceTheme.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isSelected ? PaceTheme.accent : PaceTheme.surface
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? PaceTheme.accent : Color.clear, lineWidth: 2)
            )
        }
        .accessibilityLabel("\(type.rawValue) activity type")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct LocationPermissionCard: View {
    let engine: RunEngine

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "location.slash.fill")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            Text("Location Required")
                .font(.headline)
            Text("Pace needs location access to track your route and measure distance.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(PaceTheme.surface, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct GPSReadyCard: View {
    let engine: RunEngine

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.green)
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(Color.green.opacity(0.3), lineWidth: 4)
                )
            Text("GPS Ready")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.green)
            Spacer()
            Text("High Accuracy")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(PaceTheme.surface, in: RoundedRectangle(cornerRadius: 16))
    }
}

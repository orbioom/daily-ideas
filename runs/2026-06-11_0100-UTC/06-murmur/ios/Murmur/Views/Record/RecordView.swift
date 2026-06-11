import SwiftUI
import SwiftData

struct RecordView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var vm = RecorderViewModel()
    @State private var permissionDenied = false
    @State private var showingEntry: VoiceEntry?
    @State private var showPermissionAlert = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()
                waveformView
                    .padding(.horizontal)
                    .padding(.bottom, 32)

                timerLabel

                if vm.state == .processing {
                    processingView
                } else if vm.state == .done {
                    doneView
                } else {
                    controlsView
                }

                Spacer()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Record")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Microphone Access Required", isPresented: $showPermissionAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Murmur needs microphone and speech recognition access to record voice notes.")
            }
            .sheet(item: $showingEntry) { entry in
                EntryDetailView(entry: entry)
            }
            .onAppear { vm.onEntrySaved = { showingEntry = $0 } }
        }
    }

    private var waveformView: some View {
        GeometryReader { geo in
            HStack(alignment: .center, spacing: 3) {
                ForEach(Array(vm.waveformSamples.enumerated()), id: \.offset) { _, sample in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(vm.state == .recording ? MurmurTheme.waveformActive : MurmurTheme.waveformIdle)
                        .frame(width: max(2, (geo.size.width - 3 * 60) / 60),
                               height: max(4, sample * geo.size.height * 0.9))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .frame(height: 80)
    }

    private var timerLabel: some View {
        Text(vm.elapsedFormatted)
            .font(.system(size: 56, weight: .thin, design: .monospaced))
            .foregroundStyle(vm.state == .recording ? MurmurTheme.accent : .secondary)
            .padding(.bottom, 32)
    }

    private var controlsView: some View {
        VStack(spacing: 24) {
            HStack(spacing: 48) {
                if vm.state == .paused {
                    Button(role: .destructive) { vm.discardRecording() } label: {
                        Image(systemName: "trash")
                            .font(.title2)
                            .frame(width: 56, height: 56)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(Circle())
                    }
                    .foregroundStyle(.red)
                } else {
                    Spacer().frame(width: 56, height: 56)
                }

                recordButton

                if vm.state == .paused {
                    Button { vm.stopAndProcess(modelContext: modelContext) } label: {
                        Image(systemName: "checkmark")
                            .font(.title2)
                            .frame(width: 56, height: 56)
                            .background(MurmurTheme.accent.opacity(0.15))
                            .clipShape(Circle())
                    }
                    .foregroundStyle(MurmurTheme.accent)
                } else {
                    Spacer().frame(width: 56, height: 56)
                }
            }

            Text(stateHint)
                .font(MurmurTheme.captionFont)
                .foregroundStyle(.secondary)
        }
    }

    private var recordButton: some View {
        Button {
            Task { await handleRecordTap() }
        } label: {
            ZStack {
                Circle()
                    .fill(MurmurTheme.recordRed.opacity(vm.state == .recording ? 1.0 : 0.15))
                    .frame(width: 80, height: 80)
                if vm.state == .recording {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.white)
                        .frame(width: 28, height: 28)
                } else {
                    Circle()
                        .fill(MurmurTheme.recordRed)
                        .frame(width: 56, height: 56)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(vm.state == .recording ? "Pause recording" : "Start recording")
    }

    private var processingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Transcribing…")
                .font(MurmurTheme.captionFont)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 32)
    }

    private var doneView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(MurmurTheme.accent)
            Text("Entry saved")
                .font(.headline)
            Button("Record Another") {
                vm = RecorderViewModel()
                vm.onEntrySaved = { showingEntry = $0 }
            }
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundStyle(MurmurTheme.accent)
        }
    }

    private var stateHint: String {
        switch vm.state {
        case .idle:    return "Tap to start recording"
        case .recording: return "Tap to pause"
        case .paused:  return "Tap to resume · Checkmark to save"
        default: return ""
        }
    }

    private func handleRecordTap() async {
        if vm.state == .idle {
            let ok = await vm.requestPermissions()
            if ok { vm.startRecording() } else { showPermissionAlert = true }
        } else if vm.state == .recording {
            vm.pauseRecording()
        } else if vm.state == .paused {
            vm.startRecording()
        }
    }
}

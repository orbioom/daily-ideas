import SwiftUI
import SwiftData
import AVFoundation
import PhotosUI

struct ScanView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("keepScanHistory") private var keepScanHistory = true

    @State private var cameraStatus: AVAuthorizationStatus = .notDetermined
    @State private var photoItem: PhotosPickerItem?
    @State private var isScanningPhoto = false
    @State private var photoError: String?
    @State private var result: ScanResult?

    struct ScanResult: Identifiable {
        let id = UUID()
        let payload: String
        let kind: PayloadKind
        let fromCamera: Bool
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                cameraArea
                controls
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Scan")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { refreshCameraStatus() }
            .onChange(of: photoItem) { _, item in
                guard let item else { return }
                Task { await scanPhoto(item) }
            }
            .sheet(item: $result) { result in
                ScanResultSheet(result: result)
                    .presentationDetents([.medium])
            }
            .alert("Couldn't Scan That Image", isPresented: .init(
                get: { photoError != nil },
                set: { if !$0 { photoError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(photoError ?? "")
            }
        }
    }

    // MARK: - Camera area

    @ViewBuilder
    private var cameraArea: some View {
        ZStack {
            switch cameraStatus {
            case .authorized:
                CameraScannerView { payload in
                    handle(payload: payload, fromCamera: true)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(GlyphTheme.mint.opacity(0.9), lineWidth: 3)
                        .frame(width: 230, height: 230)
                        .accessibilityHidden(true)
                }
                .overlay(alignment: .bottom) {
                    Text("Point at a QR code")
                        .font(.footnote.weight(.medium))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.thinMaterial, in: Capsule())
                        .padding(.bottom, 16)
                }
            case .notDetermined:
                placeholder(
                    icon: "viewfinder",
                    title: "Camera Scanning",
                    message: "Glyph reads QR codes with the camera, entirely on this device. Frames are never stored or uploaded.",
                    buttonTitle: "Enable Camera"
                ) {
                    AVCaptureDevice.requestAccess(for: .video) { _ in
                        DispatchQueue.main.async { refreshCameraStatus() }
                    }
                }
            default:
                placeholder(
                    icon: "video.slash",
                    title: "Camera Access Is Off",
                    message: "Allow camera access for Glyph in the Settings app, or scan a QR code from a photo below — that works without the camera.",
                    buttonTitle: nil,
                    action: nil
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 0))
    }

    private func placeholder(
        icon: String,
        title: String,
        message: String,
        buttonTitle: String?,
        action: (() -> Void)? = nil
    ) -> some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundStyle(GlyphTheme.mint)
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            if let buttonTitle, let action {
                Button(buttonTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .tint(GlyphTheme.mint)
                    .foregroundStyle(.black)
            }
        }
    }

    private func refreshCameraStatus() {
        cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(spacing: 10) {
            PhotosPicker(selection: $photoItem, matching: .images) {
                HStack {
                    if isScanningPhoto {
                        ProgressView()
                            .padding(.trailing, 4)
                    }
                    Label(isScanningPhoto ? "Reading photo…" : "Scan from Photo", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.bordered)
            .disabled(isScanningPhoto)
            .accessibilityHint("Pick an image from your photo library and Glyph will find the QR code in it")

            Text("Photo scanning works everywhere — including the simulator.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
    }

    // MARK: - Handling

    private func handle(payload: String, fromCamera: Bool) {
        Haptics.success()
        let kind = PayloadClassifier.classify(payload)
        if keepScanHistory {
            modelContext.insert(ScanRecord(payload: payload, detectedKind: kind, fromCamera: fromCamera))
        }
        result = ScanResult(payload: payload, kind: kind, fromCamera: fromCamera)
    }

    @MainActor
    private func scanPhoto(_ item: PhotosPickerItem) async {
        isScanningPhoto = true
        defer {
            isScanningPhoto = false
            photoItem = nil
        }
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                photoError = "That image couldn't be loaded."
                return
            }
            let payload = try await PhotoScanner.scan(imageData: data)
            handle(payload: payload, fromCamera: false)
        } catch {
            Haptics.error()
            photoError = error.localizedDescription
        }
    }
}

// MARK: - Result sheet

struct ScanResultSheet: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss
    let result: ScanView.ScanResult

    @State private var copied = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Label(result.kind.displayName, systemImage: result.kind.symbol)
                    .font(.headline)
                    .foregroundStyle(GlyphTheme.mint)

                ScrollView {
                    Text(result.payload)
                        .font(.callout.monospaced())
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 160)
                .glyphPanel()

                HStack(spacing: 10) {
                    Button {
                        UIPasteboard.general.string = result.payload
                        Haptics.tap()
                        copied = true
                    } label: {
                        Label(copied ? "Copied" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    if let url = actionURL {
                        Button {
                            openURL(url)
                            dismiss()
                        } label: {
                            Label(actionTitle, systemImage: "arrow.up.right.square")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(GlyphTheme.mint)
                        .foregroundStyle(.black)
                    }
                }
                Spacer()
            }
            .padding()
            .navigationTitle("Scanned")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var actionURL: URL? {
        switch result.kind {
        case .url, .email, .phone:
            return URL(string: result.payload)
        case .sms:
            // SMSTO:number:body → sms:number
            let parts = result.payload.split(separator: ":", maxSplits: 2).map(String.init)
            if parts.count >= 2 {
                return URL(string: "sms:\(parts[1])")
            }
            return nil
        case .wifi, .contact, .text:
            return nil
        }
    }

    private var actionTitle: String {
        switch result.kind {
        case .url: return "Open Link"
        case .email: return "Compose"
        case .phone: return "Call"
        case .sms: return "Message"
        default: return "Open"
        }
    }
}

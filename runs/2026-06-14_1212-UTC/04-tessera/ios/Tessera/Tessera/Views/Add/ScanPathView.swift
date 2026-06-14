import SwiftUI
import UIKit

/// Camera scan path. On a valid otpauth QR, advances to the editor preloaded
/// with the parsed values. Shows calm fallbacks when the camera is denied or
/// unavailable, pointing the user to the other import options.
struct ScanPathView: View {
    @EnvironmentObject private var settings: AppSettings
    let onSaved: () -> Void

    @State private var status: ScannerStatus = .ready
    @State private var parsed: OTPAuthURI?
    @State private var invalidNotice = false
    @State private var goToEditor = false

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            switch status {
            case .ready:
                cameraView
            case .denied:
                fallback(symbol: "video.slash.fill",
                         title: "Camera access is off",
                         message: "Allow camera access in Settings to scan QR codes, or use Paste link / Enter manually instead.")
            case .unavailable:
                fallback(symbol: "camera.metering.unknown",
                         title: "No camera available",
                         message: "This device can't scan QR codes right now. You can still paste a setup link or enter the secret manually.")
            }
        }
        .navigationTitle("Scan QR")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $goToEditor) {
            if let parsed {
                AccountEditorView(prefill: parsed, onSaved: onSaved)
            }
        }
        .alert("That QR isn't a 2FA code", isPresented: $invalidNotice) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Tessera only reads otpauth:// setup codes. Try another QR or use a different method.")
        }
    }

    private var cameraView: some View {
        ZStack {
            QRScannerView(onFound: handleFound, onStatus: { status = $0 })
                .ignoresSafeArea(edges: .bottom)
            // Reticle overlay.
            VStack {
                Spacer()
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.9), lineWidth: 3)
                    .frame(width: 230, height: 230)
                    .accessibilityHidden(true)
                Spacer()
                Text("Center the QR code in the frame")
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(.black.opacity(0.5)))
                    .padding(.bottom, 40)
            }
        }
    }

    private func handleFound(_ value: String) {
        guard !goToEditor else { return }
        if let uri = OTPAuthURI.parse(value) {
            Haptics.success(settings.hapticsEnabled)
            parsed = uri
            goToEditor = true
        } else {
            Haptics.error(settings.hapticsEnabled)
            invalidNotice = true
        }
    }

    private func fallback(symbol: String, title: String, message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: symbol)
                .font(.system(size: 52))
                .foregroundStyle(Theme.accent.opacity(0.8))
                .accessibilityHidden(true)
            Text(title)
                .font(Theme.rounded(22, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(message)
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 32)
            if status == .denied {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Open Settings")
                        .font(Theme.rounded(15, .semibold))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Theme.accent))
                        .foregroundStyle(.white)
                }
                .padding(.top, 4)
            }
            Spacer()
        }
        .padding(24)
    }
}

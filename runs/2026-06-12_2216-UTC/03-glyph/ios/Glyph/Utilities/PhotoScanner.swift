import Foundation
import Vision
import UIKit

/// Detects QR codes in an imported image via the Vision framework.
/// Works in the simulator (no camera needed) and fully offline.
enum PhotoScanner {
    enum ScanError: LocalizedError {
        case unreadableImage
        case noCodeFound

        var errorDescription: String? {
            switch self {
            case .unreadableImage: return "That image couldn't be read."
            case .noCodeFound: return "No QR code was found in that image."
            }
        }
    }

    static func scan(imageData: Data) async throws -> String {
        guard let image = UIImage(data: imageData), let cgImage = image.cgImage else {
            throw ScanError.unreadableImage
        }
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectBarcodesRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let payload = (request.results as? [VNBarcodeObservation])?
                    .first { $0.symbology == .qr }?
                    .payloadStringValue
                if let payload, !payload.isEmpty {
                    continuation.resume(returning: payload)
                } else {
                    continuation.resume(throwing: ScanError.noCodeFound)
                }
            }
            request.symbologies = [.qr]
            let handler = VNImageRequestHandler(cgImage: cgImage)
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

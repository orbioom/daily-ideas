import UIKit

/// Saves a UIImage to the user's photo library and reports success/failure via a completion.
/// Wraps the Objective-C target/action callback of `UIImageWriteToSavedPhotosAlbum`.
final class PhotoSaver: NSObject {
    private var completion: ((Result<Void, Error>) -> Void)?
    // Strong self-reference kept alive until the async callback fires.
    private var retain: PhotoSaver?

    func save(_ image: UIImage, completion: @escaping (Result<Void, Error>) -> Void) {
        self.completion = completion
        self.retain = self
        UIImageWriteToSavedPhotosAlbum(
            image,
            self,
            #selector(image(_:didFinishSavingWithError:contextInfo:)),
            nil
        )
    }

    @objc private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        let result: Result<Void, Error>
        if let error {
            result = .failure(error)
        } else {
            result = .success(())
        }
        let handler = completion
        completion = nil
        retain = nil
        DispatchQueue.main.async { handler?(result) }
    }
}

import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

/// Applies photographic filters with Core Image. A single shared context keeps
/// GPU resources warm. Falls back to the original image if anything fails.
enum FilterEngine {
    static let context = CIContext(options: [.useSoftwareRenderer: false])

    static func apply(_ filter: PhotoFilter, to image: UIImage) -> UIImage {
        guard filter != .none, let input = CIImage(image: image) else { return image }

        let output: CIImage?
        switch filter {
        case .none:
            output = input
        case .mono:
            let f = CIFilter.photoEffectMono(); f.inputImage = input; output = f.outputImage
        case .noir:
            let f = CIFilter.photoEffectNoir(); f.inputImage = input; output = f.outputImage
        case .sepia:
            let f = CIFilter.sepiaTone(); f.inputImage = input; f.intensity = 0.9; output = f.outputImage
        case .vivid:
            let f = CIFilter.colorControls()
            f.inputImage = input; f.saturation = 1.5; f.contrast = 1.1; f.brightness = 0.02
            output = f.outputImage
        case .cool:
            let f = CIFilter.temperatureAndTint()
            f.inputImage = input
            f.neutral = CIVector(x: 6500, y: 0)
            f.targetNeutral = CIVector(x: 5200, y: 0)
            output = f.outputImage
        case .warm:
            let f = CIFilter.temperatureAndTint()
            f.inputImage = input
            f.neutral = CIVector(x: 6500, y: 0)
            f.targetNeutral = CIVector(x: 8200, y: 30)
            output = f.outputImage
        case .fade:
            let f = CIFilter.colorControls()
            f.inputImage = input; f.saturation = 0.75; f.contrast = 0.9; f.brightness = 0.06
            output = f.outputImage
        }

        guard let result = output,
              let cg = context.createCGImage(result, from: input.extent) else { return image }
        return UIImage(cgImage: cg, scale: image.scale, orientation: image.imageOrientation)
    }
}

import UIKit

struct ExtractedColor: Identifiable {
    let id = UUID()
    let r: Double
    let g: Double
    let b: Double
    var name: String = ""

    var hex: String {
        String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }

    var color: SwiftUI.Color {
        SwiftUI.Color(red: r, green: g, blue: b)
    }
}

actor KMeansExtractor {
    func extract(from image: UIImage, k: Int = 6) async -> [ExtractedColor] {
        // 1. Downsample image to 100x100 for speed
        let targetSize = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let small = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }

        guard let cgImage = small.cgImage else { return [] }

        // 2. Sample pixel colors from CGImage
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var rawData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

        guard let context = CGContext(
            data: &rawData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return [] }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var pixels: [(Double, Double, Double)] = []
        pixels.reserveCapacity(width * height)
        for i in 0 ..< width * height {
            let offset = i * bytesPerPixel
            let alpha = Double(rawData[offset + 3]) / 255.0
            guard alpha > 0.1 else { continue }
            let r = Double(rawData[offset]) / (255.0 * alpha)
            let g = Double(rawData[offset + 1]) / (255.0 * alpha)
            let b = Double(rawData[offset + 2]) / (255.0 * alpha)
            pixels.append((min(r, 1), min(g, 1), min(b, 1)))
        }

        guard pixels.count >= k else { return [] }

        // 3. Run K-means for 20 iterations
        var centroids: [(Double, Double, Double)] = []
        var usedIndices = Set<Int>()
        while centroids.count < k {
            let idx = Int.random(in: 0 ..< pixels.count)
            if usedIndices.insert(idx).inserted {
                centroids.append(pixels[idx])
            }
        }

        var assignments = [Int](repeating: 0, count: pixels.count)
        var counts = [Int](repeating: 0, count: k)

        for _ in 0 ..< 20 {
            // Assign pixels to nearest centroid
            for (pi, pixel) in pixels.enumerated() {
                var best = 0
                var bestDist = Double.infinity
                for (ci, centroid) in centroids.enumerated() {
                    let dr = pixel.0 - centroid.0
                    let dg = pixel.1 - centroid.1
                    let db = pixel.2 - centroid.2
                    let dist = dr*dr + dg*dg + db*db
                    if dist < bestDist {
                        bestDist = dist
                        best = ci
                    }
                }
                assignments[pi] = best
            }

            // Recompute centroids as mean of assigned pixels
            var sums = [(Double, Double, Double)](repeating: (0, 0, 0), count: k)
            counts = [Int](repeating: 0, count: k)
            for (pi, pixel) in pixels.enumerated() {
                let ci = assignments[pi]
                sums[ci].0 += pixel.0
                sums[ci].1 += pixel.1
                sums[ci].2 += pixel.2
                counts[ci] += 1
            }
            for ci in 0 ..< k {
                if counts[ci] > 0 {
                    let n = Double(counts[ci])
                    centroids[ci] = (sums[ci].0/n, sums[ci].1/n, sums[ci].2/n)
                }
            }
        }

        // 4. Sort clusters by population (dominant first)
        let indexed = (0 ..< k).sorted { counts[$0] > counts[$1] }

        // 5. Return [ExtractedColor] with hex, rgb, name
        let namer = ColorNamer()
        return indexed.compactMap { ci -> ExtractedColor? in
            guard counts[ci] > 0 else { return nil }
            let c = centroids[ci]
            var ec = ExtractedColor(r: c.0, g: c.1, b: c.2)
            ec.name = namer.name(r: c.0, g: c.1, b: c.2)
            return ec
        }
    }
}

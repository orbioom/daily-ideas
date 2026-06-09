import Foundation
import SwiftData
import UIKit

/// Seeds a rich, realistic history on first launch so Progress charts, the photo
/// timeline, and Compare all demonstrate immediately — no bundled assets needed.
/// Photos are synthesized as on-brand gradient tiles via `UIGraphicsImageRenderer`
/// and saved through `ImageStore`. Guarded so it runs at most once.
enum SeedData {
    static func seedIfNeeded(_ context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<BodyMetric>())) ?? []
        guard existing.isEmpty else { return }

        let cal = Calendar.current
        var rng = SystemRandomNumberGenerator()
        let now = Date()

        // 13 weeks of weekly readings.
        let weeks = 13

        // MARK: Weight series — trending down with noise (canonical kg).
        let startWeight = 84.5
        let weeklyLoss = 0.55
        for w in 0..<weeks {
            guard let date = cal.date(byAdding: .day, value: -((weeks - 1 - w) * 7), to: now) else { continue }
            let noise = Double.random(in: -0.6...0.6, using: &rng)
            let value = startWeight - Double(w) * weeklyLoss + noise
            let m = BodyMetric(date: date, type: .weight, value: max(40, value))
            context.insert(m)
        }

        // MARK: Waist series — cm, slowly shrinking.
        let startWaist = 96.0
        for w in 0..<weeks {
            guard let date = cal.date(byAdding: .day, value: -((weeks - 1 - w) * 7), to: now) else { continue }
            let noise = Double.random(in: -0.4...0.4, using: &rng)
            let value = startWaist - Double(w) * 0.45 + noise
            context.insert(BodyMetric(date: date, type: .waist, value: max(50, value)))
        }

        // MARK: Chest series — cm, mostly stable / slight gain.
        let startChest = 102.0
        for w in 0..<weeks {
            guard let date = cal.date(byAdding: .day, value: -((weeks - 1 - w) * 7), to: now) else { continue }
            let noise = Double.random(in: -0.5...0.5, using: &rng)
            let value = startChest + Double(w) * 0.12 + noise
            context.insert(BodyMetric(date: date, type: .chest, value: value))
        }

        // MARK: Body-fat readings for variety (%).
        let bfStart = 24.0
        for w in stride(from: 0, to: weeks, by: 2) {
            guard let date = cal.date(byAdding: .day, value: -((weeks - 1 - w) * 7), to: now) else { continue }
            let value = bfStart - Double(w) * 0.25 + Double.random(in: -0.3...0.3, using: &rng)
            context.insert(BodyMetric(date: date, type: .bodyFat, value: max(5, value)))
        }

        // MARK: Progress photos — synthesized gradient tiles across the weeks.
        seedPhotos(context, weeks: weeks, now: now, startWeight: startWeight, weeklyLoss: weeklyLoss)

        try? context.save()
    }

    /// Generates ~5 gradient progress photos (mix of poses) dated across the span.
    private static func seedPhotos(_ context: ModelContext, weeks: Int, now: Date,
                                   startWeight: Double, weeklyLoss: Double) {
        let cal = Calendar.current
        // (weeksAgo, pose)
        let plan: [(Int, Pose)] = [
            (12, .front),
            (12, .side),
            (8, .front),
            (4, .side),
            (0, .front),
            (0, .back)
        ]
        for (weeksAgo, pose) in plan {
            guard let date = cal.date(byAdding: .day, value: -(weeksAgo * 7), to: now) else { continue }
            let image = renderGradient(pose: pose, label: pose.label)
            let filename = ImageStore.save(image) ?? ""
            let weeksElapsed = Double(weeks - 1 - weeksAgo)
            let weight = max(40, startWeight - weeksElapsed * weeklyLoss)
            let photo = ProgressPhoto(date: date, pose: pose, filename: filename,
                                      note: weeksAgo == 0 ? "Latest check-in." : "",
                                      weightAtTime: weight)
            context.insert(photo)
        }
    }

    /// Renders a calm vertical gradient tile with the pose label drawn on it,
    /// using Brand-ish colors. Pure UIKit so no asset catalog is required.
    static func renderGradient(pose: Pose, label: String) -> UIImage {
        let size = CGSize(width: 600, height: 800)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let cg = ctx.cgContext
            // Brand-ish slate gradient, shifted per pose for variety.
            let tops: [Pose: UIColor] = [
                .front: UIColor(hex: 0x5A6B8C),
                .side:  UIColor(hex: 0x6B7C9C),
                .back:  UIColor(hex: 0x4A5B7C)
            ]
            let top = tops[pose] ?? UIColor(hex: 0x5A6B8C)
            let bottom = UIColor(hex: 0x23262F)
            let colors = [top.cgColor, bottom.cgColor] as CFArray
            let space = CGColorSpaceCreateDeviceRGB()
            if let gradient = CGGradient(colorsSpace: space, colors: colors,
                                         locations: [0, 1]) {
                cg.drawLinearGradient(gradient,
                                      start: CGPoint(x: 0, y: 0),
                                      end: CGPoint(x: 0, y: size.height),
                                      options: [])
            }

            // Subtle silhouette circle (decorative).
            cg.setFillColor(UIColor.white.withAlphaComponent(0.07).cgColor)
            let r: CGFloat = 220
            cg.fillEllipse(in: CGRect(x: (size.width - r) / 2, y: 150, width: r, height: r))

            // Pose label centered near the bottom.
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 64, weight: .semibold),
                .foregroundColor: UIColor.white.withAlphaComponent(0.92),
                .paragraphStyle: paragraph
            ]
            let text = label as NSString
            let bounds = CGRect(x: 0, y: size.height - 220, width: size.width, height: 90)
            text.draw(in: bounds, withAttributes: attrs)

            let sub: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 26, weight: .regular),
                .foregroundColor: UIColor.white.withAlphaComponent(0.6),
                .paragraphStyle: paragraph
            ]
            let subText = "Contour" as NSString
            subText.draw(in: CGRect(x: 0, y: size.height - 130, width: size.width, height: 40),
                         withAttributes: sub)
        }
    }
}

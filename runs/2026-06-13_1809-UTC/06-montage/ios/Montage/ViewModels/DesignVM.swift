import SwiftUI
import UIKit

@Observable
final class DesignVM {
    let template: MontageTemplate
    var photos: [Int: UIImage] = [:]
    var backgroundID: String
    var texts: [TextOverlay] = []
    var selectedTextID: UUID?

    init(template: MontageTemplate) {
        self.template = template
        let defaults = UserDefaults.standard
        switch template.category {
        case .story: backgroundID = defaults.string(forKey: "defaultStoryBackground") ?? "sunset"
        case .square, .collage: backgroundID = "white"
        }
        let wantsCaption = defaults.object(forKey: "addCaptionByDefault") as? Bool ?? true
        if template.captionDefault && wantsCaption {
            texts = [TextOverlay(text: "Your caption", x: 0.5, y: 0.86, fontScale: 0.045,
                                 colorHex: 0xFFFFFF, weight: .bold, hasShadow: true)]
        }
    }

    var background: BackgroundStyle { BackgroundLibrary.byID(backgroundID) }
    var filledCount: Int { photos.values.count }
    var isEmpty: Bool { photos.isEmpty }
    var selectedText: TextOverlay? { texts.first { $0.id == selectedTextID } }

    func assign(_ image: UIImage, to slot: Int) {
        photos[slot] = image
        Haptics.tap()
    }
    func clearSlot(_ slot: Int) { photos[slot] = nil }

    func addText() {
        let t = TextOverlay(text: "Tap to edit", x: 0.5, y: 0.5, fontScale: 0.05,
                            colorHex: 0xFFFFFF, weight: .bold, hasShadow: true)
        texts.append(t)
        selectedTextID = t.id
        Haptics.tap()
    }

    func removeText(_ id: UUID) {
        texts.removeAll { $0.id == id }
        if selectedTextID == id { selectedTextID = nil }
    }

    func updateSelected(_ mutate: (inout TextOverlay) -> Void) {
        guard let id = selectedTextID, let idx = texts.firstIndex(where: { $0.id == id }) else { return }
        mutate(&texts[idx])
    }

    func moveText(_ id: UUID, to point: CGPoint) {
        guard let idx = texts.firstIndex(where: { $0.id == id }) else { return }
        texts[idx].x = min(1, max(0, point.x))
        texts[idx].y = min(1, max(0, point.y))
    }
}

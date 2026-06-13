import SwiftUI

enum TemplateCategory: String, CaseIterable, Identifiable {
    case story, square, collage
    var id: String { rawValue }
    var label: String {
        switch self {
        case .story: return "Story"
        case .square: return "Square"
        case .collage: return "Collage"
        }
    }
    var icon: String {
        switch self {
        case .story: return "rectangle.portrait"
        case .square: return "square"
        case .collage: return "rectangle.split.2x2"
        }
    }
}

/// A photo frame in normalized (0…1) coordinates within the canvas.
struct Frame: Identifiable {
    let id = UUID()
    let rect: CGRect          // normalized
    var cornerRadius: CGFloat = 0
}

struct MontageTemplate: Identifiable, Hashable {
    let id: String
    let name: String
    let category: TemplateCategory
    let aspect: CGFloat       // width / height
    let frames: [Frame]
    let inset: CGFloat        // outer padding fraction
    let spacing: CGFloat      // gap fraction between frames
    let captionDefault: Bool  // template includes a caption by default

    static func == (l: MontageTemplate, r: MontageTemplate) -> Bool { l.id == r.id }
    func hash(into h: inout Hasher) { h.combine(id) }

    var slotCount: Int { frames.count }
}

enum TemplateLibrary {
    static let all: [MontageTemplate] = story + square + collage

    static func inCategory(_ c: TemplateCategory) -> [MontageTemplate] { all.filter { $0.category == c } }

    private static func grid(rows: Int, cols: Int) -> [Frame] {
        var f: [Frame] = []
        let w = 1.0 / Double(cols), h = 1.0 / Double(rows)
        for r in 0..<rows {
            for c in 0..<cols {
                f.append(Frame(rect: CGRect(x: Double(c) * w, y: Double(r) * h, width: w, height: h), cornerRadius: 14))
            }
        }
        return f
    }

    static let story: [MontageTemplate] = [
        MontageTemplate(id: "s_single", name: "Single", category: .story, aspect: 9.0/16.0,
                        frames: [Frame(rect: CGRect(x: 0, y: 0, width: 1, height: 1), cornerRadius: 18)],
                        inset: 0.06, spacing: 0, captionDefault: true),
        MontageTemplate(id: "s_full", name: "Full bleed", category: .story, aspect: 9.0/16.0,
                        frames: [Frame(rect: CGRect(x: 0, y: 0, width: 1, height: 1), cornerRadius: 0)],
                        inset: 0, spacing: 0, captionDefault: true),
        MontageTemplate(id: "s_split", name: "Split", category: .story, aspect: 9.0/16.0,
                        frames: [Frame(rect: CGRect(x: 0, y: 0, width: 1, height: 0.5), cornerRadius: 14),
                                 Frame(rect: CGRect(x: 0, y: 0.5, width: 1, height: 0.5), cornerRadius: 14)],
                        inset: 0.05, spacing: 0.02, captionDefault: false),
        MontageTemplate(id: "s_trio", name: "Trio", category: .story, aspect: 9.0/16.0,
                        frames: [Frame(rect: CGRect(x: 0, y: 0, width: 1, height: 1.0/3), cornerRadius: 12),
                                 Frame(rect: CGRect(x: 0, y: 1.0/3, width: 1, height: 1.0/3), cornerRadius: 12),
                                 Frame(rect: CGRect(x: 0, y: 2.0/3, width: 1, height: 1.0/3), cornerRadius: 12)],
                        inset: 0.05, spacing: 0.02, captionDefault: false),
        MontageTemplate(id: "s_polaroid", name: "Polaroid", category: .story, aspect: 9.0/16.0,
                        frames: [Frame(rect: CGRect(x: 0.12, y: 0.20, width: 0.76, height: 0.5), cornerRadius: 6)],
                        inset: 0, spacing: 0, captionDefault: true),
        MontageTemplate(id: "s_header", name: "Header", category: .story, aspect: 9.0/16.0,
                        frames: [Frame(rect: CGRect(x: 0, y: 0, width: 1, height: 0.68), cornerRadius: 16)],
                        inset: 0.05, spacing: 0, captionDefault: true)
    ]

    static let square: [MontageTemplate] = [
        MontageTemplate(id: "q_full", name: "Full", category: .square, aspect: 1,
                        frames: [Frame(rect: CGRect(x: 0, y: 0, width: 1, height: 1), cornerRadius: 14)],
                        inset: 0.05, spacing: 0, captionDefault: true),
        MontageTemplate(id: "q_quad", name: "2 × 2", category: .square, aspect: 1,
                        frames: grid(rows: 2, cols: 2), inset: 0.04, spacing: 0.02, captionDefault: false),
        MontageTemplate(id: "q_strip", name: "Strip", category: .square, aspect: 1,
                        frames: [Frame(rect: CGRect(x: 0, y: 0, width: 1.0/3, height: 1), cornerRadius: 12),
                                 Frame(rect: CGRect(x: 1.0/3, y: 0, width: 1.0/3, height: 1), cornerRadius: 12),
                                 Frame(rect: CGRect(x: 2.0/3, y: 0, width: 1.0/3, height: 1), cornerRadius: 12)],
                        inset: 0.04, spacing: 0.02, captionDefault: false),
        MontageTemplate(id: "q_onetwo", name: "1 + 2", category: .square, aspect: 1,
                        frames: [Frame(rect: CGRect(x: 0, y: 0, width: 0.6, height: 1), cornerRadius: 12),
                                 Frame(rect: CGRect(x: 0.6, y: 0, width: 0.4, height: 0.5), cornerRadius: 12),
                                 Frame(rect: CGRect(x: 0.6, y: 0.5, width: 0.4, height: 0.5), cornerRadius: 12)],
                        inset: 0.04, spacing: 0.02, captionDefault: false)
    ]

    static let collage: [MontageTemplate] = [
        MontageTemplate(id: "c_triptych", name: "Triptych", category: .collage, aspect: 4.0/5.0,
                        frames: [Frame(rect: CGRect(x: 0, y: 0, width: 1.0/3, height: 1), cornerRadius: 10),
                                 Frame(rect: CGRect(x: 1.0/3, y: 0, width: 1.0/3, height: 1), cornerRadius: 10),
                                 Frame(rect: CGRect(x: 2.0/3, y: 0, width: 1.0/3, height: 1), cornerRadius: 10)],
                        inset: 0.03, spacing: 0.015, captionDefault: false),
        MontageTemplate(id: "c_bigsmall", name: "Feature", category: .collage, aspect: 4.0/5.0,
                        frames: [Frame(rect: CGRect(x: 0, y: 0, width: 1, height: 0.62), cornerRadius: 12),
                                 Frame(rect: CGRect(x: 0, y: 0.62, width: 0.5, height: 0.38), cornerRadius: 12),
                                 Frame(rect: CGRect(x: 0.5, y: 0.62, width: 0.5, height: 0.38), cornerRadius: 12)],
                        inset: 0.03, spacing: 0.015, captionDefault: false),
        MontageTemplate(id: "c_quad", name: "Grid", category: .collage, aspect: 4.0/5.0,
                        frames: grid(rows: 2, cols: 2), inset: 0.03, spacing: 0.015, captionDefault: false),
        MontageTemplate(id: "c_six", name: "Six", category: .collage, aspect: 4.0/5.0,
                        frames: grid(rows: 3, cols: 2), inset: 0.03, spacing: 0.015, captionDefault: false)
    ]
}

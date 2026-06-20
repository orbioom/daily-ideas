import UIKit
import Foundation

struct ScriptPDFExporter {
    // Page size: Letter 8.5" x 11" at 72pt/inch
    static let pageWidth: CGFloat = 8.5 * 72    // 612
    static let pageHeight: CGFloat = 11 * 72     // 792
    static let marginLeft: CGFloat = 1.5 * 72    // 108
    static let marginRight: CGFloat = 1.0 * 72   // 72 from right edge
    static let marginTop: CGFloat = 1.0 * 72     // 72
    static let marginBottom: CGFloat = 1.0 * 72  // 72
    static let contentWidth: CGFloat = pageWidth - marginLeft - marginRight  // 432

    static func export(project: ScriptProject) -> Data {
        let format = UIGraphicsPDFRendererFormat()
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let elements = FountainParser.parse(text: project.content)
        let courier12 = UIFont(name: "Courier", size: 12) ?? UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        let courier12Bold = UIFont(name: "Courier-Bold", size: 12) ?? UIFont.monospacedSystemFont(ofSize: 12, weight: .bold)

        struct DrawItem {
            let text: NSAttributedString
            let rect: CGRect
            let isPageBreak: Bool
        }

        var drawItems: [DrawItem] = []
        var currentY: CGFloat = marginTop

        func makeAttrs(font: UIFont, alignment: NSTextAlignment = .left, color: UIColor = .black) -> [NSAttributedString.Key: Any] {
            let para = NSMutableParagraphStyle()
            para.alignment = alignment
            return [.font: font, .paragraphStyle: para, .foregroundColor: color]
        }

        func addItem(_ text: String, font: UIFont, x: CGFloat, width: CGFloat, alignment: NSTextAlignment = .left) {
            let attrStr = NSAttributedString(string: text, attributes: makeAttrs(font: font, alignment: alignment))
            let boundingRect = attrStr.boundingRect(
                with: CGSize(width: width, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                context: nil
            )
            let itemHeight = max(boundingRect.height, courier12.lineHeight)
            let rect = CGRect(x: x, y: currentY, width: width, height: itemHeight)
            drawItems.append(DrawItem(text: attrStr, rect: rect, isPageBreak: false))
            currentY += itemHeight + 4
        }

        func addPageBreak() {
            drawItems.append(DrawItem(text: NSAttributedString(string: ""), rect: .zero, isPageBreak: true))
            currentY = marginTop
        }

        for element in elements {
            if currentY > pageHeight - marginBottom - 48 {
                addPageBreak()
            }

            switch element.type {
            case .titlePage:
                continue

            case .sceneHeading:
                currentY += 12
                addItem(element.text.uppercased(), font: courier12Bold, x: marginLeft, width: contentWidth)
                currentY += 4

            case .action:
                addItem(element.text, font: courier12, x: marginLeft, width: contentWidth)
                currentY += 4

            case .character:
                currentY += 8
                let charX: CGFloat = 266
                let charWidth: CGFloat = pageWidth - charX - marginRight
                addItem(element.text.uppercased(), font: courier12, x: charX, width: charWidth)

            case .dialogue:
                let dialogueX: CGFloat = 2.5 * 72
                let dialogueWidth: CGFloat = 3.5 * 72
                addItem(element.text, font: courier12, x: dialogueX, width: dialogueWidth)

            case .parenthetical:
                let parenX: CGFloat = 3.1 * 72
                let parenWidth: CGFloat = contentWidth - (parenX - marginLeft)
                addItem(element.text, font: courier12, x: parenX, width: parenWidth)

            case .transition:
                currentY += 8
                addItem(element.text, font: courier12, x: marginLeft, width: contentWidth, alignment: .right)
                currentY += 8

            case .pageBreak:
                addPageBreak()

            case .centered:
                let centered = element.text.trimmingCharacters(in: CharacterSet(charactersIn: "><"))
                addItem(centered, font: courier12, x: marginLeft, width: contentWidth, alignment: .center)

            default:
                addItem(element.text, font: courier12, x: marginLeft, width: contentWidth)
            }
        }

        let data = renderer.pdfData { context in
            // Title page
            context.beginPage()
            let titleFont = UIFont(name: "Courier-Bold", size: 16) ?? UIFont.monospacedSystemFont(ofSize: 16, weight: .bold)
            let subtitleFont = courier12

            let titleStr = project.title.isEmpty ? "UNTITLED" : project.title.uppercased()
            let titleAttr = NSAttributedString(string: titleStr, attributes: makeAttrs(font: titleFont, alignment: .center))
            titleAttr.draw(in: CGRect(x: 0, y: pageHeight * 0.4, width: pageWidth, height: 40))

            if !project.author.isEmpty {
                let byAttr = NSAttributedString(string: "Written by", attributes: makeAttrs(font: subtitleFont, alignment: .center))
                byAttr.draw(in: CGRect(x: 0, y: pageHeight * 0.4 + 50, width: pageWidth, height: 20))
                let authorAttr = NSAttributedString(string: project.author, attributes: makeAttrs(font: subtitleFont, alignment: .center))
                authorAttr.draw(in: CGRect(x: 0, y: pageHeight * 0.4 + 70, width: pageWidth, height: 20))
            }

            let draftAttr = NSAttributedString(string: project.draftNumber, attributes: makeAttrs(font: subtitleFont, alignment: .center))
            draftAttr.draw(in: CGRect(x: 0, y: pageHeight * 0.4 + 110, width: pageWidth, height: 20))

            // Content pages
            var pgNum = 0
            var needsNewPage = true

            for item in drawItems {
                if item.isPageBreak {
                    context.beginPage()
                    pgNum += 1
                    let pgStr = "\(pgNum + 1)."
                    let pgAttr = NSAttributedString(string: pgStr, attributes: makeAttrs(font: subtitleFont, alignment: .right))
                    pgAttr.draw(in: CGRect(x: pageWidth - marginRight - 50, y: 36, width: 50, height: 20))
                    needsNewPage = false
                    continue
                }

                if needsNewPage {
                    context.beginPage()
                    pgNum = 1
                    needsNewPage = false
                    let pgStr = "\(pgNum)."
                    let pgAttr = NSAttributedString(string: pgStr, attributes: makeAttrs(font: subtitleFont, alignment: .right))
                    pgAttr.draw(in: CGRect(x: pageWidth - marginRight - 50, y: 36, width: 50, height: 20))
                }

                item.text.draw(in: item.rect)
            }
        }

        return data
    }
}

import UIKit
import Foundation

struct InvoicePDFRenderer {
    static func generatePDF(invoice: Invoice, settings: BriefSettings) -> Data {
        let pageWidth: CGFloat = 595
        let pageHeight: CGFloat = 842
        let margin: CGFloat = 50

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        return renderer.pdfData { ctx in
            ctx.beginPage()
            let context = ctx.cgContext

            context.setFillColor(UIColor.systemBackground.cgColor)
            context.fill(CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

            var yPos: CGFloat = margin

            let businessName = settings.businessName.isEmpty ? "Your Business" : settings.businessName
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 28, weight: .bold),
                .foregroundColor: UIColor(red: 0.1, green: 0.15, blue: 0.4, alpha: 1)
            ]
            businessName.draw(at: CGPoint(x: margin, y: yPos), withAttributes: titleAttrs)

            let invoiceLabel = "INVOICE"
            let invoiceLabelAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .semibold),
                .foregroundColor: UIColor.secondaryLabel
            ]
            let invoiceLabelSize = (invoiceLabel as NSString).size(withAttributes: invoiceLabelAttrs)
            (invoiceLabel as NSString).draw(
                at: CGPoint(x: pageWidth - margin - invoiceLabelSize.width, y: yPos),
                withAttributes: invoiceLabelAttrs
            )

            yPos += 40

            let smallAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.secondaryLabel
            ]

            for line in [settings.businessEmail, settings.businessPhone, settings.businessAddress].filter({ !$0.isEmpty }) {
                line.draw(at: CGPoint(x: margin, y: yPos), withAttributes: smallAttrs)
                yPos += 14
            }

            yPos += 10

            let detailAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .medium),
                .foregroundColor: UIColor.label
            ]
            let df = DateFormatter()
            df.dateStyle = .medium

            let details: [(String, String)] = [
                ("Invoice #:", invoice.number.isEmpty ? "Draft" : invoice.number),
                ("Issue Date:", df.string(from: invoice.issueDate)),
                ("Due Date:", df.string(from: invoice.dueDate)),
                ("Status:", invoice.displayStatus.rawValue)
            ]

            let detailX: CGFloat = pageWidth - margin - 200
            var detailY: CGFloat = margin + 40
            for (label, value) in details {
                label.draw(at: CGPoint(x: detailX, y: detailY), withAttributes: smallAttrs)
                value.draw(at: CGPoint(x: detailX + 90, y: detailY), withAttributes: detailAttrs)
                detailY += 16
            }

            context.setStrokeColor(UIColor.separator.cgColor)
            context.setLineWidth(1)
            context.move(to: CGPoint(x: margin, y: yPos))
            context.addLine(to: CGPoint(x: pageWidth - margin, y: yPos))
            context.strokePath()
            yPos += 16

            let sectionAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10, weight: .semibold),
                .foregroundColor: UIColor.secondaryLabel
            ]
            "BILL TO".draw(at: CGPoint(x: margin, y: yPos), withAttributes: sectionAttrs)
            yPos += 16

            if let client = invoice.client {
                let clientNameAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 13, weight: .semibold),
                    .foregroundColor: UIColor.label
                ]
                client.name.draw(at: CGPoint(x: margin, y: yPos), withAttributes: clientNameAttrs)
                yPos += 18
                for line in [client.company, client.email, client.address].filter({ !$0.isEmpty }) {
                    line.draw(at: CGPoint(x: margin, y: yPos), withAttributes: smallAttrs)
                    yPos += 14
                }
            }

            yPos += 24

            context.setFillColor(UIColor(red: 0.93, green: 0.94, blue: 0.98, alpha: 1).cgColor)
            context.fill(CGRect(x: margin, y: yPos, width: pageWidth - 2 * margin, height: 24))

            let headerAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10, weight: .semibold),
                .foregroundColor: UIColor.label
            ]
            "Description".draw(at: CGPoint(x: margin + 8, y: yPos + 7), withAttributes: headerAttrs)
            "Qty".draw(at: CGPoint(x: pageWidth - margin - 195, y: yPos + 7), withAttributes: headerAttrs)
            "Rate".draw(at: CGPoint(x: pageWidth - margin - 130, y: yPos + 7), withAttributes: headerAttrs)
            "Amount".draw(at: CGPoint(x: pageWidth - margin - 65, y: yPos + 7), withAttributes: headerAttrs)
            yPos += 28

            let sortedItems = invoice.lineItems.sorted { $0.order < $1.order }
            var isAlt = false
            let rowAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.label
            ]

            for item in sortedItems {
                if isAlt {
                    context.setFillColor(UIColor(red: 0.97, green: 0.97, blue: 0.99, alpha: 1).cgColor)
                    context.fill(CGRect(x: margin, y: yPos, width: pageWidth - 2 * margin, height: 22))
                }

                item.itemDescription.draw(at: CGPoint(x: margin + 8, y: yPos + 6), withAttributes: rowAttrs)

                let fmt = NumberFormatter()
                fmt.numberStyle = .decimal
                fmt.maximumFractionDigits = 2
                let qtyStr = fmt.string(from: item.quantity as NSDecimalNumber) ?? ""
                qtyStr.draw(at: CGPoint(x: pageWidth - margin - 195, y: yPos + 6), withAttributes: rowAttrs)

                let rateStr = formatCurrency(item.unitPrice, code: invoice.currencyCode)
                rateStr.draw(at: CGPoint(x: pageWidth - margin - 130, y: yPos + 6), withAttributes: rowAttrs)

                let amtStr = formatCurrency(item.subtotal, code: invoice.currencyCode)
                amtStr.draw(at: CGPoint(x: pageWidth - margin - 65, y: yPos + 6), withAttributes: rowAttrs)

                yPos += 24
                isAlt.toggle()
            }

            yPos += 16

            context.setStrokeColor(UIColor.separator.cgColor)
            context.setLineWidth(0.5)
            context.move(to: CGPoint(x: pageWidth - margin - 220, y: yPos))
            context.addLine(to: CGPoint(x: pageWidth - margin, y: yPos))
            context.strokePath()
            yPos += 8

            var totals: [(String, Decimal)] = [("Subtotal", invoice.subtotal)]
            if invoice.discountAmount > Decimal(0) {
                totals.append(("Discount", -invoice.discountAmount))
            }
            if invoice.taxRate > Decimal(0) {
                let pct = invoice.taxRate * Decimal(100)
                totals.append(("Tax (\(pct)%)", invoice.taxAmount))
            }
            totals.append(("TOTAL", invoice.total))

            for (label, amount) in totals {
                let isBold = label == "TOTAL"
                let labelFont = UIFont.systemFont(ofSize: isBold ? 12 : 10, weight: isBold ? .bold : .regular)
                let valueFont = UIFont.systemFont(ofSize: isBold ? 13 : 10, weight: isBold ? .bold : .bold)
                let lAttrs: [NSAttributedString.Key: Any] = [.font: labelFont, .foregroundColor: UIColor.secondaryLabel]
                let vAttrs: [NSAttributedString.Key: Any] = [.font: valueFont, .foregroundColor: UIColor.label]

                label.draw(at: CGPoint(x: pageWidth - margin - 180, y: yPos), withAttributes: lAttrs)
                formatCurrency(amount, code: invoice.currencyCode).draw(
                    at: CGPoint(x: pageWidth - margin - 70, y: yPos),
                    withAttributes: vAttrs
                )
                yPos += isBold ? 22 : 18
            }

            if !invoice.notes.isEmpty {
                yPos += 24
                "NOTES".draw(at: CGPoint(x: margin, y: yPos), withAttributes: sectionAttrs)
                yPos += 16

                let notesRect = CGRect(x: margin, y: yPos, width: pageWidth - 2 * margin, height: 60)
                invoice.notes.draw(in: notesRect, withAttributes: smallAttrs)
            }

            let footerY = pageHeight - margin
            let footerAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 9),
                .foregroundColor: UIColor.tertiaryLabel
            ]
            "Generated by Brief • \(settings.businessName.isEmpty ? "" : settings.businessName)".draw(
                at: CGPoint(x: margin, y: footerY - 12),
                withAttributes: footerAttrs
            )
        }
    }
}

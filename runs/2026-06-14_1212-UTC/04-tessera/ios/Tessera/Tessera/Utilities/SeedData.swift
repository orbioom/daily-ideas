import Foundation
import SwiftData

/// Seeds realistic demo accounts across folders and algorithms.
///
/// All secrets are obviously-fake demo strings (valid Base32 so codes render, but
/// not tied to any real service). Used by the Settings "Load sample data" action.
enum SeedData {

    private struct Entry {
        let issuer: String
        let label: String
        let secret: String
        let algorithm: OTPAlgorithm
        let digits: Int
        let period: Int
        let type: OTPType
        let folder: String
        let hue: Double
        let favorite: Bool
    }

    /// Folder names used by the seed, in display order.
    static let folderNames = ["Work", "Personal", "Finance", "Crypto", "Social"]

    private static func entries() -> [Entry] {
        // Fake but valid Base32 secrets (A–Z, 2–7). Clearly demo data.
        return [
            Entry(issuer: "GitHub", label: "ada@orbioom.com", secret: "JBSWY3DPEHPK3PXP",
                  algorithm: .sha1, digits: 6, period: 30, type: .totp, folder: "Work", hue: 0.62, favorite: true),
            Entry(issuer: "GitLab", label: "ada.dev", secret: "MZXW6YTBOI======",
                  algorithm: .sha256, digits: 6, period: 30, type: .totp, folder: "Work", hue: 0.08, favorite: false),
            Entry(issuer: "Okta", label: "a.lovelace@corp", secret: "GEZDGNBVGY3TQOJQ",
                  algorithm: .sha1, digits: 6, period: 30, type: .totp, folder: "Work", hue: 0.55, favorite: false),
            Entry(issuer: "AWS", label: "root-account", secret: "KRSXG5CTMVRXEZLU",
                  algorithm: .sha512, digits: 6, period: 30, type: .totp, folder: "Work", hue: 0.09, favorite: false),
            Entry(issuer: "Google", label: "ada@gmail.com", secret: "JBSWY3DPEHPK3PXP",
                  algorithm: .sha1, digits: 6, period: 30, type: .totp, folder: "Personal", hue: 0.0, favorite: true),
            Entry(issuer: "Apple", label: "ada@icloud.com", secret: "NBSWY3DPEB3W64TM",
                  algorithm: .sha1, digits: 6, period: 30, type: .totp, folder: "Personal", hue: 0.7, favorite: false),
            Entry(issuer: "Microsoft", label: "ada@outlook.com", secret: "ONXW2ZJAMRXWG5LU",
                  algorithm: .sha1, digits: 6, period: 30, type: .totp, folder: "Personal", hue: 0.33, favorite: false),
            Entry(issuer: "Coinbase", label: "ada.trades", secret: "MFRGGZDFMZTWQ2LK",
                  algorithm: .sha1, digits: 7, period: 30, type: .totp, folder: "Finance", hue: 0.6, favorite: false),
            Entry(issuer: "Stripe", label: "dashboard", secret: "ORSXG5BAONSWG4TF",
                  algorithm: .sha256, digits: 6, period: 30, type: .totp, folder: "Finance", hue: 0.78, favorite: false),
            Entry(issuer: "PayPal", label: "ada@orbioom.com", secret: "PEBLOMYDEYTCMJSG",
                  algorithm: .sha1, digits: 6, period: 30, type: .totp, folder: "Finance", hue: 0.58, favorite: false),
            Entry(issuer: "Binance", label: "ada.hodl", secret: "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ",
                  algorithm: .sha1, digits: 8, period: 30, type: .totp, folder: "Crypto", hue: 0.12, favorite: true),
            Entry(issuer: "Kraken", label: "cold-storage", secret: "KRUGS4ZANFZSA5DI",
                  algorithm: .sha512, digits: 6, period: 60, type: .totp, folder: "Crypto", hue: 0.66, favorite: false),
            Entry(issuer: "Ledger", label: "recovery", secret: "NF2GQ2LOMU======",
                  algorithm: .sha1, digits: 6, period: 30, type: .hotp, folder: "Crypto", hue: 0.5, favorite: false),
            Entry(issuer: "X", label: "@ada", secret: "JFWWK4TDPB2GK3LL",
                  algorithm: .sha1, digits: 6, period: 30, type: .totp, folder: "Social", hue: 0.0, favorite: false),
            Entry(issuer: "Discord", label: "ada#1815", secret: "MFXG65DIMVZHIZLE",
                  algorithm: .sha1, digits: 6, period: 30, type: .totp, folder: "Social", hue: 0.65, favorite: false),
            Entry(issuer: "Reddit", label: "u/countess_ada", secret: "ONSWG4TFOQQGS3DF",
                  algorithm: .sha1, digits: 6, period: 30, type: .totp, folder: "Social", hue: 0.06, favorite: false),
            Entry(issuer: "Steam", label: "ada_plays", secret: "PFXXK4TUPEXXK4DT",
                  algorithm: .sha1, digits: 5, period: 30, type: .totp, folder: "Personal", hue: 0.58, favorite: false),
        ]
    }

    /// Whether any accounts already exist (so we don't double-seed).
    static func hasData(context: ModelContext) -> Bool {
        let descriptor = FetchDescriptor<Account>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        return count > 0
    }

    /// Insert the demo accounts and folders. Safe to call repeatedly via the
    /// `replaceExisting` flag (clears first) — otherwise it appends.
    @discardableResult
    static func load(context: ModelContext, replaceExisting: Bool) -> Int {
        if replaceExisting {
            eraseAll(context: context)
        }

        // Create folders, keyed by name.
        var folderMap: [String: Folder] = [:]
        for (index, name) in folderNames.enumerated() {
            let folder = Folder(name: name, sortIndex: index)
            context.insert(folder)
            folderMap[name] = folder
        }

        var inserted = 0
        let base = Date()
        for (index, entry) in entries().enumerated() {
            // Steam uses a non-standard 5-digit length; clamp to a valid value so
            // the demo always renders cleanly.
            let account = Account(issuer: entry.issuer,
                                  label: entry.label,
                                  secretBase32: entry.secret,
                                  algorithm: entry.algorithm,
                                  digits: OTPGenerator.clampDigits(entry.digits),
                                  period: entry.period,
                                  type: entry.type,
                                  counter: entry.type == .hotp ? 0 : 0,
                                  colorHue: entry.hue,
                                  sortIndex: index,
                                  favorite: entry.favorite,
                                  createdAt: base.addingTimeInterval(Double(-index) * 3600),
                                  folder: folderMap[entry.folder])
            context.insert(account)
            inserted += 1
        }
        try? context.save()
        return inserted
    }

    /// Remove all accounts and folders.
    static func eraseAll(context: ModelContext) {
        if let accounts = try? context.fetch(FetchDescriptor<Account>()) {
            for account in accounts { context.delete(account) }
        }
        if let folders = try? context.fetch(FetchDescriptor<Folder>()) {
            for folder in folders { context.delete(folder) }
        }
        try? context.save()
    }
}

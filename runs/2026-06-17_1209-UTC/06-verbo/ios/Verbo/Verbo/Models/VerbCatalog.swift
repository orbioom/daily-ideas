import Foundation

/// Static catalog of verbs. ≥60 total (≥40 Spanish, ≥20 French).
enum VerbCatalog {

    static let all: [Verb] = spanish + french

    /// Verbs for a language, optionally limited to the free tier.
    static func verbs(for language: Language, proUnlocked: Bool) -> [Verb] {
        let list = all.filter { $0.language == language }
        if language == .spanish && !proUnlocked {
            // Free tier: first 40 Spanish verbs.
            return Array(list.prefix(40))
        }
        return list
    }

    static func verb(infinitive: String, language: Language) -> Verb? {
        all.first { $0.infinitive == infinitive && $0.language == language }
    }

    // MARK: - Spanish (44)

    static let spanish: [Verb] = [
        // Irregulars (14)
        Verb("ser", .spanish, "to be (essence)", .er, irregular: true),
        Verb("estar", .spanish, "to be (state)", .ar, irregular: true),
        Verb("ir", .spanish, "to go", .ir, irregular: true),
        Verb("haber", .spanish, "to have (auxiliary)", .er, irregular: true),
        Verb("tener", .spanish, "to have", .er, irregular: true),
        Verb("hacer", .spanish, "to do, to make", .er, irregular: true),
        Verb("poder", .spanish, "to be able, can", .er, irregular: true),
        Verb("decir", .spanish, "to say, to tell", .ir, irregular: true),
        Verb("ver", .spanish, "to see", .er, irregular: true),
        Verb("dar", .spanish, "to give", .ar, irregular: true),
        Verb("saber", .spanish, "to know (facts)", .er, irregular: true),
        Verb("querer", .spanish, "to want, to love", .er, irregular: true),
        Verb("poner", .spanish, "to put, to place", .er, irregular: true),
        Verb("venir", .spanish, "to come", .ir, irregular: true),

        // Regular -ar (16)
        Verb("hablar", .spanish, "to speak, to talk", .ar),
        Verb("trabajar", .spanish, "to work", .ar),
        Verb("estudiar", .spanish, "to study", .ar),
        Verb("comprar", .spanish, "to buy", .ar),
        Verb("cantar", .spanish, "to sing", .ar),
        Verb("bailar", .spanish, "to dance", .ar),
        Verb("caminar", .spanish, "to walk", .ar),
        Verb("escuchar", .spanish, "to listen", .ar),
        Verb("mirar", .spanish, "to look, to watch", .ar),
        Verb("cocinar", .spanish, "to cook", .ar),
        Verb("viajar", .spanish, "to travel", .ar),
        Verb("llamar", .spanish, "to call", .ar),
        Verb("ayudar", .spanish, "to help", .ar),
        Verb("preguntar", .spanish, "to ask", .ar),
        Verb("descansar", .spanish, "to rest", .ar),
        Verb("nadar", .spanish, "to swim", .ar),

        // Regular -er (7)
        Verb("comer", .spanish, "to eat", .er),
        Verb("beber", .spanish, "to drink", .er),
        Verb("aprender", .spanish, "to learn", .er),
        Verb("leer", .spanish, "to read", .er),
        Verb("correr", .spanish, "to run", .er),
        Verb("vender", .spanish, "to sell", .er),
        Verb("comprender", .spanish, "to understand", .er),

        // Regular -ir (7)
        Verb("vivir", .spanish, "to live", .ir),
        Verb("escribir", .spanish, "to write", .ir),
        Verb("recibir", .spanish, "to receive", .ir),
        Verb("abrir", .spanish, "to open", .ir),
        Verb("subir", .spanish, "to go up, to climb", .ir),
        Verb("decidir", .spanish, "to decide", .ir),
        Verb("partir", .spanish, "to leave, to split", .ir),
    ]

    // MARK: - French (24)

    static let french: [Verb] = [
        // Irregulars (12)
        Verb("être", .french, "to be", .re, irregular: true),
        Verb("avoir", .french, "to have", .ir, irregular: true),
        Verb("aller", .french, "to go", .er, irregular: true, usesEtre: true),
        Verb("faire", .french, "to do, to make", .re, irregular: true),
        Verb("pouvoir", .french, "to be able, can", .ir, irregular: true),
        Verb("vouloir", .french, "to want", .ir, irregular: true),
        Verb("devoir", .french, "to have to, must", .ir, irregular: true),
        Verb("prendre", .french, "to take", .re, irregular: true),
        Verb("voir", .french, "to see", .ir, irregular: true),
        Verb("savoir", .french, "to know", .ir, irregular: true),
        Verb("venir", .french, "to come", .ir, irregular: true, usesEtre: true),
        Verb("dire", .french, "to say, to tell", .re, irregular: true),

        // Regular -er (6)
        Verb("parler", .french, "to speak", .er),
        Verb("aimer", .french, "to like, to love", .er),
        Verb("manger", .french, "to eat", .er),
        Verb("regarder", .french, "to look, to watch", .er),
        Verb("écouter", .french, "to listen", .er),
        Verb("travailler", .french, "to work", .er),

        // Regular -ir (3, finir-type)
        Verb("finir", .french, "to finish", .ir),
        Verb("choisir", .french, "to choose", .ir),
        Verb("réussir", .french, "to succeed", .ir),

        // Regular -re (3)
        Verb("vendre", .french, "to sell", .re),
        Verb("attendre", .french, "to wait", .re),
        Verb("répondre", .french, "to answer", .re),
    ]
}

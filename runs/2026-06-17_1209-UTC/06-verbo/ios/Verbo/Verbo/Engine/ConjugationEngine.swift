import Foundation

/// Pure conjugation engine. Returns the override form for irregular verbs when
/// present, otherwise computes the regular form. All indexing is guarded.
enum ConjugationEngine {

    /// Conjugate a single verb × tense × person.
    static func conjugate(_ verb: Verb, tense: Tense, person: Person) -> String {
        // Compound French tense is built from auxiliary + participle.
        if tense == .passeCompose {
            return frenchPasseCompose(verb, person: person)
        }

        // Irregular override (simple tenses).
        if let table = IrregularData.forms(for: verb.infinitive, language: verb.language),
           let forms = table[tense.rawValue],
           let form = forms[safe: person.slot] {
            return form
        }

        // Regular computation.
        switch verb.language {
        case .spanish: return spanishRegular(verb, tense: tense, slot: person.slot)
        case .french:  return frenchRegular(verb, tense: tense, slot: person.slot)
        }
    }

    /// Full table for a verb × tense, keyed by the language's persons.
    static func fullTable(_ verb: Verb, tense: Tense) -> [Person: String] {
        var result: [Person: String] = [:]
        for person in verb.language.persons {
            result[person] = conjugate(verb, tense: tense, person: person)
        }
        return result
    }

    // MARK: - Spanish regular

    private static func spanishRegular(_ verb: Verb, tense: Tense, slot: Int) -> String {
        let stem = verb.stem
        switch tense {
        case .presente:
            let endings: [String]
            switch verb.group {
            case .ar: endings = ["o", "as", "a", "amos", "áis", "an"]
            case .er: endings = ["o", "es", "e", "emos", "éis", "en"]
            case .ir: endings = ["o", "es", "e", "imos", "ís", "en"]
            case .re: endings = ["o", "es", "e", "emos", "éis", "en"]
            }
            return stem + (endings[safe: slot] ?? "")

        case .preterito:
            let endings: [String]
            switch verb.group {
            case .ar: endings = ["é", "aste", "ó", "amos", "asteis", "aron"]
            default:  endings = ["í", "iste", "ió", "imos", "isteis", "ieron"]  // -er/-ir share
            }
            return stem + (endings[safe: slot] ?? "")

        case .imperfecto:
            let endings: [String]
            switch verb.group {
            case .ar: endings = ["aba", "abas", "aba", "ábamos", "abais", "aban"]
            default:  endings = ["ía", "ías", "ía", "íamos", "íais", "ían"]     // -er/-ir share
            }
            return stem + (endings[safe: slot] ?? "")

        case .futuro:
            // Built on the full infinitive.
            let endings = ["é", "ás", "á", "emos", "éis", "án"]
            return verb.infinitive + (endings[safe: slot] ?? "")

        case .condicional:
            let endings = ["ía", "ías", "ía", "íamos", "íais", "ían"]
            return verb.infinitive + (endings[safe: slot] ?? "")

        case .subjuntivo:
            // Present subjunctive: -ar takes -e endings, -er/-ir take -a endings.
            let endings: [String]
            switch verb.group {
            case .ar: endings = ["e", "es", "e", "emos", "éis", "en"]
            default:  endings = ["a", "as", "a", "amos", "áis", "an"]
            }
            return stem + (endings[safe: slot] ?? "")

        default:
            return verb.infinitive
        }
    }

    // MARK: - French regular (simple tenses)

    private static func frenchRegular(_ verb: Verb, tense: Tense, slot: Int) -> String {
        let stem = verb.stem
        switch tense {
        case .present:
            switch verb.group {
            case .er:
                let endings = ["e", "es", "e", "ons", "ez", "ent"]
                return stem + (endings[safe: slot] ?? "")
            case .ir:
                // Standard -ir verbs (finir-type): infix -iss- in plural.
                let endings = ["is", "is", "it", "issons", "issez", "issent"]
                return stem + (endings[safe: slot] ?? "")
            case .re:
                let endings = ["s", "s", "", "ons", "ez", "ent"]
                return stem + (endings[safe: slot] ?? "")
            case .ar:
                return verb.infinitive
            }

        case .imparfait:
            // Built on the present "nous" stem; for regular verbs that's the
            // standard stem (+ -iss- for -ir verbs).
            let base: String
            switch verb.group {
            case .ir: base = stem + "iss"
            default:  base = stem
            }
            let endings = ["ais", "ais", "ait", "ions", "iez", "aient"]
            return base + (endings[safe: slot] ?? "")

        case .futur:
            // Future stem = infinitive (drop final -e for -re verbs).
            let futureStem: String
            if verb.group == .re, verb.infinitive.hasSuffix("e") {
                futureStem = String(verb.infinitive.dropLast())
            } else {
                futureStem = verb.infinitive
            }
            let endings = ["ai", "as", "a", "ons", "ez", "ont"]
            return futureStem + (endings[safe: slot] ?? "")

        default:
            return verb.infinitive
        }
    }

    // MARK: - French passé composé

    /// auxiliary (present of avoir/être) + past participle (+ agreement for être verbs).
    private static func frenchPasseCompose(_ verb: Verb, person: Person) -> String {
        let aux = verb.usesEtre ? "être" : "avoir"
        let auxForm = auxiliaryPresent(aux, slot: person.slot)
        var participle = frenchParticiple(verb)

        // Simple gender/number agreement for être verbs.
        if verb.usesEtre {
            participle = applyEtreAgreement(participle, slot: person.slot)
        }
        return "\(auxForm) \(participle)"
    }

    private static func auxiliaryPresent(_ aux: String, slot: Int) -> String {
        let forms: [String]
        if aux == "être" {
            forms = ["suis", "es", "est", "sommes", "êtes", "sont"]
        } else {
            forms = ["ai", "as", "a", "avons", "avez", "ont"]
        }
        return forms[safe: slot] ?? ""
    }

    /// Regular or irregular past participle.
    static func frenchParticiple(_ verb: Verb) -> String {
        if let irregular = IrregularData.frenchPastParticiple(verb.infinitive) {
            return irregular
        }
        let stem = verb.stem
        switch verb.group {
        case .er: return stem + "é"
        case .ir: return stem + "i"
        case .re: return stem + "u"
        case .ar: return verb.infinitive
        }
    }

    /// Default-masculine agreement; plural for nous/vous/ils slots.
    private static func applyEtreAgreement(_ participle: String, slot: Int) -> String {
        // slots 3 (nous), 4 (vous), 5 (ils) → plural -s (masculine default).
        if slot >= 3 {
            return participle.hasSuffix("s") ? participle : participle + "s"
        }
        return participle
    }
}

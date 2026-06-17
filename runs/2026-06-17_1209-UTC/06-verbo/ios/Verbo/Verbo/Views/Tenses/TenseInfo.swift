import Foundation

/// Teaching content for one tense: when to use it, the regular endings, and
/// example conjugations (resolved live from the engine).
struct TenseInfo {
    let tense: Tense
    let usage: String
    /// Endings keyed by group; each value is 6 endings in slot order.
    let endings: [(group: VerbGroup, values: [String])]
    /// Example verbs to show fully conjugated (infinitive form).
    let exampleVerbs: [String]

    static func info(for tense: Tense) -> TenseInfo {
        switch tense {
        case .presente:
            return TenseInfo(tense: tense,
                usage: "Describes what happens now, habitual actions, and general truths. The workhorse tense — learn it first.",
                endings: [(.ar, ["-o","-as","-a","-amos","-áis","-an"]),
                          (.er, ["-o","-es","-e","-emos","-éis","-en"]),
                          (.ir, ["-o","-es","-e","-imos","-ís","-en"])],
                exampleVerbs: ["hablar", "comer", "vivir"])
        case .preterito:
            return TenseInfo(tense: tense,
                usage: "The simple past for completed, one-time actions with a clear endpoint (\"I ate\", \"she spoke\").",
                endings: [(.ar, ["-é","-aste","-ó","-amos","-asteis","-aron"]),
                          (.er, ["-í","-iste","-ió","-imos","-isteis","-ieron"]),
                          (.ir, ["-í","-iste","-ió","-imos","-isteis","-ieron"])],
                exampleVerbs: ["hablar", "comer", "vivir"])
        case .imperfecto:
            return TenseInfo(tense: tense,
                usage: "The 'used to / was -ing' past for ongoing, repeated, or background actions. Highly regular.",
                endings: [(.ar, ["-aba","-abas","-aba","-ábamos","-abais","-aban"]),
                          (.er, ["-ía","-ías","-ía","-íamos","-íais","-ían"]),
                          (.ir, ["-ía","-ías","-ía","-íamos","-íais","-ían"])],
                exampleVerbs: ["hablar", "comer", "vivir"])
        case .futuro:
            return TenseInfo(tense: tense,
                usage: "Future actions ('will'). Endings attach to the whole infinitive, so all three groups share them.",
                endings: [(.ar, ["-é","-ás","-á","-emos","-éis","-án"]),
                          (.er, ["-é","-ás","-á","-emos","-éis","-án"]),
                          (.ir, ["-é","-ás","-á","-emos","-éis","-án"])],
                exampleVerbs: ["hablar", "comer", "vivir"])
        case .condicional:
            return TenseInfo(tense: tense,
                usage: "The 'would' mood for hypotheticals and politeness. Like the future, it builds on the infinitive.",
                endings: [(.ar, ["-ía","-ías","-ía","-íamos","-íais","-ían"]),
                          (.er, ["-ía","-ías","-ía","-íamos","-íais","-ían"]),
                          (.ir, ["-ía","-ías","-ía","-íamos","-íais","-ían"])],
                exampleVerbs: ["hablar", "comer", "vivir"])
        case .subjuntivo:
            return TenseInfo(tense: tense,
                usage: "Expresses wishes, doubt, emotion, and requests. -ar verbs take -e endings; -er/-ir take -a endings (the 'opposite vowel').",
                endings: [(.ar, ["-e","-es","-e","-emos","-éis","-en"]),
                          (.er, ["-a","-as","-a","-amos","-áis","-an"]),
                          (.ir, ["-a","-as","-a","-amos","-áis","-an"])],
                exampleVerbs: ["hablar", "comer", "vivir"])
        case .present:
            return TenseInfo(tense: tense,
                usage: "Describes current and habitual actions. -ir verbs of the finir type add -iss- in the plural.",
                endings: [(.er, ["-e","-es","-e","-ons","-ez","-ent"]),
                          (.ir, ["-is","-is","-it","-issons","-issez","-issent"]),
                          (.re, ["-s","-s","—","-ons","-ez","-ent"])],
                exampleVerbs: ["parler", "finir", "vendre"])
        case .imparfait:
            return TenseInfo(tense: tense,
                usage: "The ongoing/background past ('was -ing', 'used to'). All groups share one set of endings on the nous-stem.",
                endings: [(.er, ["-ais","-ais","-ait","-ions","-iez","-aient"]),
                          (.ir, ["-issais","-issais","-issait","-issions","-issiez","-issaient"]),
                          (.re, ["-ais","-ais","-ait","-ions","-iez","-aient"])],
                exampleVerbs: ["parler", "finir", "vendre"])
        case .futur:
            return TenseInfo(tense: tense,
                usage: "Future actions ('will'). Endings attach to the infinitive; -re verbs drop the final -e first.",
                endings: [(.er, ["-ai","-as","-a","-ons","-ez","-ont"]),
                          (.ir, ["-ai","-as","-a","-ons","-ez","-ont"]),
                          (.re, ["-ai","-as","-a","-ons","-ez","-ont"])],
                exampleVerbs: ["parler", "finir", "vendre"])
        case .passeCompose:
            return TenseInfo(tense: tense,
                usage: "The everyday past = present of avoir (or être) + past participle. -er → -é, -ir → -i, -re → -u. A handful of motion/state verbs use être and agree with the subject.",
                endings: [(.er, ["ai + -é","as + -é","a + -é","avons + -é","avez + -é","ont + -é"]),
                          (.ir, ["ai + -i","as + -i","a + -i","avons + -i","avez + -i","ont + -i"]),
                          (.re, ["ai + -u","as + -u","a + -u","avons + -u","avez + -u","ont + -u"])],
                exampleVerbs: ["parler", "finir", "vendre"])
        }
    }
}

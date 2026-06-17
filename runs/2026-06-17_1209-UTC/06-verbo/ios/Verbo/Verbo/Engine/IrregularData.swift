import Foundation

/// Lookup-override table for the most common irregular verbs.
/// Each entry maps a tense to a 6-element array of forms in slot order
/// [0:yo/je, 1:tú/tu, 2:él/il, 3:nosotros/nous, 4:vosotros/vous, 5:ellos/ils].
///
/// For Spanish, only the simple-tense forms are stored.
/// For French, the simple tenses are stored and `passeCompose` is built from
/// the past participle (see `frenchPastParticiple`) + auxiliary in the engine.
enum IrregularData {

    /// key: "<language>-<infinitive>"  ->  [tenseRawValue: [6 forms]]
    static func forms(for infinitive: String, language: Language) -> [String: [String]]? {
        let key = "\(language.rawValue)-\(infinitive.lowercased())"
        switch language {
        case .spanish: return spanish[key]
        case .french: return french[key]
        }
    }

    /// French past participle override for compound tenses, if irregular.
    static func frenchPastParticiple(_ infinitive: String) -> String? {
        frenchParticiples[infinitive.lowercased()]
    }

    // MARK: - Spanish irregulars

    private static let spanish: [String: [String: [String]]] = {
        var t: [String: [String: [String]]] = [:]

        t["spanish-ser"] = [
            "presente":   ["soy", "eres", "es", "somos", "sois", "son"],
            "preterito":  ["fui", "fuiste", "fue", "fuimos", "fuisteis", "fueron"],
            "imperfecto": ["era", "eras", "era", "éramos", "erais", "eran"],
            "futuro":     ["seré", "serás", "será", "seremos", "seréis", "serán"],
            "condicional":["sería", "serías", "sería", "seríamos", "seríais", "serían"],
            "subjuntivo": ["sea", "seas", "sea", "seamos", "seáis", "sean"],
        ]
        t["spanish-estar"] = [
            "presente":   ["estoy", "estás", "está", "estamos", "estáis", "están"],
            "preterito":  ["estuve", "estuviste", "estuvo", "estuvimos", "estuvisteis", "estuvieron"],
            "imperfecto": ["estaba", "estabas", "estaba", "estábamos", "estabais", "estaban"],
            "futuro":     ["estaré", "estarás", "estará", "estaremos", "estaréis", "estarán"],
            "condicional":["estaría", "estarías", "estaría", "estaríamos", "estaríais", "estarían"],
            "subjuntivo": ["esté", "estés", "esté", "estemos", "estéis", "estén"],
        ]
        t["spanish-ir"] = [
            "presente":   ["voy", "vas", "va", "vamos", "vais", "van"],
            "preterito":  ["fui", "fuiste", "fue", "fuimos", "fuisteis", "fueron"],
            "imperfecto": ["iba", "ibas", "iba", "íbamos", "ibais", "iban"],
            "futuro":     ["iré", "irás", "irá", "iremos", "iréis", "irán"],
            "condicional":["iría", "irías", "iría", "iríamos", "iríais", "irían"],
            "subjuntivo": ["vaya", "vayas", "vaya", "vayamos", "vayáis", "vayan"],
        ]
        t["spanish-haber"] = [
            "presente":   ["he", "has", "ha", "hemos", "habéis", "han"],
            "preterito":  ["hube", "hubiste", "hubo", "hubimos", "hubisteis", "hubieron"],
            "imperfecto": ["había", "habías", "había", "habíamos", "habíais", "habían"],
            "futuro":     ["habré", "habrás", "habrá", "habremos", "habréis", "habrán"],
            "condicional":["habría", "habrías", "habría", "habríamos", "habríais", "habrían"],
            "subjuntivo": ["haya", "hayas", "haya", "hayamos", "hayáis", "hayan"],
        ]
        t["spanish-tener"] = [
            "presente":   ["tengo", "tienes", "tiene", "tenemos", "tenéis", "tienen"],
            "preterito":  ["tuve", "tuviste", "tuvo", "tuvimos", "tuvisteis", "tuvieron"],
            "imperfecto": ["tenía", "tenías", "tenía", "teníamos", "teníais", "tenían"],
            "futuro":     ["tendré", "tendrás", "tendrá", "tendremos", "tendréis", "tendrán"],
            "condicional":["tendría", "tendrías", "tendría", "tendríamos", "tendríais", "tendrían"],
            "subjuntivo": ["tenga", "tengas", "tenga", "tengamos", "tengáis", "tengan"],
        ]
        t["spanish-hacer"] = [
            "presente":   ["hago", "haces", "hace", "hacemos", "hacéis", "hacen"],
            "preterito":  ["hice", "hiciste", "hizo", "hicimos", "hicisteis", "hicieron"],
            "imperfecto": ["hacía", "hacías", "hacía", "hacíamos", "hacíais", "hacían"],
            "futuro":     ["haré", "harás", "hará", "haremos", "haréis", "harán"],
            "condicional":["haría", "harías", "haría", "haríamos", "haríais", "harían"],
            "subjuntivo": ["haga", "hagas", "haga", "hagamos", "hagáis", "hagan"],
        ]
        t["spanish-poder"] = [
            "presente":   ["puedo", "puedes", "puede", "podemos", "podéis", "pueden"],
            "preterito":  ["pude", "pudiste", "pudo", "pudimos", "pudisteis", "pudieron"],
            "imperfecto": ["podía", "podías", "podía", "podíamos", "podíais", "podían"],
            "futuro":     ["podré", "podrás", "podrá", "podremos", "podréis", "podrán"],
            "condicional":["podría", "podrías", "podría", "podríamos", "podríais", "podrían"],
            "subjuntivo": ["pueda", "puedas", "pueda", "podamos", "podáis", "puedan"],
        ]
        t["spanish-decir"] = [
            "presente":   ["digo", "dices", "dice", "decimos", "decís", "dicen"],
            "preterito":  ["dije", "dijiste", "dijo", "dijimos", "dijisteis", "dijeron"],
            "imperfecto": ["decía", "decías", "decía", "decíamos", "decíais", "decían"],
            "futuro":     ["diré", "dirás", "dirá", "diremos", "diréis", "dirán"],
            "condicional":["diría", "dirías", "diría", "diríamos", "diríais", "dirían"],
            "subjuntivo": ["diga", "digas", "diga", "digamos", "digáis", "digan"],
        ]
        t["spanish-ver"] = [
            "presente":   ["veo", "ves", "ve", "vemos", "veis", "ven"],
            "preterito":  ["vi", "viste", "vio", "vimos", "visteis", "vieron"],
            "imperfecto": ["veía", "veías", "veía", "veíamos", "veíais", "veían"],
            "futuro":     ["veré", "verás", "verá", "veremos", "veréis", "verán"],
            "condicional":["vería", "verías", "vería", "veríamos", "veríais", "verían"],
            "subjuntivo": ["vea", "veas", "vea", "veamos", "veáis", "vean"],
        ]
        t["spanish-dar"] = [
            "presente":   ["doy", "das", "da", "damos", "dais", "dan"],
            "preterito":  ["di", "diste", "dio", "dimos", "disteis", "dieron"],
            "imperfecto": ["daba", "dabas", "daba", "dábamos", "dabais", "daban"],
            "futuro":     ["daré", "darás", "dará", "daremos", "daréis", "darán"],
            "condicional":["daría", "darías", "daría", "daríamos", "daríais", "darían"],
            "subjuntivo": ["dé", "des", "dé", "demos", "deis", "den"],
        ]
        t["spanish-saber"] = [
            "presente":   ["sé", "sabes", "sabe", "sabemos", "sabéis", "saben"],
            "preterito":  ["supe", "supiste", "supo", "supimos", "supisteis", "supieron"],
            "imperfecto": ["sabía", "sabías", "sabía", "sabíamos", "sabíais", "sabían"],
            "futuro":     ["sabré", "sabrás", "sabrá", "sabremos", "sabréis", "sabrán"],
            "condicional":["sabría", "sabrías", "sabría", "sabríamos", "sabríais", "sabrían"],
            "subjuntivo": ["sepa", "sepas", "sepa", "sepamos", "sepáis", "sepan"],
        ]
        t["spanish-querer"] = [
            "presente":   ["quiero", "quieres", "quiere", "queremos", "queréis", "quieren"],
            "preterito":  ["quise", "quisiste", "quiso", "quisimos", "quisisteis", "quisieron"],
            "imperfecto": ["quería", "querías", "quería", "queríamos", "queríais", "querían"],
            "futuro":     ["querré", "querrás", "querrá", "querremos", "querréis", "querrán"],
            "condicional":["querría", "querrías", "querría", "querríamos", "querríais", "querrían"],
            "subjuntivo": ["quiera", "quieras", "quiera", "queramos", "queráis", "quieran"],
        ]
        t["spanish-poner"] = [
            "presente":   ["pongo", "pones", "pone", "ponemos", "ponéis", "ponen"],
            "preterito":  ["puse", "pusiste", "puso", "pusimos", "pusisteis", "pusieron"],
            "imperfecto": ["ponía", "ponías", "ponía", "poníamos", "poníais", "ponían"],
            "futuro":     ["pondré", "pondrás", "pondrá", "pondremos", "pondréis", "pondrán"],
            "condicional":["pondría", "pondrías", "pondría", "pondríamos", "pondríais", "pondrían"],
            "subjuntivo": ["ponga", "pongas", "ponga", "pongamos", "pongáis", "pongan"],
        ]
        t["spanish-venir"] = [
            "presente":   ["vengo", "vienes", "viene", "venimos", "venís", "vienen"],
            "preterito":  ["vine", "viniste", "vino", "vinimos", "vinisteis", "vinieron"],
            "imperfecto": ["venía", "venías", "venía", "veníamos", "veníais", "venían"],
            "futuro":     ["vendré", "vendrás", "vendrá", "vendremos", "vendréis", "vendrán"],
            "condicional":["vendría", "vendrías", "vendría", "vendríamos", "vendríais", "vendrían"],
            "subjuntivo": ["venga", "vengas", "venga", "vengamos", "vengáis", "vengan"],
        ]
        return t
    }()

    // MARK: - French irregulars (simple tenses)

    private static let french: [String: [String: [String]]] = {
        var t: [String: [String: [String]]] = [:]

        t["french-être"] = [
            "present":   ["suis", "es", "est", "sommes", "êtes", "sont"],
            "imparfait": ["étais", "étais", "était", "étions", "étiez", "étaient"],
            "futur":     ["serai", "seras", "sera", "serons", "serez", "seront"],
        ]
        t["french-avoir"] = [
            "present":   ["ai", "as", "a", "avons", "avez", "ont"],
            "imparfait": ["avais", "avais", "avait", "avions", "aviez", "avaient"],
            "futur":     ["aurai", "auras", "aura", "aurons", "aurez", "auront"],
        ]
        t["french-aller"] = [
            "present":   ["vais", "vas", "va", "allons", "allez", "vont"],
            "imparfait": ["allais", "allais", "allait", "allions", "alliez", "allaient"],
            "futur":     ["irai", "iras", "ira", "irons", "irez", "iront"],
        ]
        t["french-faire"] = [
            "present":   ["fais", "fais", "fait", "faisons", "faites", "font"],
            "imparfait": ["faisais", "faisais", "faisait", "faisions", "faisiez", "faisaient"],
            "futur":     ["ferai", "feras", "fera", "ferons", "ferez", "feront"],
        ]
        t["french-pouvoir"] = [
            "present":   ["peux", "peux", "peut", "pouvons", "pouvez", "peuvent"],
            "imparfait": ["pouvais", "pouvais", "pouvait", "pouvions", "pouviez", "pouvaient"],
            "futur":     ["pourrai", "pourras", "pourra", "pourrons", "pourrez", "pourront"],
        ]
        t["french-vouloir"] = [
            "present":   ["veux", "veux", "veut", "voulons", "voulez", "veulent"],
            "imparfait": ["voulais", "voulais", "voulait", "voulions", "vouliez", "voulaient"],
            "futur":     ["voudrai", "voudras", "voudra", "voudrons", "voudrez", "voudront"],
        ]
        t["french-devoir"] = [
            "present":   ["dois", "dois", "doit", "devons", "devez", "doivent"],
            "imparfait": ["devais", "devais", "devait", "devions", "deviez", "devaient"],
            "futur":     ["devrai", "devras", "devra", "devrons", "devrez", "devront"],
        ]
        t["french-prendre"] = [
            "present":   ["prends", "prends", "prend", "prenons", "prenez", "prennent"],
            "imparfait": ["prenais", "prenais", "prenait", "prenions", "preniez", "prenaient"],
            "futur":     ["prendrai", "prendras", "prendra", "prendrons", "prendrez", "prendront"],
        ]
        t["french-voir"] = [
            "present":   ["vois", "vois", "voit", "voyons", "voyez", "voient"],
            "imparfait": ["voyais", "voyais", "voyait", "voyions", "voyiez", "voyaient"],
            "futur":     ["verrai", "verras", "verra", "verrons", "verrez", "verront"],
        ]
        t["french-savoir"] = [
            "present":   ["sais", "sais", "sait", "savons", "savez", "savent"],
            "imparfait": ["savais", "savais", "savait", "savions", "saviez", "savaient"],
            "futur":     ["saurai", "sauras", "saura", "saurons", "saurez", "sauront"],
        ]
        t["french-venir"] = [
            "present":   ["viens", "viens", "vient", "venons", "venez", "viennent"],
            "imparfait": ["venais", "venais", "venait", "venions", "veniez", "venaient"],
            "futur":     ["viendrai", "viendras", "viendra", "viendrons", "viendrez", "viendront"],
        ]
        t["french-dire"] = [
            "present":   ["dis", "dis", "dit", "disons", "dites", "disent"],
            "imparfait": ["disais", "disais", "disait", "disions", "disiez", "disaient"],
            "futur":     ["dirai", "diras", "dira", "dirons", "direz", "diront"],
        ]
        return t
    }()

    /// Irregular French past participles for compound tenses.
    private static let frenchParticiples: [String: String] = [
        "être": "été",
        "avoir": "eu",
        "aller": "allé",
        "faire": "fait",
        "pouvoir": "pu",
        "vouloir": "voulu",
        "devoir": "dû",
        "prendre": "pris",
        "voir": "vu",
        "savoir": "su",
        "venir": "venu",
        "dire": "dit",
    ]
}

import Foundation

enum NameGender: String, CaseIterable, Codable, Identifiable {
    case girl, boy, neutral
    var id: String { rawValue }
    var label: String {
        switch self {
        case .girl: return "Girl"
        case .boy: return "Boy"
        case .neutral: return "Neutral"
        }
    }
}

enum NameStyle: String, CaseIterable, Codable, Identifiable {
    case classic, modern, vintage, nature, international, mythic, short
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}

/// A candidate name. Static catalog content — verdicts are persisted separately.
struct NameCard: Identifiable, Hashable {
    let name: String
    let gender: NameGender
    let origin: String
    let meaning: String
    let styles: [NameStyle]

    var id: String { name + "·" + gender.rawValue }
}

enum NameCatalog {
    /// Compact builder: (name, gender, origin, meaning, styles).
    private static func n(_ name: String, _ g: NameGender, _ origin: String,
                          _ meaning: String, _ styles: [NameStyle]) -> NameCard {
        NameCard(name: name, gender: g, origin: origin, meaning: meaning, styles: styles)
    }

    static let all: [NameCard] = [
        // ---- Girls ----
        n("Amelia", .girl, "Germanic", "industrious, striving", [.classic]),
        n("Aurora", .girl, "Latin", "dawn; goddess of morning", [.mythic, .nature]),
        n("Hazel", .girl, "English", "the hazel tree", [.vintage, .nature]),
        n("Ivy", .girl, "English", "the ivy plant; fidelity", [.nature, .short]),
        n("Luna", .girl, "Latin", "the moon", [.mythic, .short, .modern]),
        n("Clara", .girl, "Latin", "bright, clear", [.classic, .vintage]),
        n("Eleanor", .girl, "French", "shining light", [.classic]),
        n("Maeve", .girl, "Irish", "she who intoxicates; a warrior queen", [.mythic, .short, .international]),
        n("Nora", .girl, "Irish", "light, honor", [.vintage, .short]),
        n("Wren", .girl, "English", "small songbird", [.nature, .short, .modern]),
        n("Violet", .girl, "Latin", "the purple flower", [.vintage, .nature]),
        n("Iris", .girl, "Greek", "rainbow; messenger goddess", [.mythic, .nature, .short]),
        n("Freya", .girl, "Norse", "noble lady; goddess of love", [.mythic, .international]),
        n("Ada", .girl, "Germanic", "noble; first programmer's name", [.vintage, .short]),
        n("Beatrice", .girl, "Latin", "she who brings happiness", [.classic, .vintage]),
        n("Cora", .girl, "Greek", "maiden", [.vintage, .short]),
        n("Daphne", .girl, "Greek", "laurel tree; pursued nymph", [.mythic, .nature]),
        n("Elodie", .girl, "French", "foreign riches; a melody", [.international, .modern]),
        n("Flora", .girl, "Latin", "flower; goddess of spring", [.mythic, .nature, .vintage]),
        n("Greta", .girl, "German", "pearl", [.vintage, .international]),
        n("Helena", .girl, "Greek", "shining light", [.classic, .international]),
        n("Ines", .girl, "Spanish", "pure, holy", [.international, .short]),
        n("Juniper", .girl, "Latin", "the evergreen shrub", [.nature, .modern]),
        n("Lila", .girl, "Arabic", "night; play, divine drama", [.short, .international]),
        n("Margot", .girl, "French", "pearl", [.vintage, .international]),
        n("Matilda", .girl, "Germanic", "mighty in battle", [.vintage, .classic]),
        n("Ophelia", .girl, "Greek", "help; Shakespeare's tragic heroine", [.mythic, .vintage]),
        n("Penelope", .girl, "Greek", "weaver; faithful wife of Odysseus", [.mythic, .classic]),
        n("Rosa", .girl, "Latin", "rose", [.classic, .nature, .international, .short]),
        n("Sylvie", .girl, "French", "from the forest", [.nature, .international, .vintage]),
        n("Thea", .girl, "Greek", "goddess; gift of god", [.mythic, .short, .modern]),
        n("Una", .girl, "Irish", "lamb; the one", [.short, .international, .vintage]),
        n("Vera", .girl, "Russian", "faith; truth", [.vintage, .short, .international]),
        n("Willa", .girl, "Germanic", "resolute protection", [.vintage, .modern]),
        n("Zara", .girl, "Arabic", "blooming flower; radiance", [.modern, .short, .international]),
        n("Alice", .girl, "Germanic", "noble; of the wonderland", [.classic, .vintage]),
        n("Camille", .girl, "French", "young ceremonial attendant", [.classic, .international]),
        n("Esme", .girl, "French", "esteemed, beloved", [.short, .vintage, .international]),
        n("Genevieve", .girl, "French", "woman of the family; patron of Paris", [.classic, .vintage]),
        n("Imogen", .girl, "Celtic", "maiden, innocent", [.vintage, .international]),
        n("Josephine", .girl, "Hebrew", "God will increase", [.classic, .vintage]),
        n("Lucia", .girl, "Latin", "light", [.classic, .international]),
        n("Mira", .girl, "Sanskrit", "ocean, wonder; prosperous", [.short, .modern, .international]),
        n("Noa", .girl, "Hebrew", "motion, movement", [.short, .modern, .international]),
        n("Anouk", .girl, "Dutch", "grace", [.international, .short, .modern]),
        n("Saoirse", .girl, "Irish", "freedom, liberty", [.international, .mythic]),
        n("Astrid", .girl, "Norse", "divinely beautiful", [.international, .mythic]),
        n("Leonie", .girl, "Latin", "lioness", [.international, .vintage]),
        n("Paloma", .girl, "Spanish", "dove; peace", [.international, .nature]),
        n("Sage", .girl, "Latin", "wise; the herb", [.nature, .short, .modern]),
        n("Marlowe", .girl, "English", "driftwood; remnants of a lake", [.modern]),
        n("Isla", .girl, "Scottish", "island", [.modern, .short, .nature]),
        n("Eden", .girl, "Hebrew", "delight; paradise garden", [.nature, .short, .modern]),
        n("Celine", .girl, "French", "heavenly", [.international, .modern]),
        n("Dahlia", .girl, "Scandinavian", "Dahl's flower; valley dweller", [.nature, .vintage]),
        n("Echo", .girl, "Greek", "reflected sound; nymph of the mountains", [.mythic, .short, .modern]),
        n("Faye", .girl, "English", "fairy; loyalty", [.short, .vintage, .mythic]),
        n("Gaia", .girl, "Greek", "the earth mother", [.mythic, .nature, .short]),
        n("Harriet", .girl, "Germanic", "home ruler", [.vintage, .classic]),
        n("Indira", .girl, "Sanskrit", "beauty; goddess of prosperity", [.international, .mythic]),
        n("June", .girl, "Latin", "young; the month of the goddess Juno", [.vintage, .short, .nature]),
        n("Kaia", .girl, "Hawaiian", "the sea", [.modern, .nature, .short]),
        n("Lyra", .girl, "Greek", "the lyre; a northern constellation", [.mythic, .modern, .short]),
        n("Maren", .girl, "Latin", "of the sea", [.international, .modern, .nature]),
        n("Niamh", .girl, "Irish", "bright, radiant", [.international, .mythic]),
        n("Odette", .girl, "French", "wealthy; the swan queen", [.vintage, .international]),
        n("Pearl", .girl, "Latin", "the gem of the sea", [.vintage, .nature, .short]),
        n("Quinn", .girl, "Irish", "descendant of the wise one", [.modern, .short]),
        n("Ramona", .girl, "Spanish", "wise protector", [.vintage, .international]),
        n("Seren", .girl, "Welsh", "star", [.international, .nature, .short]),
        n("Tilda", .girl, "Germanic", "mighty in battle", [.vintage, .short, .international]),
        n("Ursa", .girl, "Latin", "little bear; the northern constellation", [.mythic, .short]),
        n("Vivienne", .girl, "Latin", "alive, lively", [.classic, .international]),
        n("Winona", .girl, "Dakota", "firstborn daughter", [.international, .vintage]),
        n("Xiomara", .girl, "Spanish", "ready for battle", [.international]),
        n("Yara", .girl, "Arabic", "small butterfly; water lady", [.international, .short, .mythic]),
        n("Zelda", .girl, "Yiddish", "blessed, happy", [.vintage, .mythic]),
        n("Opal", .girl, "Sanskrit", "jewel", [.vintage, .nature, .short]),
        n("Romy", .girl, "Latin", "rosemary; dew of the sea", [.short, .modern, .international]),
        n("Cleo", .girl, "Greek", "glory, fame", [.vintage, .short, .mythic]),
        n("Billie", .girl, "Germanic", "resolute protector", [.modern, .vintage]),
        n("Goldie", .girl, "English", "made of gold", [.vintage]),
        n("Frances", .girl, "Latin", "free woman; from France", [.classic, .vintage]),
        n("Agnes", .girl, "Greek", "pure, holy", [.vintage, .classic]),
        n("Blythe", .girl, "English", "free spirit; happy", [.vintage, .short]),
        n("Calla", .girl, "Greek", "beautiful; the lily", [.nature, .short]),
        n("Delphine", .girl, "Greek", "of Delphi; the dolphin", [.international, .mythic]),
        n("Edith", .girl, "English", "prosperous in war", [.vintage, .classic]),
        n("Fern", .girl, "English", "the green woodland plant", [.nature, .short, .vintage]),
        n("Gwen", .girl, "Welsh", "white circle; blessed", [.short, .international]),
        n("Honor", .girl, "Latin", "dignity, reputation", [.modern, .classic]),
        n("Petra", .girl, "Greek", "rock, stone", [.international, .mythic]),
        n("Salome", .girl, "Hebrew", "peace", [.international, .mythic]),
        n("Tamsin", .girl, "English", "twin", [.international, .vintage]),
        // ---- Boys ----
        n("Arthur", .boy, "Celtic", "bear; the once and future king", [.classic, .mythic]),
        n("Atlas", .boy, "Greek", "to carry; the titan who bore the sky", [.mythic, .modern]),
        n("August", .boy, "Latin", "great, venerable", [.vintage, .classic]),
        n("Felix", .boy, "Latin", "happy, fortunate", [.classic, .international, .short]),
        n("Hugo", .boy, "Germanic", "mind, intellect", [.classic, .international, .short]),
        n("Jasper", .boy, "Persian", "treasurer; the spotted stone", [.vintage, .nature]),
        n("Leo", .boy, "Latin", "lion", [.classic, .short]),
        n("Milo", .boy, "Germanic", "merciful; soldier", [.modern, .short]),
        n("Oscar", .boy, "Irish", "deer friend; spear of the gods", [.classic, .vintage]),
        n("Theodore", .boy, "Greek", "gift of God", [.classic]),
        n("Silas", .boy, "Latin", "of the forest", [.vintage, .nature]),
        n("Ezra", .boy, "Hebrew", "helper", [.vintage, .short, .modern]),
        n("Finn", .boy, "Irish", "fair; the legendary hunter-warrior", [.mythic, .short, .modern]),
        n("Henry", .boy, "Germanic", "home ruler", [.classic]),
        n("Ivo", .boy, "Germanic", "yew wood; archer's bow", [.short, .international]),
        n("Jude", .boy, "Hebrew", "praised", [.short, .modern, .classic]),
        n("Kai", .boy, "Hawaiian", "the sea", [.short, .modern, .nature, .international]),
        n("Lucian", .boy, "Latin", "light", [.classic, .international]),
        n("Magnus", .boy, "Latin", "great", [.mythic, .international, .classic]),
        n("Nico", .boy, "Greek", "victory of the people", [.short, .modern, .international]),
        n("Orion", .boy, "Greek", "the hunter constellation", [.mythic, .nature, .modern]),
        n("Pax", .boy, "Latin", "peace", [.short, .mythic, .modern]),
        n("Quentin", .boy, "Latin", "the fifth", [.classic, .international]),
        n("Rowan", .boy, "Irish", "little red one; the rowan tree", [.nature, .modern]),
        n("Sebastian", .boy, "Greek", "venerable, revered", [.classic, .international]),
        n("Tobias", .boy, "Hebrew", "God is good", [.classic, .vintage, .international]),
        n("Ulysses", .boy, "Latin", "wrathful; the wanderer of the Odyssey", [.mythic, .vintage]),
        n("Victor", .boy, "Latin", "conqueror", [.classic, .vintage]),
        n("Walter", .boy, "Germanic", "ruler of the army", [.vintage, .classic]),
        n("Xavier", .boy, "Basque", "new house; bright", [.classic, .international]),
        n("Yusuf", .boy, "Arabic", "God will increase", [.international, .classic]),
        n("Zane", .boy, "Hebrew", "gift of God", [.short, .modern]),
        n("Alistair", .boy, "Scottish", "defender of the people", [.classic, .international]),
        n("Bram", .boy, "Dutch", "father of multitudes; the raven", [.short, .international, .vintage]),
        n("Caspian", .boy, "Latin", "of the sea between Europe and Asia", [.mythic, .nature, .modern]),
        n("Darius", .boy, "Persian", "possessing goodness; great kings of Persia", [.mythic, .international, .classic]),
        n("Edmund", .boy, "English", "fortunate protector", [.classic, .vintage]),
        n("Fox", .boy, "English", "the cunning animal", [.nature, .short, .modern]),
        n("Gideon", .boy, "Hebrew", "mighty warrior; feller of trees", [.classic, .mythic]),
        n("Hawthorne", .boy, "English", "the flowering thorn tree", [.nature, .vintage]),
        n("Idris", .boy, "Welsh", "ardent lord; studious", [.international, .mythic, .short]),
        n("Jonas", .boy, "Hebrew", "dove", [.classic, .international]),
        n("Koa", .boy, "Hawaiian", "warrior; the acacia tree", [.short, .nature, .international]),
        n("Lachlan", .boy, "Scottish", "from the land of lakes", [.international, .modern]),
        n("Marcel", .boy, "French", "young warrior; of Mars", [.vintage, .international]),
        n("Nathaniel", .boy, "Hebrew", "gift of God", [.classic]),
        n("Otis", .boy, "Germanic", "wealthy", [.vintage, .short]),
        n("Phineas", .boy, "Hebrew", "oracle; serpent's mouth", [.vintage, .mythic]),
        n("Rafael", .boy, "Hebrew", "God has healed", [.classic, .international]),
        n("Soren", .boy, "Danish", "stern; thunder god's name softened", [.international, .modern]),
        n("Theo", .boy, "Greek", "god; divine gift", [.short, .modern, .classic]),
        n("Emrys", .boy, "Welsh", "immortal; Merlin's true name", [.mythic, .international]),
        n("Wilder", .boy, "English", "untamed; hunter", [.modern, .nature]),
        n("York", .boy, "English", "yew tree settlement", [.short, .vintage]),
        n("Zeno", .boy, "Greek", "gift of Zeus; the paradox philosopher", [.mythic, .short, .international]),
        n("Ander", .boy, "Basque", "manly, brave", [.short, .international, .modern]),
        n("Bear", .boy, "English", "the animal; strength", [.nature, .short, .modern]),
        n("Cyrus", .boy, "Persian", "sun; founder of an empire", [.mythic, .classic, .international]),
        n("Dashiell", .boy, "French", "page boy; the detective novelist", [.modern, .vintage]),
        n("Elio", .boy, "Italian", "sun", [.short, .international, .modern, .mythic]),
        n("Fitzgerald", .boy, "Irish", "son of the spear-ruler", [.vintage, .classic]),
        n("Grover", .boy, "English", "lives near a grove", [.vintage, .nature]),
        n("Hollis", .boy, "English", "dweller by the holly trees", [.vintage, .nature]),
        n("Ignatius", .boy, "Latin", "fiery one", [.classic, .mythic, .vintage]),
        n("Jericho", .boy, "Arabic", "city of the moon", [.mythic, .modern]),
        n("Keats", .boy, "English", "kite; the romantic poet", [.short, .vintage, .modern]),
        n("Laszlo", .boy, "Hungarian", "glorious ruler", [.international, .vintage]),
        n("Mercer", .boy, "French", "merchant of fine cloth", [.modern, .vintage]),
        n("Nile", .boy, "Greek", "the great river", [.nature, .short, .mythic]),
        n("Obadiah", .boy, "Hebrew", "servant of God", [.vintage, .classic]),
        n("Peregrine", .boy, "Latin", "traveler, pilgrim; the falcon", [.mythic, .nature, .vintage]),
        n("Ronan", .boy, "Irish", "little seal", [.international, .modern, .nature]),
        n("Stellan", .boy, "Swedish", "calm, peaceful", [.international, .modern]),
        n("Vaughn", .boy, "Welsh", "small", [.short, .vintage]),
        n("Wells", .boy, "English", "spring, stream", [.nature, .short, .modern]),
        n("Apollo", .boy, "Greek", "god of light, music and poetry", [.mythic, .modern]),
        n("Booker", .boy, "English", "scribe; maker of books", [.vintage, .modern]),
        n("Clement", .boy, "Latin", "mild, merciful", [.classic, .vintage]),
        n("Duke", .boy, "Latin", "leader", [.short, .vintage, .modern]),
        n("Everett", .boy, "English", "brave as a wild boar", [.classic, .modern]),
        n("Florian", .boy, "Latin", "flowering, blossoming", [.international, .nature, .vintage]),
        n("Gus", .boy, "Latin", "great, venerable", [.short, .vintage]),
        n("Hamish", .boy, "Scottish", "supplanter", [.international, .vintage]),
        n("Iker", .boy, "Basque", "visitation", [.short, .international, .modern]),
        n("Joaquin", .boy, "Spanish", "lifted by God", [.international, .classic]),
        n("Knox", .boy, "Scottish", "round hill", [.short, .modern]),
        n("Lionel", .boy, "Latin", "young lion", [.vintage, .classic]),
        n("Matteo", .boy, "Italian", "gift of God", [.international, .modern]),
        // ---- Neutral ----
        n("River", .neutral, "English", "flowing water", [.nature, .modern]),
        n("Sky", .neutral, "Norse", "the heavens; cloud", [.nature, .short, .modern]),
        n("Rory", .neutral, "Irish", "red king", [.short, .international, .modern]),
        n("Ellis", .neutral, "Welsh", "benevolent; kind", [.modern, .vintage]),
        n("Avery", .neutral, "English", "ruler of the elves", [.modern]),
        n("Briar", .neutral, "English", "thorny rose bush", [.nature, .modern, .mythic]),
        n("Cedar", .neutral, "English", "the evergreen tree", [.nature, .modern]),
        n("Darcy", .neutral, "French", "from Arcy; dark one", [.vintage, .international]),
        n("Emerson", .neutral, "English", "child of Emery; the philosopher", [.modern, .classic]),
        n("Frankie", .neutral, "Latin", "free one", [.modern, .vintage, .short]),
        n("Gray", .neutral, "English", "the color between", [.short, .modern]),
        n("Halcyon", .neutral, "Greek", "kingfisher; calm days of winter", [.mythic, .nature]),
        n("Indigo", .neutral, "Greek", "the deep blue dye", [.nature, .modern]),
        n("Jules", .neutral, "Latin", "youthful; soft-bearded", [.short, .international, .vintage]),
        n("Lake", .neutral, "English", "still water", [.nature, .short, .modern]),
        n("Marlin", .neutral, "English", "sea fortress; the ocean fish", [.nature, .modern]),
        n("Noor", .neutral, "Arabic", "light", [.short, .international, .modern]),
        n("Oakley", .neutral, "English", "oak meadow", [.nature, .modern]),
        n("Phoenix", .neutral, "Greek", "the bird reborn from ash", [.mythic, .modern]),
        n("Reese", .neutral, "Welsh", "ardor, enthusiasm", [.short, .modern]),
        n("Sasha", .neutral, "Russian", "defender of humankind", [.international, .modern, .short]),
        n("Tatum", .neutral, "English", "cheerful bringer of joy", [.modern, .short]),
        n("Vesper", .neutral, "Latin", "evening star", [.mythic, .modern, .nature]),
        n("Winter", .neutral, "English", "the cold season", [.nature, .modern]),
        n("Arden", .neutral, "English", "valley of the eagle; great forest", [.nature, .modern]),
        n("Blair", .neutral, "Scottish", "plain, field", [.short, .modern]),
        n("Casey", .neutral, "Irish", "vigilant in war", [.modern, .short]),
        n("Devon", .neutral, "English", "the deep valley county", [.modern, .nature]),
        n("Eli", .neutral, "Hebrew", "ascended; my God", [.short, .classic, .modern]),
        n("Flynn", .neutral, "Irish", "descendant of the red-haired one", [.short, .modern]),
        n("Harlow", .neutral, "English", "rocky hill army", [.modern, .vintage]),
        n("Jamie", .neutral, "Hebrew", "supplanter", [.short, .modern]),
        n("Kit", .neutral, "Greek", "bearing Christ; small falcon", [.short, .vintage, .modern]),
        n("Lennox", .neutral, "Scottish", "elm grove", [.modern, .international]),
        n("Marlow", .neutral, "English", "driftwood; lake remnants", [.modern]),
        n("Nova", .neutral, "Latin", "new; an exploding star", [.mythic, .modern, .short]),
        n("Onyx", .neutral, "Greek", "the black gem", [.short, .modern, .nature]),
        n("Palmer", .neutral, "English", "pilgrim bearing palms", [.vintage, .modern]),
        n("Robin", .neutral, "Germanic", "bright fame; the red-breasted bird", [.vintage, .nature]),
        n("Shiloh", .neutral, "Hebrew", "tranquil; place of peace", [.mythic, .modern]),
        n("Tate", .neutral, "Norse", "cheerful", [.short, .modern]),
        n("Wynn", .neutral, "Welsh", "blessed, white, fair", [.short, .vintage, .international]),
    ]

    static func card(forID id: String) -> NameCard? {
        all.first { $0.id == id }
    }

    static func filtered(genders: Set<NameGender>, styles: Set<NameStyle>,
                         initial: String?, maxLength: Int?) -> [NameCard] {
        all.filter { card in
            guard genders.isEmpty || genders.contains(card.gender) else { return false }
            if !styles.isEmpty && !card.styles.contains(where: { styles.contains($0) }) { return false }
            if let initial, !initial.isEmpty,
               !card.name.lowercased().hasPrefix(initial.lowercased()) { return false }
            if let maxLength, card.name.count > maxLength { return false }
            return true
        }
    }
}

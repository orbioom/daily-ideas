import Foundation

enum PuzzleBank {
    static let all: [Puzzle] = buildPuzzles()

    static func puzzle(for id: Int) -> Puzzle {
        all[id % all.count]
    }

    // Daily puzzle: index based on days since a fixed epoch
    static func todayPuzzle() -> Puzzle {
        let epoch = Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let days = Calendar.current.dateComponents([.day], from: epoch, to: Date()).day ?? 0
        return puzzle(for: max(0, days))
    }

    private static func g(_ id: Int, _ diff: Int, _ cat: String, _ w1: String, _ w2: String, _ w3: String, _ w4: String) -> PuzzleGroup {
        PuzzleGroup(id: id, category: cat, difficulty: diff, words: [w1, w2, w3, w4])
    }

    // swiftlint:disable function_body_length
    private static func buildPuzzles() -> [Puzzle] {
        [
        Puzzle(id: 0, groups: [
            g(0,1,"Kitchen tools","SPATULA","WHISK","LADLE","COLANDER"),
            g(1,2,"___ ball","BASKET","FOOT","BASE","VOLLEY"),
            g(2,3,"Shades of blue","COBALT","TEAL","SAPPHIRE","NAVY"),
            g(3,4,"Classic board games","CHESS","CHECKERS","SCRABBLE","CLUE"),
        ]),
        Puzzle(id: 1, groups: [
            g(4,1,"Breakfast staples","WAFFLE","BAGEL","MUFFIN","CREPE"),
            g(5,2,"Things that buzz","BEE","PHONE","ALARM","CROWD"),
            g(6,3,"Famous Williams","GATES","SHAKESPEARE","TELL","WORDSWORTH"),
            g(7,4,"___ book","COOK","NOTE","YEAR","TEXT"),
        ]),
        Puzzle(id: 2, groups: [
            g(8,1,"Pizza toppings","PEPPERONI","MUSHROOM","BASIL","OLIVE"),
            g(9,2,"Types of rain","DRIZZLE","DOWNPOUR","SHOWER","SPRINKLE"),
            g(10,3,"Famous Davids","BOWIE","BECKHAM","ATTENBOROUGH","LETTERMAN"),
            g(11,4,"Words after 'black'","BERRY","BIRD","BOARD","HOLE"),
        ]),
        Puzzle(id: 3, groups: [
            g(12,1,"Big cats","LION","TIGER","CHEETAH","JAGUAR"),
            g(13,2,"Pasta shapes","PENNE","RIGATONI","FUSILLI","ORZO"),
            g(14,3,"___ stone","LIME","COBBLE","SAND","CORNER"),
            g(15,4,"Shakespeare plays","HAMLET","OTHELLO","MACBETH","TEMPEST"),
        ]),
        Puzzle(id: 4, groups: [
            g(16,1,"Ice cream flavors","VANILLA","STRAWBERRY","PISTACHIO","MINT"),
            g(17,2,"Card games","POKER","BRIDGE","SOLITAIRE","SNAP"),
            g(18,3,"Things with rings","SATURN","BOXING","WEDDING","CIRCUS"),
            g(19,4,"___ line","GUIDE","PUNCH","HEAD","DEAD"),
        ]),
        Puzzle(id: 5, groups: [
            g(20,1,"Dog breeds","LABRADOR","BEAGLE","CORGI","POODLE"),
            g(21,2,"Musical genres","JAZZ","REGGAE","BLUEGRASS","DISCO"),
            g(22,3,"Ancient wonders","PYRAMID","COLOSSUS","LIGHTHOUSE","MAUSOLEUM"),
            g(23,4,"___ fall","FREE","NIGHT","DOWN","WATER"),
        ]),
        Puzzle(id: 6, groups: [
            g(24,1,"Ocean creatures","OCTOPUS","JELLYFISH","SEAHORSE","SQUID"),
            g(25,2,"Things you knot","TIE","ROPE","SHOELACE","SCARF"),
            g(26,3,"Famous Alberts","EINSTEIN","CAMUS","PUJOLS","BROOKS"),
            g(27,4,"___ key","DON","MON","DON","TUR"),
        ]),
        Puzzle(id: 7, groups: [
            g(28,1,"Herbs","BASIL","THYME","SAGE","ROSEMARY"),
            g(29,2,"Space objects","COMET","NEBULA","QUASAR","PULSAR"),
            g(30,3,"___ light","FLASH","SPOT","MOON","STAR"),
            g(31,4,"Greek letters","ALPHA","DELTA","SIGMA","OMEGA"),
        ]),
        Puzzle(id: 8, groups: [
            g(32,1,"Yoga poses","COBRA","WARRIOR","DOWNWARD DOG","TREE"),
            g(33,2,"Things that float","CLOUD","BOAT","LEAF","BUBBLE"),
            g(34,3,"Shakespeare heroines","JULIET","OPHELIA","DESDEMONA","PORTIA"),
            g(35,4,"___ bar","CROW","HANDLE","CANDY","MINI"),
        ]),
        Puzzle(id: 9, groups: [
            g(36,1,"Cheese types","BRIE","GOUDA","FETA","GRUYERE"),
            g(37,2,"Palindromes","RACECAR","LEVEL","RADAR","CIVIC"),
            g(38,3,"___ house","LIGHT","TREE","FULL","GREEN"),
            g(39,4,"Constellations","ORION","LYRA","CASSIOPEIA","DRACO"),
        ]),
        Puzzle(id: 10, groups: [
            g(40,1,"Types of music note","WHOLE","HALF","QUARTER","EIGHTH"),
            g(41,2,"Fairy tale characters","CINDERELLA","RAPUNZEL","THUMBELINA","HANSEL"),
            g(42,3,"___ bridge","DRAW","ROPE","STONE","TOLL"),
            g(43,4,"Words that sound like letters","ARE","SEA","WHY","TEE"),
        ]),
        Puzzle(id: 11, groups: [
            g(44,1,"Citrus fruits","LEMON","LIME","GRAPEFRUIT","TANGERINE"),
            g(45,2,"Types of cloud","CIRRUS","CUMULUS","STRATUS","NIMBUS"),
            g(46,3,"___ work","TEAM","FRAME","NET","GROUND"),
            g(47,4,"Dances","WALTZ","TANGO","FOXTROT","POLKA"),
        ]),
        Puzzle(id: 12, groups: [
            g(48,1,"Olympic sports","FENCING","ARCHERY","ROWING","JUDO"),
            g(49,2,"Things with keys","PIANO","KEYBOARD","LOCK","MAP"),
            g(50,3,"___ smith","BLACK","GOLD","SILVER","LOCK"),
            g(51,4,"Logical operators","AND","OR","NOT","XOR"),
        ]),
        Puzzle(id: 13, groups: [
            g(52,1,"Shades of green","EMERALD","JADE","OLIVE","SAGE"),
            g(53,2,"Phobias (what they fear)","ARACHNOPHOBIA","CLAUSTROPHOBIA","ACROPHOBIA","AGORAPHOBIA"),
            g(54,3,"___ point","GUN","BALL","VIEW","STAND"),
            g(55,4,"Anagram of a color","LUBE","GONER","WAITER","PINE"),
        ]),
        Puzzle(id: 14, groups: [
            g(56,1,"Weather phenomena","TORNADO","BLIZZARD","TYPHOON","HAIL"),
            g(57,2,"Roman numerals as words","IVY","MIX","DIX","VIA"),
            g(58,3,"___ man","IRON","SPIDER","SALES","STRAW"),
            g(59,4,"Famous fictional detectives","POIROT","MARPLE","MORSE","COLOMBO"),
        ]),
        Puzzle(id: 15, groups: [
            g(60,1,"Coffee drinks","LATTE","ESPRESSO","CAPPUCCINO","MACCHIATO"),
            g(61,2,"Things in a toolbox","HAMMER","WRENCH","PLIERS","LEVEL"),
            g(62,3,"___ box","SAND","BREAD","TOOL","JACK"),
            g(63,4,"Elements named after planets","URANIUM","NEPTUNIUM","PLUTONIUM","MERCURY"),
        ]),
        Puzzle(id: 16, groups: [
            g(64,1,"Knitting terms","PURL","CAST","YARN","NEEDLE"),
            g(65,2,"Things that can be scrambled","EGG","CODE","SIGNAL","BRAIN"),
            g(66,3,"___ age","STONE","BRONZE","IRON","SPACE"),
            g(67,4,"Bond villains","GOLDFINGER","JAWS","BLOFELD","SILVA"),
        ]),
        Puzzle(id: 17, groups: [
            g(68,1,"Sushi types","NIGIRI","MAKI","TEMAKI","URAMAKI"),
            g(69,2,"Things that can be cast","NET","SPELL","VOTE","SHADOW"),
            g(70,3,"___ run","DRY","HOME","BULL","SKI"),
            g(71,4,"Shades of red","CRIMSON","SCARLET","VERMILLION","CARMINE"),
        ]),
        Puzzle(id: 18, groups: [
            g(72,1,"Parts of a shoe","SOLE","HEEL","TOE","LACE"),
            g(73,2,"Types of energy","SOLAR","KINETIC","NUCLEAR","THERMAL"),
            g(74,3,"___ watch","DOG","NIGHT","STOP","DEATH"),
            g(75,4,"Monopoly properties","BOARDWALK","MARVIN","PARK","VENTNOR"),
        ]),
        Puzzle(id: 19, groups: [
            g(76,1,"Baking ingredients","FLOUR","YEAST","BAKING SODA","VANILLA"),
            g(77,2,"Things with bark","TREE","DOG","BOAT","REDWOOD"),
            g(78,3,"___ eye","BIRD","FISH","BULL","RED"),
            g(79,4,"Famous Elizabeths","WARREN","TAYLOR","BENNET","BLACKWELL"),
        ]),
        Puzzle(id: 20, groups: [
            g(80,1,"Cocktail ingredients","GIN","VERMOUTH","BITTERS","TRIPLE SEC"),
            g(81,2,"Things you press","BUTTON","IRON","FLOWER","SUIT"),
            g(82,3,"___ board","SURF","SKATE","CARD","KEY"),
            g(83,4,"Philosophers","SOCRATES","KANT","NIETZSCHE","HEGEL"),
        ]),
        Puzzle(id: 21, groups: [
            g(84,1,"Types of pasta sauce","BOLOGNESE","PESTO","ALFREDO","MARINARA"),
            g(85,2,"Things that are hollow","BONE","LOG","REED","PROMISE"),
            g(86,3,"___ pool","CAR","DEAD","SWIMMING","ROCK"),
            g(87,4,"Famous Nicoles","KIDMAN","RICHIE","SCHERZINGER","URDANG"),
        ]),
        Puzzle(id: 22, groups: [
            g(88,1,"Gym equipment","BARBELL","TREADMILL","KETTLEBELL","ROWING MACHINE"),
            g(89,2,"Shakespeare insults (first word)","THOU","VILLAINOUS","BOOTLESS","CLAY-BRAINED"),
            g(90,3,"___ play","FAIR","WORD","ROLE","FORE"),
            g(91,4,"Types of hat","FEDORA","BERET","TRILBY","STETSON"),
        ]),
        Puzzle(id: 23, groups: [
            g(92,1,"Things you can fold","PAPER","LAUNDRY","MAP","OMELET"),
            g(93,2,"Ballet terms","PLIE","ARABESQUE","PIROUETTE","JETE"),
            g(94,3,"___ coat","OVER","RAIN","TAIL","SUGAR"),
            g(95,4,"Famous Johns (last name)","LENNON","ADAMS","CLEESE","STEINBECK"),
        ]),
        Puzzle(id: 24, groups: [
            g(96,1,"Spices","CUMIN","TURMERIC","CORIANDER","CARDAMOM"),
            g(97,2,"Things that can be split","BANANA","CHECK","ATOM","VOTE"),
            g(98,3,"___ cap","ICE","HUB","SKULL","KNEE"),
            g(99,4,"Literary genres","GOTHIC","NOIR","PICARESQUE","BILDUNGSROMAN"),
        ]),
        Puzzle(id: 25, groups: [
            g(100,1,"Things in a library","SHELF","CARD CATALOG","STACKS","DEWEY"),
            g(101,2,"Types of sentence","SIMPLE","COMPOUND","COMPLEX","FRAGMENT"),
            g(102,3,"___ stick","CANDLE","LIP","CHOP","DRUM"),
            g(103,4,"Periodic table row 2","LITHIUM","BERYLLIUM","BORON","CARBON"),
        ]),
        Puzzle(id: 26, groups: [
            g(104,1,"Things with wings","BIRD","PLANE","STAGE","BUTTERFLY"),
            g(105,2,"___ bell","DOOR","DUMB","COW","TACO"),
            g(106,3,"Architectural styles","BAROQUE","GOTHIC","BRUTALIST","ART DECO"),
            g(107,4,"Words meaning tired","WEARY","SPENT","KNACKERED","HAGGARD"),
        ]),
        Puzzle(id: 27, groups: [
            g(108,1,"Card suits","HEARTS","CLUBS","DIAMONDS","SPADES"),
            g(109,2,"Things with a face","CLOCK","CLIFF","CARD","COIN"),
            g(110,3,"___ ring","BOXING","WEDDING","EARRING","TEETHING"),
            g(111,4,"Famous Charlies","CHAPLIN","DARWIN","SHEEN","BROWN"),
        ]),
        Puzzle(id: 28, groups: [
            g(112,1,"Types of triangle","EQUILATERAL","ISOSCELES","SCALENE","RIGHT"),
            g(113,2,"Things that can be perfect","PITCH","SCORE","STORM","TIMING"),
            g(114,3,"___ front","COLD","WAR","WATER","HOME"),
            g(115,4,"Words meaning brave","VALIANT","DAUNTLESS","INTREPID","STALWART"),
        ]),
        Puzzle(id: 29, groups: [
            g(116,1,"Jungle animals","JAGUAR","TOUCAN","ANACONDA","TAPIR"),
            g(117,2,"Things you set","TABLE","TRAP","CLOCK","RECORD"),
            g(118,3,"___ ship","FRIEND","HARD","WORK","COURT"),
            g(119,4,"Shades of yellow","AMBER","GOLD","OCHRE","SAFFRON"),
        ]),
        Puzzle(id: 30, groups: [
            g(120,1,"Types of bread","SOURDOUGH","BRIOCHE","CIABATTA","FOCACCIA"),
            g(121,2,"Things that can be tender","HEART","CHICKEN","LEGAL","BENDER"),
            g(122,3,"___ light","FLASH","TRAFFIC","MOON","STAR"),
            g(123,4,"Chess pieces","ROOK","BISHOP","KNIGHT","QUEEN"),
        ]),
        Puzzle(id: 31, groups: [
            g(124,1,"Planets in order (first 4)","MERCURY","VENUS","EARTH","MARS"),
            g(125,2,"Things with a dial","PHONE","RADIO","SAFE","COMPASS"),
            g(126,3,"___ break","JAIL","LUNCH","GROUND","HEART"),
            g(127,4,"Words for fast","SWIFT","FLEET","NIMBLE","BRISK"),
        ]),
        Puzzle(id: 32, groups: [
            g(128,1,"Ancient civilizations","MAYAN","ROMAN","GREEK","SUMERIAN"),
            g(129,2,"Things you can crack","NUT","CODE","JOKE","DAWN"),
            g(130,3,"___ back","GIVE","PAPER","SET","COME"),
            g(131,4,"Fonts / typefaces","GARAMOND","HELVETICA","FUTURA","BODONI"),
        ]),
        Puzzle(id: 33, groups: [
            g(132,1,"Zoo animals","GIRAFFE","ELEPHANT","HIPPO","GORILLA"),
            g(133,2,"Things you can plant","SEED","FLAG","KISS","IDEA"),
            g(134,3,"___ stone","LIME","SAND","EYE","KEY"),
            g(135,4,"Words meaning funny","DROLL","WAGGISH","FACETIOUS","JOCULAR"),
        ]),
        Puzzle(id: 34, groups: [
            g(136,1,"Car parts","ALTERNATOR","CAMSHAFT","RADIATOR","AXLE"),
            g(137,2,"Things with a sole","SHOE","FISH","GUITAR","SOUL"),
            g(138,3,"___ coat","HAIR","OVER","SUGAR","RAIN"),
            g(139,4,"Wonders of the natural world","GRAND CANYON","AMAZON RIVER","AURORA","VICTORIA FALLS"),
        ]),
        Puzzle(id: 35, groups: [
            g(140,1,"Parts of an eye","IRIS","CORNEA","PUPIL","RETINA"),
            g(141,2,"Things that can be plain","CHEESE","TRAIN","FLIGHT","SAILING"),
            g(142,3,"___ bank","RIVER","FOOD","DATA","PIG"),
            g(143,4,"Nobel Prize categories","PEACE","PHYSICS","CHEMISTRY","LITERATURE"),
        ]),
        Puzzle(id: 36, groups: [
            g(144,1,"Types of knife","BOWIE","PARING","BREAD","SWISS ARMY"),
            g(145,2,"Things that can be acute","ANGLE","PAIN","HEARING","AWARENESS"),
            g(146,3,"___ current","UNDER","RIP","DIRECT","CROSS"),
            g(147,4,"Words meaning old","ANCIENT","ARCHAIC","ANTIQUATED","HOARY"),
        ]),
        Puzzle(id: 37, groups: [
            g(148,1,"Superheroes (DC)","BATMAN","SUPERMAN","WONDER WOMAN","GREEN LANTERN"),
            g(149,2,"Things that can be grand","PIANO","JURY","TOTAL","SLAM"),
            g(150,3,"___ ball","SNOW","FIRE","PIN","BASKET"),
            g(151,4,"Languages with accent marks","FRENCH","SPANISH","PORTUGUESE","GERMAN"),
        ]),
        Puzzle(id: 38, groups: [
            g(152,1,"Things in a sushi restaurant","WASABI","GINGER","SOY SAUCE","NORI"),
            g(153,2,"Things you can skip","MEAL","ROPE","STONE","CLASS"),
            g(154,3,"___ turn","U","LEFT","ABOUT","OVER"),
            g(155,4,"Famous Maries","CURIE","ANTOINETTE","KONDO","CALLAS"),
        ]),
        Puzzle(id: 39, groups: [
            g(156,1,"Cooking methods","BRAISE","POACH","SAUTÉ","BROIL"),
            g(157,2,"Things with teeth","COMB","SAW","GEAR","ZIPPER"),
            g(158,3,"___ fire","CAMP","CROSS","OPEN","CEASE"),
            g(159,4,"Words meaning start","COMMENCE","INAUGURATE","INITIATE","EMBARK"),
        ]),
        Puzzle(id: 40, groups: [
            g(160,1,"Musical instruments (string)","CELLO","BANJO","HARP","MANDOLIN"),
            g(161,2,"Things that can be grand","CANYON","TOTAL","FINAL","PRIX"),
            g(162,3,"___ pool","GENE","DEAD","SWIM","ROCK"),
            g(163,4,"Logical fallacies","STRAWMAN","AD HOMINEM","SLIPPERY SLOPE","RED HERRING"),
        ]),
        Puzzle(id: 41, groups: [
            g(164,1,"Island nations","MADAGASCAR","CUBA","ICELAND","TAIWAN"),
            g(165,2,"Things that can be split","INFINITIVE","BANANA","DECISION","HAIR"),
            g(166,3,"___ glass","HOUR","LOOKING","MAGNIFYING","WINE"),
            g(167,4,"Famous Margarets","THATCHER","ATWOOD","MEAD","HAMILTON"),
        ]),
        Puzzle(id: 42, groups: [
            g(168,1,"Things in a bathroom","FAUCET","LOOFAH","PUMICE","GROUT"),
            g(169,2,"Things that can be smooth","JAZZ","OPERATOR","SAILING","CRIMINAL"),
            g(170,3,"___ down","BREAK","MARK","COUNT","STAND"),
            g(171,4,"Oscar Best Picture (2020s)","NOMADLAND","CODA","EVERYTHING","OPPENHEIMER"),
        ]),
        Puzzle(id: 43, groups: [
            g(172,1,"Types of cloud service","STORAGE","COMPUTING","STREAMING","BACKUP"),
            g(173,2,"Things you can run","BATH","BUSINESS","RISK","ERRAND"),
            g(174,3,"___ top","DESK","FLAT","LAP","CROP"),
            g(175,4,"Words meaning empty","VOID","HOLLOW","VACUOUS","BARREN"),
        ]),
        Puzzle(id: 44, groups: [
            g(176,1,"Carnival rides","FERRIS WHEEL","CAROUSEL","ZIPPER","SCRAMBLER"),
            g(177,2,"Things with a shell","EGG","TORTOISE","WALNUT","NUT"),
            g(178,3,"___ drop","EAR","RAIN","NAME","LEMON"),
            g(179,4,"Literary devices","SIMILE","METAPHOR","ALLITERATION","IRONY"),
        ]),
        Puzzle(id: 45, groups: [
            g(180,1,"French words in English","BALLET","BUFFET","CLICHÉ","FIANCÉ"),
            g(181,2,"Things that can be raw","DEAL","POWER","TALENT","NERVE"),
            g(182,3,"___ star","ROCK","POLE","SHOOTING","DEATH"),
            g(183,4,"Philosophers' famous works","REPUBLIC","CRITIQUE","LEVIATHAN","ETHICS"),
        ]),
        Puzzle(id: 46, groups: [
            g(184,1,"Things in a hardware store","CAULK","JOIST","FLASHING","GROUT"),
            g(185,2,"Things that drip","FAUCET","CANDLE","PAINT","SWEAT"),
            g(186,3,"___ line","DEAD","GUIDE","BOTTOM","HAIR"),
            g(187,4,"Words for walk","SAUNTER","AMBLE","STRUT","MEANDER"),
        ]),
        Puzzle(id: 47, groups: [
            g(188,1,"Board game pieces","TOKEN","PAWN","DICE","SPINNER"),
            g(189,2,"Things that can be fair","SKIN","WEATHER","TRADE","GAME"),
            g(190,3,"___ house","LIGHT","GREEN","TOWN","FULL"),
            g(191,4,"Words for laugh","CHORTLE","GUFFAW","TITTER","SNICKER"),
        ]),
        Puzzle(id: 48, groups: [
            g(192,1,"Types of lock","DEADBOLT","PADLOCK","COMBINATION","MORTISE"),
            g(193,2,"Things that can be stiff","COMPETITION","DRINK","BREEZE","UPPER LIP"),
            g(194,3,"___ gate","FLOOD","IRON","WATER","TAIL"),
            g(195,4,"Words meaning shy","BASHFUL","COY","RETICENT","DIFFIDENT"),
        ]),
        Puzzle(id: 49, groups: [
            g(196,1,"Cooking fats","LARD","GHEE","SUET","SHORTENING"),
            g(197,2,"Things that can be wild","CARD","FIRE","FLOWER","GOOSE CHASE"),
            g(198,3,"___ chase","WILD GOOSE","CAR","PUB","FOX"),
            g(199,4,"Architecture terms","BUTTRESS","CLERESTORY","AMBULATORY","NAVE"),
        ]),
        Puzzle(id: 50, groups: [
            g(200,1,"Fabrics","CHIFFON","TAFFETA","GROSGRAIN","JACQUARD"),
            g(201,2,"Things you can tap","PHONE","KEG","SHOULDER","FOOT"),
            g(202,3,"___ scale","SLIDING","RICHTER","FISH","GREY"),
            g(203,4,"Words meaning hard","ARDUOUS","GRUELING","TAXING","PUNISHING"),
        ]),
        Puzzle(id: 51, groups: [
            g(204,1,"Types of government","DEMOCRACY","OLIGARCHY","THEOCRACY","MONARCHY"),
            g(205,2,"Things that can be royal","FLUSH","BLUE","FAMILY","PAIN"),
            g(206,3,"___ blue","BABY","ROYAL","SKY","POWDER"),
            g(207,4,"Words for edge","BRINK","VERGE","PRECIPICE","CUSP"),
        ]),
        Puzzle(id: 52, groups: [
            g(208,1,"Tea types","OOLONG","DARJEELING","ASSAM","SENCHA"),
            g(209,2,"Things with a pitch","SALES","PERFECT","BASEBALL","TAR"),
            g(210,3,"___ note","FOOT","BANK","HALF","STICKY"),
            g(211,4,"Words meaning careful","PRUDENT","CIRCUMSPECT","JUDICIOUS","WARY"),
        ]),
        Puzzle(id: 53, groups: [
            g(212,1,"Things in a circus","TRAPEZE","ACROBAT","RINGMASTER","JUGGLER"),
            g(213,2,"Things that can be striking","MATCH","MINERS","APPEARANCE","CLOCK"),
            g(214,3,"___ match","BOOK","BOX","TENNIS","LOVE"),
            g(215,4,"Words meaning large","COLOSSAL","MAMMOTH","GARGANTUAN","TITANIC"),
        ]),
        Puzzle(id: 54, groups: [
            g(216,1,"Things in a beehive","DRONE","QUEEN","WORKER","HONEYCOMB"),
            g(217,2,"Things that can be loaded","GUN","QUESTION","DICE","BAKED POTATO"),
            g(218,3,"___ bee","HONEY","SPELLING","BUMBLE","KILLER"),
            g(219,4,"Words meaning sad","MELANCHOLY","FORLORN","DOLEFUL","LUGUBRIOUS"),
        ]),
        Puzzle(id: 55, groups: [
            g(220,1,"Types of knot","BOWLINE","REEF","CLOVE HITCH","FIGURE EIGHT"),
            g(221,2,"Things that can be bent","RULE","ELBOW","TRUTH","LIGHT"),
            g(222,3,"___ point","GUN","BALL","VIEW","BREAKING"),
            g(223,4,"Words meaning fake","SPURIOUS","APOCRYPHAL","BOGUS","ERSATZ"),
        ]),
        Puzzle(id: 56, groups: [
            g(224,1,"Types of stitch","CROSS","RUNNING","SATIN","CHAIN"),
            g(225,2,"Things that can be fine","ART","PRINT","WEATHER","TUNE"),
            g(226,3,"___ needle","PINE","COMPASS","KNITTING","HYPODERMIC"),
            g(227,4,"Words meaning strange","OUTLANDISH","ABERRANT","UNCANNY","EERIE"),
        ]),
        Puzzle(id: 57, groups: [
            g(228,1,"Types of map","TOPOGRAPHIC","CONTOUR","RELIEF","POLITICAL"),
            g(229,2,"Things that can be steep","HILL","PRICE","TEA","LEARNING CURVE"),
            g(230,3,"___ road","HIGH","SILK","DEAD END","TOLL"),
            g(231,4,"Words meaning slow","LANGUID","TORPID","SLUGGISH","LEADEN"),
        ]),
        Puzzle(id: 58, groups: [
            g(232,1,"Sci-fi franchises","STAR WARS","DUNE","FOUNDATION","EXPANSE"),
            g(233,2,"Things you can draw","GUN","BLOOD","BATH","ATTENTION"),
            g(234,3,"___ draw","QUICK","OUT","WITH","OVER"),
            g(235,4,"Words meaning brief","TERSE","LACONIC","PITHY","SUCCINCT"),
        ]),
        Puzzle(id: 59, groups: [
            g(236,1,"Types of market","BULL","BEAR","STOCK","FARMERS"),
            g(237,2,"Things that can be bear","ARMS","FRUIT","WITNESS","GRUDGE"),
            g(238,3,"___ bear","GRIZZLY","POLAR","KOALA","TEDDY"),
            g(239,4,"Words for boundary","PERIMETER","THRESHOLD","FRONTIER","DEMARCATION"),
        ]),
        Puzzle(id: 60, groups: [
            g(240,1,"Things in a pocket","LINT","CHANGE","KNIFE","RECEIPT"),
            g(241,2,"Things that can be dirty","LAUNDRY","MONEY","TRICK","DOZEN"),
            g(242,3,"___ dozen","BAKER","DIRTY","DAILY","LONG"),
            g(243,4,"Words for bright","LUMINOUS","RADIANT","INCANDESCENT","EFFULGENT"),
        ]),
        Puzzle(id: 61, groups: [
            g(244,1,"Mountain ranges","ANDES","HIMALAYAS","ROCKIES","ALPS"),
            g(245,2,"Things that can be peak","PERFORMANCE","HOUR","OIL","MOUNTAIN"),
            g(246,3,"___ range","MOUNTAIN","FIRING","DRIVING","FREE"),
            g(247,4,"Words for calm","PLACID","SERENE","TRANQUIL","EQUANIMOUS"),
        ]),
        Puzzle(id: 62, groups: [
            g(248,1,"Cocktails","NEGRONI","GIMLET","SIDECAR","BOULEVARDIER"),
            g(249,2,"Things that can be neat","TRICK","WRITING","SOLUTION","WHISKY"),
            g(250,3,"___ trick","HAT","CARD","MAGIC","DIRTY"),
            g(251,4,"Words meaning cunning","WILY","CRAFTY","GUILEFUL","ARTFUL"),
        ]),
        Puzzle(id: 63, groups: [
            g(252,1,"Types of bridge (card game)","CONTRACT","DUPLICATE","RUBBER","CHICAGO"),
            g(253,2,"Things that can be rubber","DUCK","BAND","STAMP","BULLET"),
            g(254,3,"___ stamp","RUBBER","POSTAGE","DATE","FOOD"),
            g(255,4,"Words meaning loyal","STEADFAST","STAUNCH","UNWAVERING","INVETERATE"),
        ]),
        Puzzle(id: 64, groups: [
            g(256,1,"Things at a farmers market","KALE","HEIRLOOM TOMATO","HONEY","PRESERVES"),
            g(257,2,"Things that can be preserved","JAM","FOSSIL","DIGNITY","SPECIMEN"),
            g(258,3,"___ preserve","NATURE","GAME","PLUM","SELF"),
            g(259,4,"Words meaning strong","ROBUST","STALWART","FORMIDABLE","REDOUBTABLE"),
        ]),
        Puzzle(id: 65, groups: [
            g(260,1,"Wine regions","BORDEAUX","BURGUNDY","CHIANTI","RIOJA"),
            g(261,2,"Things that can be full-bodied","WINE","SHAMPOO","DESCRIPTION","NOVEL"),
            g(262,3,"___ body","FULL","OVER","SOME","EVERY"),
            g(263,4,"Words meaning pure","PRISTINE","UNSULLIED","IMMACULATE","VIRGINAL"),
        ]),
        Puzzle(id: 66, groups: [
            g(264,1,"Mythological creatures","MINOTAUR","SPHINX","CHIMERA","BASILISK"),
            g(265,2,"Things that can be golden","GATE","RATIO","AGE","RETRIEVER"),
            g(266,3,"___ age","GOLDEN","STONE","SPACE","DARK"),
            g(267,4,"Words meaning deep","PROFOUND","ABYSSAL","Fathomless","Bottomless"),
        ]),
        Puzzle(id: 67, groups: [
            g(268,1,"Photography terms","APERTURE","SHUTTER","BOKEH","HISTOGRAM"),
            g(269,2,"Things that can be raw","DEAL","FILE","EMOTION","POWER"),
            g(270,3,"___ file","RAW","NAIL","PROFILE","RANK"),
            g(271,4,"Words meaning abundant","COPIOUS","PROFUSE","LAVISH","PLENTIFUL"),
        ]),
        Puzzle(id: 68, groups: [
            g(272,1,"Types of eclipse","SOLAR","LUNAR","TOTAL","ANNULAR"),
            g(273,2,"Things that can be total","ECLIPSE","RECALL","WAR","STRANGER"),
            g(274,3,"___ recall","TOTAL","INSTANT","PERFECT","MUSCLE"),
            g(275,4,"Words meaning short-lived","EPHEMERAL","FLEETING","TRANSIENT","EVANESCENT"),
        ]),
        Puzzle(id: 69, groups: [
            g(276,1,"Things in a hospital","SCALPEL","GAUZE","FORCEPS","SUTURE"),
            g(277,2,"Things that can be critical","MASS","THINKING","CARE","POINT"),
            g(278,3,"___ care","CRITICAL","HEALTH","HAIR","SKIN"),
            g(279,4,"Words meaning to wander","MEANDER","RAMBLE","ROAM","TRAIPSE"),
        ]),
        Puzzle(id: 70, groups: [
            g(280,1,"Things in a fire station","LADDER","HOSE","POLE","DALMATIAN"),
            g(281,2,"Things that can be extended","FAMILY","DEADLINE","HAND","LEASE"),
            g(282,3,"___ family","EXTENDED","BLENDED","CHOSEN","NUCLEAR"),
            g(283,4,"Words meaning to deceive","BAMBOOZLE","HOODWINK","COZEN","INVEIGLE"),
        ]),
        Puzzle(id: 71, groups: [
            g(284,1,"Types of soil","LOAM","CLAY","SILT","PEAT"),
            g(285,2,"Things that can be ground","COFFEE","MEAT","GLASS","ZERO"),
            g(286,3,"___ floor","GROUND","DANCE","OCEAN","SHOP"),
            g(287,4,"Words meaning to join","AMALGAMATE","COALESCE","MERGE","CONSOLIDATE"),
        ]),
        Puzzle(id: 72, groups: [
            g(288,1,"Weather instruments","BAROMETER","HYGROMETER","ANEMOMETER","THERMOMETER"),
            g(289,2,"Things that can be measured","TEMPERATURE","PATIENCE","RAINFALL","IMPACT"),
            g(290,3,"___ meter","BARO","GAS","PARK","KILO"),
            g(291,4,"Words meaning plentiful","BOUNTIFUL","TEEMING","FLUSH","RIFE"),
        ]),
        Puzzle(id: 73, groups: [
            g(292,1,"Things with a spine","BOOK","SEA URCHIN","CACTUS","HEDGEHOG"),
            g(293,2,"Things that can be picked","LOCK","FIGHT","POCKET","BONE"),
            g(294,3,"___ bone","PICK","CHEEK","COLLAR","WISH"),
            g(295,4,"Words meaning hesitant","RETICENT","LOATH","RELUCTANT","DIFFIDENT"),
        ]),
        Puzzle(id: 74, groups: [
            g(296,1,"Things on a clock face","MINUTE HAND","SECOND HAND","BEZEL","CRYSTAL"),
            g(297,2,"Things that can be wound up","CLOCK","SPRING","SPEECH","DEAL"),
            g(298,3,"___ spring","PALM","HOT","MAIN","WELL"),
            g(299,4,"Words meaning unexpected","UNFORESEEN","FORTUITOUS","Serendipitous","UNANTICIPATED"),
        ]),
        Puzzle(id: 75, groups: [
            g(300,1,"Things in a school bag","PENCIL CASE","PROTRACTOR","RULER","ERASER"),
            g(301,2,"Things that can be ruler","TWELVE INCH","ABSOLUTE","FOOT","CLASSROOM"),
            g(302,3,"___ ruler","SLIDE","FOOT","TWELVE","INCH"),
            g(303,4,"Words meaning humble","MEEK","UNASSUMING","MODEST","SELF-EFFACING"),
        ]),
        Puzzle(id: 76, groups: [
            g(304,1,"Knitting stitches","GARTER","STOCKINETTE","SEED","CABLE"),
            g(305,2,"Things that can be strained","RELATIONSHIP","MUSCLE","SAUCE","BUDGET"),
            g(306,3,"___ strain","MAIN","EYE","BRAIN","REFRAIN"),
            g(307,4,"Words meaning very bright","DAZZLING","RESPLENDENT","Vivid","BLAZING"),
        ]),
        Puzzle(id: 77, groups: [
            g(308,1,"Types of energy drink","RED BULL","MONSTER","REIGN","CELSIUS"),
            g(309,2,"Things that can be charged","PHONE","BULL","PRICE","BATTERY"),
            g(310,3,"___ bull","RED","PIT","JOHN","SITTING"),
            g(311,4,"Words meaning to criticize","CENSURE","CASTIGATE","CHIDE","LAMBASTE"),
        ]),
        Puzzle(id: 78, groups: [
            g(312,1,"Types of noodle","RAMEN","UDON","SOBA","PHO"),
            g(313,2,"Things that can be long","NOODLE","HAIR","HISTORY","SHOT"),
            g(314,3,"___ shot","LONG","GUN","MOON","BIG"),
            g(315,4,"Words meaning to improve","AMELIORATE","REFINE","Hone","CULTIVATE"),
        ]),
        Puzzle(id: 79, groups: [
            g(316,1,"Things in a treasure chest","DOUBLOON","JEWEL","MAP","COMPASS"),
            g(317,2,"Things that can be precious","METAL","MOMENT","STONE","TIME"),
            g(318,3,"___ stone","PRECIOUS","CORNER","LIME","STUMBLING"),
            g(319,4,"Words meaning curious","INQUISITIVE","QUIZZICAL","Prying","NOSY"),
        ]),
        ]
    }
}

import Foundation

// Embedded word list — 500 common English words for offline play
struct WordValidator {
    static let validWords: Set<String> = {
        Set(wordList.components(separatedBy: "\n").map { $0.uppercased().trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty })
    }()

    static func isValid(_ word: String) -> Bool {
        validWords.contains(word.uppercased())
    }

    // ~500 common 3-8 letter words covering a broad range of Scrabble plays
    private static let wordList = """
    ace act add age ago aid aim air ale all ant ape apt arc are ark arm art ask ate
    awe axe aye baa bad bag ban bar bat bay bed bet bid big bit bog bow box boy bud
    bug bun bus but buy cab can cap car cat cob cod cog cop cot cow cry cub cud cup
    cut dab dam dew did dig dim dip doe dog dot dub dud dug dun duo dye ear eat eel
    egg ego elf elk elm emu end era eve ewe eye fad fan far fat fax fed few fib fig
    fin fir fit fix fly fob fog foe for fox fry fub fun fur gag gap gas gay gel gem
    get gig gin gnu god got gum gun gut guy gym had ham has hat haw hay hem hen hew
    hid him hip his hit hob hog hop hot how hub hug hum hut ice icy ill imp ink inn
    ion ire irk ivy jab jag jam jar jaw jay jet jig job jot joy jug jut keg kid kin
    kit lab lad lag lap law lax lay led leg let lid lip lit log lot low lug mad man
    map mar mat maw may men met mew mid mix mob moo mop mud mug nab nag nap nit nob
    nod nor not now nun oak oar odd ode off oft ohm oil old opt orb ore our out owe
    owl own pad pan pap par pat paw pay pea peg pen pep per pew pie pig pin pit ply
    pod pox pro pub pug pun pup pus put rag ram ran rap rat raw ray red rep rev rid
    rig rim rip rob rod roe rot row rub rug rum run rut rye sac sad sag sap sat saw
    say sea set sew she shy sin sip sir sit six ski sky slab slam slap slim slip slob
    slop slot slow slum sob sod son sop sot sow spa spy sob sob sob sue sum sun sup
    tab tag tan tap tar tat tax tea ten the tie til tin tip toe ton too top tot tow
    toy try tub tug tun tut two ugh urn use van vat via vie vim vow wag war was wax
    way web wed wee wig win wit woe wok won woo yak yam yap yew you zap zen zip zoo
    able acid acne aged ages aide aids aims ails aims airs alms also alto alum amok
    ankh ante anti apex apes arch area aria arid arms arty ashy atop avid axle babe
    back bade bail bait bald bale balk ball band bane bang bank bard bare barn base
    bash bask bass bath bead beak beam bean beat beef been beer bees beet bell belt
    bend best bias bird bite bled blot blow blue blur boar boat bold bolt bone bony
    book boom boon boot bore born boss both buoy burn burp burr buzz cafe cage cake
    call calm came camp cane cant cape card care cart case cash cast cave cell cent
    chap char chat chef chew chin chip chop clad clam clap claw clay clip clod clog
    club clue coal coat coax coil coin cold colt come cone cool cope cord core cork
    corn cost cove cozy cram crew crib crop crow cube curb cure curl cute dale dame
    dark dart dash date dawn days dead deaf deal dean dear debt deck deep deer deft
    deli dell demo deny desk dial dies diet dirt disk dive dock dome done door dose
    dote dove down drag draw drip drop drum dual duck duel duke dull dump dupe dusk
    dust duty each earl earn ease east edge emit envy epic even ever evil exam face
    fact fade fail fair fame farm fast fate fawn feat feel feet fell felt fern fest
    feud file fill film find fine fire firm fish fist flab flag flaw flea fled flex
    flip flit flog flop flow foam foci foil fold folk fond font food fool foot ford
    fore fork form fort foul fowl free fret frog from fuel full fund furl fury fuse
    fuss gait gale gall game gang garb gate gave gaze germ gild gill gilt girl gist
    give glad glee glen glib glob glow glue glum goal goat gold golf gone gong good
    gore gory gosh gown grad gray grew grid grin grip grit grow grub gulf gull gulp
    guns guru gush gust hack hale half hall halo halt hand hang hare harm harp hash
    hast hate haul have hawk haze hazy head heal heap hear heat heed heel held helm
    help herd hero high hill hint hire hold hole holy home hone hood hoop hope horn
    hose host hour huge hull hump hung hunt hurl hurt hymn icon idea idle idol inch
    into iron isle itch item jade jail jape jest jest jest jest jibe jilt join joke
    jolt joss jowl joys jump junk just keen keep kelp kept kill kind king kink knob
    knot know lack lame lamp land lane lard lark lash last late laud lava lawn laze
    lazy lead leaf leak lean leap lend lens lest levy lick lieu lift like lime limp
    line link lion list live loan lock loft lone long look loom loon lore lorn loss
    lost loud love luck lull lump lung lure lust mace made maid mail main mall mane
    mast mate math maze mead meal mean meat meet melt memo mend mesh mild mile milk
    mill mime mind mine mint mire miss mist mite moat mode mold molt mope more mote
    moth move much muck mull muse musk must nail name nape navy near neat need nest
    news next nice nick node none noon norm nose note null oath obey oboe once only
    open oral oven over pace pack page paid pail pair palm pang park part pass past
    path pave peak peal peel peer pest pick pied pike pile pill pine pink pipe pith
    pity plan plod plot plow ploy plug plum plus poem poet pole poll polo pond pony
    pool poor pope pore port pose post pour pout pray prey prim prow pull pump pure
    push quit race rack raft raid rail rain rake rank rant rapt rash rate rave read
    real reap redo reed reef reel rein rely rent rest rice rich ride rife rift ring
    riot rise risk road roam roar robe rock role roll roof room rope rose rout rove
    ruin rule rush rust safe sage sail sake salt same sand sane sang sank sash save
    scan scar shed shed shim shin ship shoe shop shot show shun shut sick side sigh
    sign silk sill silk sill sill silt sing sink site size skip slab slam slap slat
    sled slew slim slip slot slow slug slum slur smug snag snap snob snub soak soap
    soar sock sofa soil sole some song soot sort soul sour span spar spit spot spud
    spur stab stag star stem step stew stir stop stow stub stun such suit sulk sung
    sunk sure swam swan swap swat sway swig swim swam tale talk tall tame tank tape
    tare tart task taut teal team tear teem tell tend tent term test text thaw thee
    them then they thin this tho tide tidy tier tile time tiny tire toll tomb tome
    tone tong tool tore torn toss tote tour town trek trim trio trip trod trot true
    tube tuck tune turf turn tusk tutu twin type ugly undo unit upon urge used vale
    vane vary vase vast veer veil vein vent verb very vest veto vibe view vile vine
    vise void volt vote wade wail wait wake walk wall wand wane ward ware warm warn
    warp wart wary wave wavy weak weal wean weed week weld well welt went were west
    wick wide wife wild wile will wilt wind wine wing wink wiry wish wisp with woke
    wolf womb word wore work worm worn wrap wren wring writ wry yawn year yell yoga
    yore zero zest zeal zone
    """
}

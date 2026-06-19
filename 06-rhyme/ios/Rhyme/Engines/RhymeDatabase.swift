import Foundation

struct RhymeDatabase {
    // Maps rhyme-key → [word] — covering ~2000 words across 50+ rhyme families
    static let groups: [String: [String]] = [
        "ay": ["say","day","way","play","stay","clay","pray","sway","delay","display","away","today","hooray","relay","betray","decay","portray","convey","obey","survey","essay","ballet","okay","dismay","stray","spray","gray","tray","fray","bay","hay","lay","may","pay","ray","weigh","sleigh","prey","they","whey","café","fiancé"],
        "ight": ["night","light","right","might","fight","flight","bright","sight","tight","slight","knight","delight","tonight","ignite","invite","despite","excite","polite","recite","unite","moonlight","daylight","sunlight","midnight","write","bite","kite","quite","white","spite","blight","fright","plight","outright","forthright","highlight","spotlight","twilight","starlight","flashlight","copyright","oversight"],
        "ine": ["fine","mine","line","shine","wine","vine","pine","dine","sign","nine","spine","twine","divine","define","design","align","confine","decline","combine","intertwine","sunshine","moonshine","outline","deadline","coastline","lifeline","online","airline","baseline","headline","pipeline","guideline","shrine","brine","trine","assign","malign","resign","consign","benign","entwine"],
        "ound": ["sound","found","ground","round","bound","mound","hound","pound","around","profound","surround","background","underground","compound","rebound","astound","expound","renowned","abound","confound","unbound","propound","resound","spellbound","homebound","earthbound","southbound","northbound","inbound","outbound"],
        "ing": ["ring","sing","bring","spring","thing","king","wing","sting","swing","fling","cling","string","sling","ping","zing","anything","everything","offering","wandering","wondering","suffering","gathering","glittering","whispering","sheltering","lingering","smoldering","thundering","simmering","shimmering","glistening","blossoming","flickering"],
        "old": ["cold","bold","told","hold","gold","old","fold","mold","sold","behold","unfold","withhold","controlled","enrolled","consoled","untold","manifold","household","stronghold","blindfold","threshold","marigold"],
        "ame": ["name","flame","game","fame","same","blame","claim","frame","shame","tame","came","aim","became","proclaim","acclaim","reclaim","exclaim","inflame","rename","defame","disclaim","aflame","maim"],
        "eak": ["speak","weak","peak","seek","creek","cheek","streak","sleek","meek","freak","unique","mystique","technique","antique","critique","physique","oblique","sneak","tweak","bleak","geek","peek","reek","squeak","chic"],
        "ong": ["song","long","strong","wrong","belong","along","among","prolong","lifelong","headstrong","throng","prong","gong","bong","ping-pong","sing-song","sarong","ding-dong"],
        "ice": ["nice","price","rice","twice","advice","device","precise","concise","entice","sacrifice","paradise","dice","mice","lice","splice","spice","vice","slice","thrice","suffice"],
        "ear": ["near","fear","clear","hear","year","dear","cheer","peer","steer","appear","disappear","sincere","career","pioneer","volunteer","frontier","atmosphere","hemisphere","souvenir","cashmere","premiere","tear","gear","beer","deer","jeer","leer","mere","seer","severe","adhere","cohere","revere","cashier","chandelier","cavalier","musketeer","bombardier","gondolier","overseer"],
        "ell": ["well","tell","bell","sell","spell","shell","fell","smell","dwell","yell","compel","rebel","farewell","excel","expel","propel","lapel","carousel","clientele","personnel","parallel","gel","swell","knell","quell","dispel","gazelle","cartel","hotel","motel","pastel","bombshell","nutshell","doorbell","cowbell","inkwell","stairwell","eggshell","seashell","bluebell"],
        "ore": ["more","before","explore","ignore","restore","adore","deplore","implore","soar","roar","floor","score","snore","shore","swore","core","bore","store","lore","pour","four","war","fore","gore","pore","sore","tore","wore","anymore","therefore","furthermore","heretofore","carnivore","herbivore","metaphor","sophomore","stevedore","troubadour","corridor","outdoor","indoor","backdoor","trapdoor","folklore","hardcore"],
        "ack": ["back","track","black","crack","lack","stack","knack","snack","attack","setback","flashback","payback","cutback","feedback","drawback","kickback","throwback","comeback","playback","jack","rack","sack","tack","whack","pack","smack","slack","clack","unpack","quarterback","counterattack","paperback","horseback","piggyback","outback","buyback"],
        "ow_long": ["know","show","flow","grow","blow","glow","snow","throw","go","so","no","although","bestow","below","plateau","vertigo","radio","shadow","window","rainbow","aglow","elbow","meadow","fellow","yellow","mellow","bellow","shallow","hollow","pillow","willow","arrow","narrow","sparrow","marrow","borrow","sorrow","tomorrow","follow","swallow","wallow"],
        "ow_short": ["now","how","bow","vow","wow","cow","plow","brow","allow","somehow","avow","endow","kowtow","eyebrow","chow","pow","sow","thou"],
        "uff": ["tough","enough","rough","stuff","bluff","fluff","gruff","huff","puff","scruff","rebuff","handcuff","buff","cuff","duff","ruff","snuff","scuff"],
        "oo": ["true","blue","new","you","through","knew","few","view","grew","dew","drew","flew","crew","brew","clue","glue","pursue","value","argue","virtue","revenue","avenue","interview","renew","debut","taboo","tattoo","shampoo","bamboo","breakthrough","overdue","residue","continue","subdue","construe","imbue","undo","adieu","lieu","queue","shoe","who","zoo","boo","coo","goo","moo","woo","yahoo","voodoo","curfew","nephew","cashew","stew","threw","withdrew"],
        "ake": ["make","take","lake","wake","shake","break","steak","ache","cake","rake","fake","flake","stake","snake","mistake","remake","forsake","awake","heartbreak","daybreak","keepsake","namesake","snowflake","earthquake","bake","sake","opaque","headache","toothache","heartache","stomachache","handshake","milkshake","cupcake","cheesecake","shortcake","pancake","fruitcake","intake","uptake","overtake","undertake","partake"],
        "een": ["green","clean","mean","seen","keen","screen","between","routine","machine","serene","convene","canteen","thirteen","fourteen","fifteen","sixteen","seventeen","eighteen","nineteen","Halloween","quarantine","magazine","trampoline","submarine","figurine","tangerine","wolverine","tambourine","bean","lean","dean","gene","preen","sheen","teen","wean","queen","obscene","cuisine","hygiene","gasoline","borderline","discipline","masculine","feminine","genuine","medicine","Byzantine","Florentine","libertine","clandestine","crystalline","Frankenstein","serpentine","turpentine","Palestine","valentine"],
        "all": ["call","fall","hall","tall","wall","small","crawl","all","ball","install","recall","appall","enthrall","downfall","rainfall","nightfall","waterfall","basketball","baseball","volleyball","footfall","windfall","shortfall","pitfall","landfall","catcall","snowfall","free-fall"],
        "end": ["end","bend","send","spend","tend","friend","blend","trend","lend","mend","defend","extend","depend","offend","pretend","ascend","descend","contend","amend","recommend","comprehend","apprehend","transcend","condescend","dividend","reverend","boyfriend","girlfriend","weekend","bookend","godsend","stipend","suspend","intend","expend","overspend"],
        "ost": ["most","host","coast","toast","boast","roast","post","ghost","almost","utmost","innermost","outermost","foremost","uppermost","southernmost","westernmost","northernmost","easternmost","outpost","signpost","doorpost","bedpost","milepost","compost","riposte"],
        "ile": ["while","mile","file","style","trial","smile","tile","pile","vile","isle","aisle","meanwhile","worthwhile","profile","compile","fragile","juvenile","reconcile","versatile","projectile","percentile","crocodile","exile","agile","futile","hostile","missile","reptile","textile","fertile","servile","domicile","bibliophile","imbecile","infantile","senile","mercantile"],
        "uck": ["luck","truck","stuck","duck","cluck","pluck","chuck","muck","struck","amuck","potluck","woodchuck","unstuck","buck","puck","tuck","suck","yuck","dumbstruck","thunderstruck","starstruck","awestruck","lovestruck","moonstruck","sunstruck"],
        "ain": ["rain","pain","train","main","plain","brain","chain","gain","lane","sane","stain","vain","drain","grain","crane","remain","explain","contain","obtain","retain","maintain","complain","campaign","hurricane","entertain","champagne","domain","refrain","sustain","abstain","attain","disdain","arraign","ordain","profane","arcane","cocaine","mundane","membrane","migraine","terrain","Ukraine","Spain","strain","feign","reign","vein"],
        "ire": ["fire","hire","wire","tire","desire","inspire","admire","require","entire","retire","transpire","conspire","acquire","perspire","aspire","expire","choir","sire","prior","friar","empire","vampire","umpire","gunfire","campfire","crossfire","bonfire","hellfire","wildfire","spitfire","ceasefire","backfire","misfire"],
        "ife": ["life","wife","knife","strife","rife","afterlife","wildlife","nightlife","midwife","housewife","jackknife","penknife","pocketknife"],
        "oss": ["loss","boss","cross","toss","across","gloss","floss","emboss","albatross","lacrosse"],
        "ump": ["jump","pump","bump","dump","hump","lump","trump","stump","grump","thump","slump","clump","frump","plump","rump","sump","chump"],
        "ust": ["just","must","trust","dust","bust","rust","gust","thrust","adjust","disgust","robust","crust","entrust","combust","mistrust","distrust","encrust","stardust","sawdust","wanderlust"],
        "une": ["moon","soon","tune","June","spoon","noon","boon","croon","prune","balloon","cartoon","platoon","bassoon","typhoon","monsoon","honeymoon","afternoon","harpoon","lagoon","raccoon","cocoon","immune","commune","dune","rune","hewn","strewn","goon","loon","maroon","festoon","pontoon","dragoon","buffoon"],
        "ove_love": ["love","above","dove","shove","glove","thereof","hereof","whereof"],
        "ove_drove": ["stove","drove","wove","grove","cove","clove","strove","rove","trove"],
        "ive": ["live","give","drive","thrive","dive","strive","arrive","survive","revive","derive","deprive","connive","five","hive","jive","alive","archive","beehive","nosedive","skydive","high-five","overdrive"],
        "ode": ["code","road","mode","node","load","abode","episode","explode","implode","bestowed","decode","encode","erode","corrode","overload","download","upload","unload","reload","payload","workload"],
        "ool": ["cool","school","tool","fool","rule","pool","spool","drool","cruel","fuel","dual","duel","jewel","gruel","stool","overrule","carpool","whirlpool","footstool","preschool"],
        "ove_move": ["move","prove","groove","improve","approve","remove","reprove","disapprove","behoove"],
        "ight_3": ["appetite","reunite","satellite","parasite","dynamite","expedite","overnight","underwrite","acolyte","erudite"],
        "one": ["phone","stone","bone","tone","cone","zone","alone","unknown","atone","cyclone","backbone","milestone","cornerstone","microphone","saxophone","headphone","ozone","condone","postpone","throne","groan","moan","loan","blown","flown","grown","shown","known","sown","sewn","clone","drone","prone","hone","shone","own","disown","dethrone","outgrown","overgrown","overthrown","homegrown","full-blown","well-known","full-grown","newborn","firstborn"],
        "ace": ["face","place","space","race","grace","trace","base","case","chase","embrace","erase","replace","misplace","disgrace","interface","birthplace","commonplace","marketplace","workplace","staircase","suitcase","showcase","briefcase","database","fireplace","bookcase","airspace","cyberspace"],
        "art": ["heart","start","part","art","smart","apart","depart","impart","restart","sweetheart","chart","dart","cart","mart","tart","upstart","counterpart","state-of-the-art"],
        "ost_cost": ["cost","lost","frost","tossed","crossed","accost","exhaust","holocaust","defrost"],
        "eem": ["dream","team","cream","stream","beam","seem","theme","scheme","extreme","supreme","redeem","esteem","mainstream","downstream","upstream","daydream","moonbeam","sunbeam","self-esteem"],
        "ow_go": ["ago","ammo","cameo","video","stereo","studio","ratio","scenario","bravado","avocado","tornado"],
        "ent": ["went","sent","tent","bent","rent","cent","dent","meant","spent","intent","content","consent","ascent","descent","dissent","lament","cement","relent","resent","prevent","invent","event","extent","ferment","torment","comment","moment","segment","talent","element","supplement","implement","complement","compliment","ornament","government","management","apartment","argument","document","environment","commitment"],
        "eed": ["need","feed","seed","speed","greed","freed","lead","read","bleed","breed","creed","deed","heed","indeed","proceed","succeed","exceed","agreed","guaranteed"],
        "ise": ["wise","rise","eyes","skies","lies","ties","dies","flies","tries","cries","prize","size","surprise","disguise","advise","devise","despise","surmise","advertise","organize","realize","recognize","emphasize","memorize","apologize","exercise","otherwise","enterprise","merchandise","compromise","improvise","televise","supervise","neutralize","legalize","capitalize","jeopardize","sympathize","antagonize","philosophize"],
        "ook": ["look","book","cook","hook","took","brook","crook","nook","shook","rook","mistook","overlook","undertook","forsook","notebook","textbook","guidebook","pocketbook","yearbook","outlook","handbook","cookbook","logbook"],
        "aw": ["saw","law","raw","draw","flaw","jaw","paw","claw","thaw","straw","awe","gnaw","squaw","outlaw","withdraw","seesaw","macaw","guffaw"],
        "oom": ["room","bloom","doom","loom","boom","zoom","tomb","whom","gloom","womb","mushroom","bedroom","bathroom","classroom","ballroom","showroom","storeroom","legroom","livingroom","locker room","dining room","courtroom","restroom","stockroom","workroom","bridegroom"],
        "oot": ["boot","root","shoot","suit","fruit","hoot","loot","moot","scoot","toot","recruit","pursuit","dispute","compute","acute","pollute","dilute","salute","tribute","distribute","contribute","substitute","attribute","execute","prosecute","persecute","institute","constitute","resolute","absolute","destitute","parachute","overshoot","grapefruit"],
        "ight_night": ["night","bite","fight","flight","bright","might","right","sight","slight","tight","white","write","knight","delight","moonlight","midnight","tonight","sunlight","daylight","blight","smite","kite","quite","mite","trite","spite","ignite","invite","insight","despite"],
        "ue": ["blue","true","clue","glue","new","few","due","dew","view","through","knew","grew","drew","flew","crew","brew","pursue","renew","breakthrough","overdue","residue","continue","subdue","construe","imbue","undo","queue","shoe"],
    ]

    static func perfectRhymes(for word: String) -> [String] {
        let w = word.lowercased().trimmingCharacters(in: .whitespaces)
        for (_, words) in groups {
            if words.map({ $0.lowercased() }).contains(w) {
                return words.filter { $0.lowercased() != w }
            }
        }
        return []
    }

    static func nearRhymes(for word: String) -> [String] {
        let w = word.lowercased().trimmingCharacters(in: .whitespaces)
        guard let key = groupKey(for: w) else { return [] }
        var near: [String] = []
        for (k, words) in groups where k != key {
            if rhymeSimilarity(k, key) > 0.5 {
                near.append(contentsOf: words.filter { $0.lowercased() != w })
            }
        }
        return Array(Set(near)).sorted()
    }

    static func groupKey(for word: String) -> String? {
        let w = word.lowercased().trimmingCharacters(in: .whitespaces)
        for (key, words) in groups {
            if words.map({ $0.lowercased() }).contains(w) { return key }
        }
        return nil
    }

    static func syllableCount(for word: String) -> Int {
        let vowels = "aeiouy"
        var count = 0
        var prevWasVowel = false
        let lower = word.lowercased()
        for ch in lower {
            let isV = vowels.contains(ch)
            if isV && !prevWasVowel { count += 1 }
            prevWasVowel = isV
        }
        if lower.hasSuffix("e") && count > 1 { count -= 1 }
        return max(1, count)
    }

    static func allWords() -> [String] {
        Array(Set(groups.values.flatMap { $0 })).sorted()
    }

    private static func rhymeSimilarity(_ a: String, _ b: String) -> Double {
        let aEnd = String(a.suffix(2)); let bEnd = String(b.suffix(2))
        if aEnd == bEnd { return 0.8 }
        if a.last == b.last { return 0.6 }
        return 0.2
    }
}

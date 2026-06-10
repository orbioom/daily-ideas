import Foundation

/// Curated five-letter words. Used both as the daily/random answers and as the
/// dictionary of accepted guesses. All common, lowercase, no proper nouns.
enum WordList {
    /// Only exactly-five-letter, all-letter words survive — a guard against any
    /// stray entry of the wrong length slipping into the raw list.
    static let answers: [String] = words
    static let valid: Set<String> = Set(words)

    static func isValid(_ word: String) -> Bool {
        valid.contains(word.lowercased())
    }

    static let words: [String] = rawWords.filter { $0.count == 5 && $0.allSatisfy { $0.isLetter } }

    private static let rawWords: [String] = [
        "about","above","abuse","actor","acute","admit","adopt","adult","after","again",
        "agent","agree","ahead","alarm","album","alert","alike","alive","allow","alone",
        "along","alter","among","anger","angle","angry","apart","apple","apply","arena",
        "argue","arise","array","aside","asset","audio","audit","avoid","award","aware",
        "badly","baker","bases","basic","beach","began","begin","being","below","bench",
        "billy","birth","black","blame","blank","blast","blind","block","blood","board",
        "boost","booth","bound","brain","brand","brave","bread","break","breed","brief",
        "bring","broad","broke","brown","build","built","buyer","cable","calm","carry",
        "catch","cause","chain","chair","chaos","charm","chart","chase","cheap","check",
        "chest","chief","child","china","chose","civil","claim","class","clean","clear",
        "click","climb","clock","close","cloud","coach","coast","could","count","court",
        "cover","craft","crash","crazy","cream","crime","cross","crowd","crown","curve",
        "cycle","daily","dance","dated","dealt","death","debut","delay","depth","doing",
        "doubt","dozen","draft","drama","drawn","dream","dress","drill","drink","drive",
        "drove","dying","eager","early","earth","eight","elite","empty","enemy","enjoy",
        "enter","entry","equal","error","event","every","exact","exist","extra","faith",
        "false","fault","favor","fence","fewer","fiber","field","fifth","fifty","fight",
        "final","first","fixed","flame","flash","fleet","floor","fluid","focus","force",
        "forth","forty","forum","found","frame","frank","fraud","fresh","front","frost",
        "fruit","fully","funny","ghost","giant","given","glass","globe","glory","grace",
        "grade","grain","grand","grant","grass","grave","great","green","greet","gross",
        "group","grown","guard","guess","guest","guide","happy","harsh","heart","heavy",
        "hence","hobby","horse","hotel","house","human","ideal","image","index","inner",
        "input","issue","ivory","joint","judge","juice","known","label","labor","large",
        "laser","later","laugh","layer","learn","lease","least","leave","legal","lemon",
        "level","light","limit","linen","links","lives","local","logic","loose","lower",
        "loyal","lucky","lunar","lunch","lying","magic","major","maker","march","match",
        "maybe","mayor","meant","medal","media","melon","mercy","merge","metal","meter",
        "might","minor","minus","mixed","model","money","month","moral","motor","mount",
        "mouse","mouth","movie","music","naval","nerve","never","newly","night","noble",
        "noise","north","noted","novel","nurse","ocean","offer","often","olive","onion",
        "order","other","ought","outer","owner","paint","panel","paper","party","pause",
        "peace","pearl","penny","phase","phone","photo","piano","piece","pilot","pitch",
        "place","plain","plane","plant","plate","plaza","plot","point","porch","pound",
        "power","press","price","pride","prime","print","prior","prize","proof","proud",
        "prove","punch","pupil","quick","quiet","quite","quota","quote","radar","radio",
        "raise","rally","range","rapid","ratio","reach","ready","realm","rebel","refer",
        "relax","reply","rifle","right","rigid","river","robot","rocky","roman","rough",
        "round","route","royal","rural","sadly","saint","salad","sauce","scale","scene",
        "scope","score","sense","serve","seven","shade","shake","shall","shape","share",
        "sharp","sheet","shelf","shell","shift","shine","shirt","shock","shoot","shore",
        "short","shown","sight","silly","since","sixth","sixty","skill","sleep","slice",
        "slide","slope","small","smart","smell","smile","smoke","snake","solar","solid",
        "solve","sorry","sound","south","space","spare","speak","speed","spend","spent",
        "spice","spite","split","spoke","sport","spray","staff","stage","stair","stake",
        "stand","stare","start","state","steam","steel","steep","steer","stern","stick",
        "still","stock","stone","stood","store","storm","story","strip","stuck","study",
        "stuff","style","sugar","suite","sunny","super","sweet","swift","swing","table",
        "taken","taste","taxes","teach","teeth","terry","thank","theft","their","theme",
        "there","these","thick","thing","think","third","those","three","threw","throw",
        "tight","timer","tired","title","today","token","topic","total","touch","tough",
        "tower","track","trade","trail","train","treat","trend","trial","tribe","trick",
        "tried","tries","truck","truly","trust","truth","twice","twist","tying","ultra",
        "uncle","under","union","unite","unity","until","upper","upset","urban","usage",
        "usual","valid","value","video","virus","visit","vital","vocal","voice","waste",
        "watch","water","weary","wedge","weird","wheat","wheel","where","which","while",
        "white","whole","whose","woman","world","worry","worse","worst","worth","would",
        "wound","write","wrong","wrote","yield","young","yours","youth","zebra",
    ]
}

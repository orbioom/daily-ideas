import Foundation

struct HskWord: Identifiable {
    let id: Int
    let character: String
    let pinyin: String
    let tone: Int          // 1-4 for tones, 5 for neutral
    let english: String
    let exampleSentence: String
    let exampleTranslation: String
}

// MARK: - HSK 1 Vocabulary (100 words)
let hskWords: [HskWord] = [
    // Pronouns
    HskWord(id: 1,  character: "我",    pinyin: "wǒ",       tone: 3, english: "I / me",           exampleSentence: "我是学生。",         exampleTranslation: "I am a student."),
    HskWord(id: 2,  character: "你",    pinyin: "nǐ",       tone: 3, english: "you",               exampleSentence: "你好吗？",           exampleTranslation: "How are you?"),
    HskWord(id: 3,  character: "他",    pinyin: "tā",       tone: 1, english: "he / him",          exampleSentence: "他是老师。",         exampleTranslation: "He is a teacher."),
    HskWord(id: 4,  character: "她",    pinyin: "tā",       tone: 1, english: "she / her",         exampleSentence: "她很漂亮。",         exampleTranslation: "She is beautiful."),
    HskWord(id: 5,  character: "我们",  pinyin: "wǒmen",    tone: 3, english: "we / us",           exampleSentence: "我们是朋友。",       exampleTranslation: "We are friends."),
    HskWord(id: 6,  character: "你们",  pinyin: "nǐmen",    tone: 3, english: "you (plural)",      exampleSentence: "你们好！",           exampleTranslation: "Hello everyone!"),
    HskWord(id: 7,  character: "他们",  pinyin: "tāmen",    tone: 1, english: "they / them",       exampleSentence: "他们在哪里？",       exampleTranslation: "Where are they?"),

    // Core verbs
    HskWord(id: 8,  character: "是",    pinyin: "shì",      tone: 4, english: "to be",             exampleSentence: "我是中国人。",       exampleTranslation: "I am Chinese."),
    HskWord(id: 9,  character: "有",    pinyin: "yǒu",      tone: 3, english: "to have",           exampleSentence: "我有一本书。",       exampleTranslation: "I have a book."),
    HskWord(id: 10, character: "在",    pinyin: "zài",      tone: 4, english: "at / in",           exampleSentence: "我在家。",           exampleTranslation: "I am at home."),
    HskWord(id: 11, character: "不",    pinyin: "bù",       tone: 4, english: "not / no",          exampleSentence: "我不去。",           exampleTranslation: "I am not going."),
    HskWord(id: 12, character: "没",    pinyin: "méi",      tone: 2, english: "not have / no",     exampleSentence: "我没有时间。",       exampleTranslation: "I don't have time."),

    // Particles
    HskWord(id: 13, character: "的",    pinyin: "de",       tone: 5, english: "possessive particle", exampleSentence: "我的书在这里。",   exampleTranslation: "My book is here."),
    HskWord(id: 14, character: "了",    pinyin: "le",       tone: 5, english: "completion particle", exampleSentence: "我吃了。",         exampleTranslation: "I have eaten."),
    HskWord(id: 15, character: "吗",    pinyin: "ma",       tone: 5, english: "question particle",  exampleSentence: "你好吗？",         exampleTranslation: "Are you well?"),
    HskWord(id: 16, character: "呢",    pinyin: "ne",       tone: 5, english: "softening particle", exampleSentence: "你呢？",           exampleTranslation: "What about you?"),

    // Conjunctions / adverbs
    HskWord(id: 17, character: "和",    pinyin: "hé",       tone: 2, english: "and",               exampleSentence: "我和你是朋友。",     exampleTranslation: "You and I are friends."),
    HskWord(id: 18, character: "也",    pinyin: "yě",       tone: 3, english: "also",              exampleSentence: "我也去。",           exampleTranslation: "I am going too."),
    HskWord(id: 19, character: "都",    pinyin: "dōu",      tone: 1, english: "all / both",        exampleSentence: "我们都很好。",       exampleTranslation: "We are all fine."),
    HskWord(id: 20, character: "很",    pinyin: "hěn",      tone: 3, english: "very",              exampleSentence: "他很忙。",           exampleTranslation: "He is very busy."),

    // Adjectives
    HskWord(id: 21, character: "好",    pinyin: "hǎo",      tone: 3, english: "good",              exampleSentence: "今天天气很好。",     exampleTranslation: "The weather is good today."),
    HskWord(id: 22, character: "大",    pinyin: "dà",       tone: 4, english: "big",               exampleSentence: "这个房间很大。",     exampleTranslation: "This room is very big."),
    HskWord(id: 23, character: "小",    pinyin: "xiǎo",     tone: 3, english: "small",             exampleSentence: "那只猫很小。",       exampleTranslation: "That cat is very small."),
    HskWord(id: 24, character: "多",    pinyin: "duō",      tone: 1, english: "many / much",       exampleSentence: "这里人很多。",       exampleTranslation: "There are many people here."),
    HskWord(id: 25, character: "少",    pinyin: "shǎo",     tone: 3, english: "few / little",      exampleSentence: "我钱很少。",         exampleTranslation: "I have very little money."),

    // Nouns – people
    HskWord(id: 26, character: "人",    pinyin: "rén",      tone: 2, english: "person",            exampleSentence: "那个人是谁？",       exampleTranslation: "Who is that person?"),
    HskWord(id: 27, character: "中国",  pinyin: "zhōngguó", tone: 1, english: "China",             exampleSentence: "我来自中国。",       exampleTranslation: "I am from China."),
    HskWord(id: 28, character: "学生",  pinyin: "xuésheng", tone: 2, english: "student",           exampleSentence: "她是学生。",         exampleTranslation: "She is a student."),
    HskWord(id: 29, character: "老师",  pinyin: "lǎoshī",   tone: 3, english: "teacher",           exampleSentence: "老师很好。",         exampleTranslation: "The teacher is good."),
    HskWord(id: 30, character: "朋友",  pinyin: "péngyou",  tone: 2, english: "friend",            exampleSentence: "她是我的朋友。",     exampleTranslation: "She is my friend."),

    // Nouns – places / things
    HskWord(id: 31, character: "家",    pinyin: "jiā",      tone: 1, english: "home / family",     exampleSentence: "我回家了。",         exampleTranslation: "I went home."),
    HskWord(id: 32, character: "书",    pinyin: "shū",      tone: 1, english: "book",              exampleSentence: "这本书很好看。",     exampleTranslation: "This book is great."),
    HskWord(id: 33, character: "水",    pinyin: "shuǐ",     tone: 3, english: "water",             exampleSentence: "我要喝水。",         exampleTranslation: "I want to drink water."),

    // Action verbs
    HskWord(id: 34, character: "吃",    pinyin: "chī",      tone: 1, english: "eat",               exampleSentence: "我们去吃饭。",       exampleTranslation: "Let's go eat."),
    HskWord(id: 35, character: "喝",    pinyin: "hē",       tone: 1, english: "drink",             exampleSentence: "你喝茶吗？",         exampleTranslation: "Do you drink tea?"),
    HskWord(id: 36, character: "说",    pinyin: "shuō",     tone: 1, english: "speak / say",       exampleSentence: "他说汉语。",         exampleTranslation: "He speaks Chinese."),
    HskWord(id: 37, character: "看",    pinyin: "kàn",      tone: 4, english: "look / watch",      exampleSentence: "我看电视。",         exampleTranslation: "I watch TV."),
    HskWord(id: 38, character: "听",    pinyin: "tīng",     tone: 1, english: "listen",            exampleSentence: "我听音乐。",         exampleTranslation: "I listen to music."),
    HskWord(id: 39, character: "写",    pinyin: "xiě",      tone: 3, english: "write",             exampleSentence: "请写你的名字。",     exampleTranslation: "Please write your name."),
    HskWord(id: 40, character: "去",    pinyin: "qù",       tone: 4, english: "go",                exampleSentence: "我去学校。",         exampleTranslation: "I am going to school."),
    HskWord(id: 41, character: "来",    pinyin: "lái",      tone: 2, english: "come",              exampleSentence: "你来这里。",         exampleTranslation: "Come here."),
    HskWord(id: 42, character: "回",    pinyin: "huí",      tone: 2, english: "return",            exampleSentence: "我要回家。",         exampleTranslation: "I want to go home."),

    // Directional / positional
    HskWord(id: 43, character: "上",    pinyin: "shàng",    tone: 4, english: "up / above",        exampleSentence: "书在桌子上。",       exampleTranslation: "The book is on the table."),
    HskWord(id: 44, character: "下",    pinyin: "xià",      tone: 4, english: "down / below",      exampleSentence: "猫在桌子下。",       exampleTranslation: "The cat is under the table."),
    HskWord(id: 45, character: "里",    pinyin: "lǐ",       tone: 3, english: "inside",            exampleSentence: "书包里有什么？",     exampleTranslation: "What is inside the bag?"),
    HskWord(id: 46, character: "外",    pinyin: "wài",      tone: 4, english: "outside",           exampleSentence: "外面很冷。",         exampleTranslation: "It is cold outside."),
    HskWord(id: 47, character: "前",    pinyin: "qián",     tone: 2, english: "front / before",    exampleSentence: "学校前面有公园。",   exampleTranslation: "There is a park in front of the school."),
    HskWord(id: 48, character: "后",    pinyin: "hòu",      tone: 4, english: "back / after",      exampleSentence: "后面是超市。",       exampleTranslation: "There is a supermarket behind."),
    HskWord(id: 49, character: "左",    pinyin: "zuǒ",      tone: 3, english: "left",              exampleSentence: "向左转。",           exampleTranslation: "Turn left."),
    HskWord(id: 50, character: "右",    pinyin: "yòu",      tone: 4, english: "right",             exampleSentence: "向右转。",           exampleTranslation: "Turn right."),
    HskWord(id: 51, character: "中",    pinyin: "zhōng",    tone: 1, english: "middle",            exampleSentence: "他坐在中间。",       exampleTranslation: "He is sitting in the middle."),

    // Time
    HskWord(id: 52, character: "年",    pinyin: "nián",     tone: 2, english: "year",              exampleSentence: "今年是哪年？",       exampleTranslation: "What year is this year?"),
    HskWord(id: 53, character: "月",    pinyin: "yuè",      tone: 4, english: "month",             exampleSentence: "这个月很忙。",       exampleTranslation: "This month is very busy."),
    HskWord(id: 54, character: "日",    pinyin: "rì",       tone: 4, english: "day / sun",         exampleSentence: "今天是几日？",       exampleTranslation: "What day of the month is it today?"),
    HskWord(id: 55, character: "今天",  pinyin: "jīntiān",  tone: 1, english: "today",             exampleSentence: "今天天气很好。",     exampleTranslation: "The weather is nice today."),
    HskWord(id: 56, character: "明天",  pinyin: "míngtiān", tone: 2, english: "tomorrow",          exampleSentence: "明天见！",           exampleTranslation: "See you tomorrow!"),
    HskWord(id: 57, character: "昨天",  pinyin: "zuótiān",  tone: 2, english: "yesterday",         exampleSentence: "昨天我去了学校。",   exampleTranslation: "I went to school yesterday."),
    HskWord(id: 58, character: "时间",  pinyin: "shíjiān",  tone: 2, english: "time",              exampleSentence: "你有时间吗？",       exampleTranslation: "Do you have time?"),
    HskWord(id: 59, character: "现在",  pinyin: "xiànzài",  tone: 4, english: "now",               exampleSentence: "现在几点了？",       exampleTranslation: "What time is it now?"),
    HskWord(id: 60, character: "以前",  pinyin: "yǐqián",   tone: 3, english: "before / previously", exampleSentence: "以前我在北京。",   exampleTranslation: "I used to be in Beijing."),
    HskWord(id: 61, character: "以后",  pinyin: "yǐhòu",    tone: 3, english: "after / later",     exampleSentence: "以后再说。",         exampleTranslation: "We'll talk about it later."),

    // Activity / work
    HskWord(id: 62, character: "工作",  pinyin: "gōngzuò",  tone: 1, english: "work / job",        exampleSentence: "你的工作怎么样？",   exampleTranslation: "How is your work?"),
    HskWord(id: 63, character: "学习",  pinyin: "xuéxí",    tone: 2, english: "study / learn",     exampleSentence: "我在学习汉语。",     exampleTranslation: "I am studying Chinese."),
    HskWord(id: 64, character: "喜欢",  pinyin: "xǐhuān",   tone: 3, english: "like",              exampleSentence: "我喜欢吃苹果。",     exampleTranslation: "I like to eat apples."),
    HskWord(id: 65, character: "爱",    pinyin: "ài",       tone: 4, english: "love",              exampleSentence: "我爱我的家人。",     exampleTranslation: "I love my family."),

    // Modal verbs / ability
    HskWord(id: 66, character: "想",    pinyin: "xiǎng",    tone: 3, english: "want / think",      exampleSentence: "我想去北京。",       exampleTranslation: "I want to go to Beijing."),
    HskWord(id: 67, character: "要",    pinyin: "yào",      tone: 4, english: "want / need",       exampleSentence: "我要一杯水。",       exampleTranslation: "I need a glass of water."),
    HskWord(id: 68, character: "可以",  pinyin: "kěyǐ",     tone: 3, english: "can / may",         exampleSentence: "我可以坐这里吗？",   exampleTranslation: "May I sit here?"),
    HskWord(id: 69, character: "能",    pinyin: "néng",     tone: 2, english: "can / able",        exampleSentence: "你能帮我吗？",       exampleTranslation: "Can you help me?"),
    HskWord(id: 70, character: "会",    pinyin: "huì",      tone: 4, english: "know how to",       exampleSentence: "我会说汉语。",       exampleTranslation: "I know how to speak Chinese."),
    HskWord(id: 71, character: "知道",  pinyin: "zhīdào",   tone: 1, english: "know",              exampleSentence: "你知道吗？",         exampleTranslation: "Do you know?"),
    HskWord(id: 72, character: "觉得",  pinyin: "juéde",    tone: 2, english: "feel / think",      exampleSentence: "你觉得怎么样？",     exampleTranslation: "How do you feel?"),

    // Numbers
    HskWord(id: 73, character: "一",    pinyin: "yī",       tone: 1, english: "one",               exampleSentence: "我有一本书。",       exampleTranslation: "I have one book."),
    HskWord(id: 74, character: "二",    pinyin: "èr",       tone: 4, english: "two",               exampleSentence: "我有两个苹果。",     exampleTranslation: "I have two apples."),
    HskWord(id: 75, character: "三",    pinyin: "sān",      tone: 1, english: "three",             exampleSentence: "三个人。",           exampleTranslation: "Three people."),
    HskWord(id: 76, character: "四",    pinyin: "sì",       tone: 4, english: "four",              exampleSentence: "四点钟见。",         exampleTranslation: "See you at four o'clock."),
    HskWord(id: 77, character: "五",    pinyin: "wǔ",       tone: 3, english: "five",              exampleSentence: "五个朋友。",         exampleTranslation: "Five friends."),
    HskWord(id: 78, character: "六",    pinyin: "liù",      tone: 4, english: "six",               exampleSentence: "六月份。",           exampleTranslation: "The month of June."),
    HskWord(id: 79, character: "七",    pinyin: "qī",       tone: 1, english: "seven",             exampleSentence: "七天一个星期。",     exampleTranslation: "Seven days a week."),
    HskWord(id: 80, character: "八",    pinyin: "bā",       tone: 1, english: "eight",             exampleSentence: "八点上课。",         exampleTranslation: "Class starts at eight."),
    HskWord(id: 81, character: "九",    pinyin: "jiǔ",      tone: 3, english: "nine",              exampleSentence: "九月。",             exampleTranslation: "September."),
    HskWord(id: 82, character: "十",    pinyin: "shí",      tone: 2, english: "ten",               exampleSentence: "十个人。",           exampleTranslation: "Ten people."),
    HskWord(id: 83, character: "百",    pinyin: "bǎi",      tone: 3, english: "hundred",           exampleSentence: "一百块钱。",         exampleTranslation: "One hundred yuan."),
    HskWord(id: 84, character: "千",    pinyin: "qiān",     tone: 1, english: "thousand",          exampleSentence: "一千本书。",         exampleTranslation: "One thousand books."),

    // Question words
    HskWord(id: 85, character: "什么",  pinyin: "shénme",   tone: 2, english: "what",              exampleSentence: "这是什么？",         exampleTranslation: "What is this?"),
    HskWord(id: 86, character: "哪",    pinyin: "nǎ",       tone: 3, english: "which",             exampleSentence: "你去哪？",           exampleTranslation: "Where are you going?"),
    HskWord(id: 87, character: "谁",    pinyin: "shuí",     tone: 2, english: "who",               exampleSentence: "他是谁？",           exampleTranslation: "Who is he?"),
    HskWord(id: 88, character: "哪里",  pinyin: "nǎlǐ",     tone: 3, english: "where",             exampleSentence: "你住在哪里？",       exampleTranslation: "Where do you live?"),
    HskWord(id: 89, character: "怎么",  pinyin: "zěnme",    tone: 3, english: "how",               exampleSentence: "你怎么去？",         exampleTranslation: "How are you getting there?"),
    HskWord(id: 90, character: "为什么", pinyin: "wèishénme", tone: 4, english: "why",             exampleSentence: "你为什么哭？",       exampleTranslation: "Why are you crying?"),
    HskWord(id: 91, character: "多少",  pinyin: "duōshao",  tone: 1, english: "how many / how much", exampleSentence: "多少钱？",         exampleTranslation: "How much does it cost?"),
    HskWord(id: 92, character: "几",    pinyin: "jǐ",       tone: 3, english: "how many / several", exampleSentence: "你几岁了？",        exampleTranslation: "How old are you?"),

    // Demonstratives
    HskWord(id: 93, character: "这",    pinyin: "zhè",      tone: 4, english: "this",              exampleSentence: "这是我的书。",       exampleTranslation: "This is my book."),
    HskWord(id: 94, character: "那",    pinyin: "nà",       tone: 4, english: "that",              exampleSentence: "那是你的吗？",       exampleTranslation: "Is that yours?"),
    HskWord(id: 95, character: "这里",  pinyin: "zhèlǐ",    tone: 4, english: "here",              exampleSentence: "请坐在这里。",       exampleTranslation: "Please sit here."),
    HskWord(id: 96, character: "那里",  pinyin: "nàlǐ",     tone: 4, english: "there",             exampleSentence: "他在那里。",         exampleTranslation: "He is over there."),

    // Polite expressions & common phrases
    HskWord(id: 97,  character: "谢谢",  pinyin: "xièxie",    tone: 4, english: "thank you",       exampleSentence: "谢谢你的帮助！",     exampleTranslation: "Thank you for your help!"),
    HskWord(id: 98,  character: "对不起", pinyin: "duìbuqǐ",  tone: 4, english: "sorry",           exampleSentence: "对不起，我迟到了。", exampleTranslation: "Sorry, I am late."),
    HskWord(id: 99,  character: "没关系", pinyin: "méiguānxi", tone: 2, english: "no problem",     exampleSentence: "没关系，没事的。",   exampleTranslation: "No problem, it's fine."),
    HskWord(id: 100, character: "再见",  pinyin: "zàijiàn",   tone: 4, english: "goodbye",         exampleSentence: "明天见，再见！",     exampleTranslation: "See you tomorrow, goodbye!"),
]

extension HskWord {
    /// Look up a word by its integer ID
    static func find(id: Int) -> HskWord? {
        hskWords.first { $0.id == id }
    }

    /// Pinyin stripped of diacritics for display in tone quiz
    var pinyinNoTone: String {
        let base = pinyin
            .replacingOccurrences(of: "ā", with: "a").replacingOccurrences(of: "á", with: "a")
            .replacingOccurrences(of: "ǎ", with: "a").replacingOccurrences(of: "à", with: "a")
            .replacingOccurrences(of: "ē", with: "e").replacingOccurrences(of: "é", with: "e")
            .replacingOccurrences(of: "ě", with: "e").replacingOccurrences(of: "è", with: "e")
            .replacingOccurrences(of: "ī", with: "i").replacingOccurrences(of: "í", with: "i")
            .replacingOccurrences(of: "ǐ", with: "i").replacingOccurrences(of: "ì", with: "i")
            .replacingOccurrences(of: "ō", with: "o").replacingOccurrences(of: "ó", with: "o")
            .replacingOccurrences(of: "ǒ", with: "o").replacingOccurrences(of: "ò", with: "o")
            .replacingOccurrences(of: "ū", with: "u").replacingOccurrences(of: "ú", with: "u")
            .replacingOccurrences(of: "ǔ", with: "u").replacingOccurrences(of: "ù", with: "u")
            .replacingOccurrences(of: "ǖ", with: "ü").replacingOccurrences(of: "ǘ", with: "ü")
            .replacingOccurrences(of: "ǚ", with: "ü").replacingOccurrences(of: "ǜ", with: "ü")
        return base
    }
}

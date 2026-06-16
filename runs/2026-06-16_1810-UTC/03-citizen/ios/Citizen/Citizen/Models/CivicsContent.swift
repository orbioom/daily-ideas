import Foundation

/// Bundled, public-domain content: the official USCIS 100 civics questions
/// (2008 version — the current operative naturalization test), plus the
/// official reading & writing vocabulary lists.
///
/// Source: U.S. Citizenship and Immigration Services (USCIS) study materials,
/// which are works of the U.S. federal government and in the public domain.
/// Wording and acceptable answers follow the canonical USCIS list.
enum CivicsContent {

    // MARK: - The official 100 civics questions

    static let questions: [CivicsQuestion] = [

        // ===== AMERICAN GOVERNMENT — A: Principles of American Democracy (1-12) =====
        CivicsQuestion(number: 1, section: .principlesOfDemocracy,
            prompt: "What is the supreme law of the land?",
            acceptableAnswers: ["the Constitution"]),
        CivicsQuestion(number: 2, section: .principlesOfDemocracy,
            prompt: "What does the Constitution do?",
            acceptableAnswers: ["sets up the government",
                                "defines the government",
                                "protects basic rights of Americans"]),
        CivicsQuestion(number: 3, section: .principlesOfDemocracy,
            prompt: "The idea of self-government is in the first three words of the Constitution. What are these words?",
            acceptableAnswers: ["We the People"]),
        CivicsQuestion(number: 4, section: .principlesOfDemocracy,
            prompt: "What is an amendment?",
            acceptableAnswers: ["a change (to the Constitution)",
                                "an addition (to the Constitution)"]),
        CivicsQuestion(number: 5, section: .principlesOfDemocracy,
            prompt: "What do we call the first ten amendments to the Constitution?",
            acceptableAnswers: ["the Bill of Rights"]),
        CivicsQuestion(number: 6, section: .principlesOfDemocracy,
            prompt: "What is one right or freedom from the First Amendment?",
            acceptableAnswers: ["speech", "religion", "assembly", "press",
                                "petition the government"]),
        CivicsQuestion(number: 7, section: .principlesOfDemocracy,
            prompt: "How many amendments does the Constitution have?",
            acceptableAnswers: ["twenty-seven (27)"]),
        CivicsQuestion(number: 8, section: .principlesOfDemocracy,
            prompt: "What did the Declaration of Independence do?",
            acceptableAnswers: ["announced our independence (from Great Britain)",
                                "declared our independence (from Great Britain)",
                                "said that the United States is free (from Great Britain)"]),
        CivicsQuestion(number: 9, section: .principlesOfDemocracy,
            prompt: "What are two rights in the Declaration of Independence?",
            acceptableAnswers: ["life", "liberty", "pursuit of happiness"]),
        CivicsQuestion(number: 10, section: .principlesOfDemocracy,
            prompt: "What is freedom of religion?",
            acceptableAnswers: ["You can practice any religion, or not practice a religion."]),
        CivicsQuestion(number: 11, section: .principlesOfDemocracy,
            prompt: "What is the economic system in the United States?",
            acceptableAnswers: ["capitalist economy", "market economy"]),
        CivicsQuestion(number: 12, section: .principlesOfDemocracy,
            prompt: "What is the \u{201C}rule of law\u{201D}?",
            acceptableAnswers: ["Everyone must follow the law.",
                                "Leaders must obey the law.",
                                "Government must obey the law.",
                                "No one is above the law."]),

        // ===== AMERICAN GOVERNMENT — B: System of Government (13-47) =====
        CivicsQuestion(number: 13, section: .systemOfGovernment,
            prompt: "Name one branch or part of the government.",
            acceptableAnswers: ["Congress", "legislative", "President", "executive",
                                "the courts", "judicial"]),
        CivicsQuestion(number: 14, section: .systemOfGovernment,
            prompt: "What stops one branch of government from becoming too powerful?",
            acceptableAnswers: ["checks and balances", "separation of powers"]),
        CivicsQuestion(number: 15, section: .systemOfGovernment,
            prompt: "Who is in charge of the executive branch?",
            acceptableAnswers: ["the President"]),
        CivicsQuestion(number: 16, section: .systemOfGovernment,
            prompt: "Who makes federal laws?",
            acceptableAnswers: ["Congress", "Senate and House (of Representatives)",
                                "(U.S. or national) legislature"]),
        CivicsQuestion(number: 17, section: .systemOfGovernment,
            prompt: "What are the two parts of the U.S. Congress?",
            acceptableAnswers: ["the Senate and House (of Representatives)"]),
        CivicsQuestion(number: 18, section: .systemOfGovernment,
            prompt: "How many U.S. Senators are there?",
            acceptableAnswers: ["one hundred (100)"]),
        CivicsQuestion(number: 19, section: .systemOfGovernment,
            prompt: "We elect a U.S. Senator for how many years?",
            acceptableAnswers: ["six (6)"]),
        CivicsQuestion(number: 20, section: .systemOfGovernment,
            prompt: "Who is one of your state\u{2019}s U.S. Senators now?",
            acceptableAnswers: ["Answers will vary by state."],
            note: "Answer for YOUR state. Look up your current U.S. Senators on USA.gov. (D.C. and U.S. territories have no Senators.)",
            varies: true),
        CivicsQuestion(number: 21, section: .systemOfGovernment,
            prompt: "The House of Representatives has how many voting members?",
            acceptableAnswers: ["four hundred thirty-five (435)"]),
        CivicsQuestion(number: 22, section: .systemOfGovernment,
            prompt: "We elect a U.S. Representative for how many years?",
            acceptableAnswers: ["two (2)"]),
        CivicsQuestion(number: 23, section: .systemOfGovernment,
            prompt: "Name your U.S. Representative.",
            acceptableAnswers: ["Answers will vary."],
            note: "Answer for YOUR district. Look up your current U.S. Representative on USA.gov.",
            varies: true),
        CivicsQuestion(number: 24, section: .systemOfGovernment,
            prompt: "Who does a U.S. Senator represent?",
            acceptableAnswers: ["all people of the state"]),
        CivicsQuestion(number: 25, section: .systemOfGovernment,
            prompt: "Why do some states have more Representatives than other states?",
            acceptableAnswers: ["(because of) the state\u{2019}s population",
                                "(because) they have more people",
                                "(because) some states have more people"]),
        CivicsQuestion(number: 26, section: .systemOfGovernment,
            prompt: "We elect a President for how many years?",
            acceptableAnswers: ["four (4)"]),
        CivicsQuestion(number: 27, section: .systemOfGovernment,
            prompt: "In what month do we vote for President?",
            acceptableAnswers: ["November"]),
        CivicsQuestion(number: 28, section: .systemOfGovernment,
            prompt: "What is the name of the President of the United States now?",
            acceptableAnswers: ["Answers will vary by current officeholder."],
            note: "Answer for the CURRENT President. Verify on USA.gov / whitehouse.gov.",
            varies: true),
        CivicsQuestion(number: 29, section: .systemOfGovernment,
            prompt: "What is the name of the Vice President of the United States now?",
            acceptableAnswers: ["Answers will vary by current officeholder."],
            note: "Answer for the CURRENT Vice President. Verify on USA.gov / whitehouse.gov.",
            varies: true),
        CivicsQuestion(number: 30, section: .systemOfGovernment,
            prompt: "If the President can no longer serve, who becomes President?",
            acceptableAnswers: ["the Vice President"]),
        CivicsQuestion(number: 31, section: .systemOfGovernment,
            prompt: "If both the President and the Vice President can no longer serve, who becomes President?",
            acceptableAnswers: ["the Speaker of the House"]),
        CivicsQuestion(number: 32, section: .systemOfGovernment,
            prompt: "Who is the Commander in Chief of the military?",
            acceptableAnswers: ["the President"]),
        CivicsQuestion(number: 33, section: .systemOfGovernment,
            prompt: "Who signs bills to become laws?",
            acceptableAnswers: ["the President"]),
        CivicsQuestion(number: 34, section: .systemOfGovernment,
            prompt: "Who vetoes bills?",
            acceptableAnswers: ["the President"]),
        CivicsQuestion(number: 35, section: .systemOfGovernment,
            prompt: "What does the President\u{2019}s Cabinet do?",
            acceptableAnswers: ["advises the President"]),
        CivicsQuestion(number: 36, section: .systemOfGovernment,
            prompt: "What are two Cabinet-level positions?",
            acceptableAnswers: ["Secretary of Agriculture", "Secretary of Commerce",
                                "Secretary of Defense", "Secretary of Education",
                                "Secretary of Energy", "Secretary of Health and Human Services",
                                "Secretary of Homeland Security", "Secretary of Housing and Urban Development",
                                "Secretary of the Interior", "Secretary of Labor",
                                "Secretary of State", "Secretary of Transportation",
                                "Secretary of the Treasury", "Secretary of Veterans Affairs",
                                "Attorney General", "Vice President"]),
        CivicsQuestion(number: 37, section: .systemOfGovernment,
            prompt: "What does the judicial branch do?",
            acceptableAnswers: ["reviews laws", "explains laws",
                                "resolves disputes (disagreements)",
                                "decides if a law goes against the Constitution"]),
        CivicsQuestion(number: 38, section: .systemOfGovernment,
            prompt: "What is the highest court in the United States?",
            acceptableAnswers: ["the Supreme Court"]),
        CivicsQuestion(number: 39, section: .systemOfGovernment,
            prompt: "How many justices are on the Supreme Court?",
            acceptableAnswers: ["nine (9)"],
            note: "The Supreme Court currently has nine justices, set by Congress."),
        CivicsQuestion(number: 40, section: .systemOfGovernment,
            prompt: "Who is the Chief Justice of the United States now?",
            acceptableAnswers: ["Answers will vary by current officeholder."],
            note: "Answer for the CURRENT Chief Justice. Verify on supremecourt.gov.",
            varies: true),
        CivicsQuestion(number: 41, section: .systemOfGovernment,
            prompt: "Under our Constitution, some powers belong to the federal government. What is one power of the federal government?",
            acceptableAnswers: ["to print money", "to declare war",
                                "to create an army", "to make treaties"]),
        CivicsQuestion(number: 42, section: .systemOfGovernment,
            prompt: "Under our Constitution, some powers belong to the states. What is one power of the states?",
            acceptableAnswers: ["provide schooling and education",
                                "provide protection (police)",
                                "provide safety (fire departments)",
                                "give a driver\u{2019}s license",
                                "approve zoning and land use"]),
        CivicsQuestion(number: 43, section: .systemOfGovernment,
            prompt: "Who is the Governor of your state now?",
            acceptableAnswers: ["Answers will vary by state."],
            note: "Answer for YOUR state. (D.C. residents may answer that D.C. does not have a Governor.) Verify on USA.gov.",
            varies: true),
        CivicsQuestion(number: 44, section: .systemOfGovernment,
            prompt: "What is the capital of your state?",
            acceptableAnswers: ["Answers will vary by state."],
            note: "Answer with YOUR state\u{2019}s capital. (D.C. residents answer that D.C. is not a state and has no capital; territory residents name their territory\u{2019}s capital.)",
            varies: true),
        CivicsQuestion(number: 45, section: .systemOfGovernment,
            prompt: "What are the two major political parties in the United States?",
            acceptableAnswers: ["Democratic and Republican"]),
        CivicsQuestion(number: 46, section: .systemOfGovernment,
            prompt: "What is the political party of the President now?",
            acceptableAnswers: ["Answers will vary by current officeholder."],
            note: "Answer for the CURRENT President\u{2019}s party. Verify on USA.gov.",
            varies: true),
        CivicsQuestion(number: 47, section: .systemOfGovernment,
            prompt: "What is the name of the Speaker of the House of Representatives now?",
            acceptableAnswers: ["Answers will vary by current officeholder."],
            note: "Answer for the CURRENT Speaker of the House. Verify on house.gov.",
            varies: true),

        // ===== AMERICAN GOVERNMENT — C: Rights and Responsibilities (48-57) =====
        CivicsQuestion(number: 48, section: .rightsAndResponsibilities,
            prompt: "There are four amendments to the Constitution about who can vote. Describe one of them.",
            acceptableAnswers: ["Citizens eighteen (18) and older (can vote).",
                                "You don\u{2019}t have to pay (a poll tax) to vote.",
                                "Any citizen can vote. (Women and men can vote.)",
                                "A male citizen of any race (can vote)."]),
        CivicsQuestion(number: 49, section: .rightsAndResponsibilities,
            prompt: "What is one responsibility that is only for United States citizens?",
            acceptableAnswers: ["serve on a jury", "vote in a federal election"]),
        CivicsQuestion(number: 50, section: .rightsAndResponsibilities,
            prompt: "Name one right only for United States citizens.",
            acceptableAnswers: ["vote in a federal election", "run for federal office"]),
        CivicsQuestion(number: 51, section: .rightsAndResponsibilities,
            prompt: "What are two rights of everyone living in the United States?",
            acceptableAnswers: ["freedom of expression", "freedom of speech",
                                "freedom of assembly", "freedom to petition the government",
                                "freedom of religion", "the right to bear arms"]),
        CivicsQuestion(number: 52, section: .rightsAndResponsibilities,
            prompt: "What do we show loyalty to when we say the Pledge of Allegiance?",
            acceptableAnswers: ["the United States", "the flag"]),
        CivicsQuestion(number: 53, section: .rightsAndResponsibilities,
            prompt: "What is one promise you make when you become a United States citizen?",
            acceptableAnswers: ["give up loyalty to other countries",
                                "defend the Constitution and laws of the United States",
                                "obey the laws of the United States",
                                "serve in the U.S. military (if needed)",
                                "serve (do important work for) the nation (if needed)",
                                "be loyal to the United States"]),
        CivicsQuestion(number: 54, section: .rightsAndResponsibilities,
            prompt: "How old do citizens have to be to vote for President?",
            acceptableAnswers: ["eighteen (18) and older"]),
        CivicsQuestion(number: 55, section: .rightsAndResponsibilities,
            prompt: "What are two ways that Americans can participate in their democracy?",
            acceptableAnswers: ["vote", "join a political party",
                                "help with a campaign", "join a civic group",
                                "join a community group",
                                "give an elected official your opinion on an issue",
                                "call Senators and Representatives",
                                "publicly support or oppose an issue or policy",
                                "run for office", "write to a newspaper"]),
        CivicsQuestion(number: 56, section: .rightsAndResponsibilities,
            prompt: "When is the last day you can send in federal income tax forms?",
            acceptableAnswers: ["April 15"]),
        CivicsQuestion(number: 57, section: .rightsAndResponsibilities,
            prompt: "When must all men register for the Selective Service?",
            acceptableAnswers: ["at age eighteen (18)", "between eighteen (18) and twenty-six (26)"]),

        // ===== AMERICAN HISTORY — A: Colonial Period and Independence (58-70) =====
        CivicsQuestion(number: 58, section: .colonialAndIndependence,
            prompt: "What is one reason colonists came to America?",
            acceptableAnswers: ["freedom", "political liberty", "religious freedom",
                                "economic opportunity", "practice their religion",
                                "escape persecution"]),
        CivicsQuestion(number: 59, section: .colonialAndIndependence,
            prompt: "Who lived in America before the Europeans arrived?",
            acceptableAnswers: ["American Indians", "Native Americans"]),
        CivicsQuestion(number: 60, section: .colonialAndIndependence,
            prompt: "What group of people was taken to America and sold as slaves?",
            acceptableAnswers: ["Africans", "people from Africa"]),
        CivicsQuestion(number: 61, section: .colonialAndIndependence,
            prompt: "Why did the colonists fight the British?",
            acceptableAnswers: ["because of high taxes (taxation without representation)",
                                "because the British army stayed in their houses (boarding, quartering)",
                                "because they didn\u{2019}t have self-government"]),
        CivicsQuestion(number: 62, section: .colonialAndIndependence,
            prompt: "Who wrote the Declaration of Independence?",
            acceptableAnswers: ["(Thomas) Jefferson"]),
        CivicsQuestion(number: 63, section: .colonialAndIndependence,
            prompt: "When was the Declaration of Independence adopted?",
            acceptableAnswers: ["July 4, 1776"]),
        CivicsQuestion(number: 64, section: .colonialAndIndependence,
            prompt: "There were 13 original states. Name three.",
            acceptableAnswers: ["New Hampshire", "Massachusetts", "Rhode Island",
                                "Connecticut", "New York", "New Jersey", "Pennsylvania",
                                "Delaware", "Maryland", "Virginia", "North Carolina",
                                "South Carolina", "Georgia"]),
        CivicsQuestion(number: 65, section: .colonialAndIndependence,
            prompt: "What happened at the Constitutional Convention?",
            acceptableAnswers: ["The Constitution was written.",
                                "The Founding Fathers wrote the Constitution."]),
        CivicsQuestion(number: 66, section: .colonialAndIndependence,
            prompt: "When was the Constitution written?",
            acceptableAnswers: ["1787"]),
        CivicsQuestion(number: 67, section: .colonialAndIndependence,
            prompt: "The Federalist Papers supported the passage of the U.S. Constitution. Name one of the writers.",
            acceptableAnswers: ["(James) Madison", "(Alexander) Hamilton",
                                "(John) Jay", "Publius"]),
        CivicsQuestion(number: 68, section: .colonialAndIndependence,
            prompt: "What is one thing Benjamin Franklin is famous for?",
            acceptableAnswers: ["U.S. diplomat",
                                "oldest member of the Constitutional Convention",
                                "first Postmaster General of the United States",
                                "writer of \u{201C}Poor Richard\u{2019}s Almanac\u{201D}",
                                "started the first free libraries"]),
        CivicsQuestion(number: 69, section: .colonialAndIndependence,
            prompt: "Who is the \u{201C}Father of Our Country\u{201D}?",
            acceptableAnswers: ["(George) Washington"]),
        CivicsQuestion(number: 70, section: .colonialAndIndependence,
            prompt: "Who was the first President?",
            acceptableAnswers: ["(George) Washington"]),

        // ===== AMERICAN HISTORY — B: 1800s (71-77) =====
        CivicsQuestion(number: 71, section: .eighteenHundreds,
            prompt: "What territory did the United States buy from France in 1803?",
            acceptableAnswers: ["the Louisiana Territory", "Louisiana"]),
        CivicsQuestion(number: 72, section: .eighteenHundreds,
            prompt: "Name one war fought by the United States in the 1800s.",
            acceptableAnswers: ["War of 1812", "Mexican-American War",
                                "Civil War", "Spanish-American War"]),
        CivicsQuestion(number: 73, section: .eighteenHundreds,
            prompt: "Name the U.S. war between the North and the South.",
            acceptableAnswers: ["the Civil War", "the War between the States"]),
        CivicsQuestion(number: 74, section: .eighteenHundreds,
            prompt: "Name one problem that led to the Civil War.",
            acceptableAnswers: ["slavery", "economic reasons", "states\u{2019} rights"]),
        CivicsQuestion(number: 75, section: .eighteenHundreds,
            prompt: "What was one important thing that Abraham Lincoln did?",
            acceptableAnswers: ["freed the slaves (Emancipation Proclamation)",
                                "saved (or preserved) the Union",
                                "led the United States during the Civil War"]),
        CivicsQuestion(number: 76, section: .eighteenHundreds,
            prompt: "What did the Emancipation Proclamation do?",
            acceptableAnswers: ["freed the slaves", "freed slaves in the Confederacy",
                                "freed slaves in the Confederate states",
                                "freed slaves in most Southern states"]),
        CivicsQuestion(number: 77, section: .eighteenHundreds,
            prompt: "What did Susan B. Anthony do?",
            acceptableAnswers: ["fought for women\u{2019}s rights", "fought for civil rights"]),

        // ===== AMERICAN HISTORY — C: Recent American History and Other (78-87) =====
        CivicsQuestion(number: 78, section: .recentAndOther,
            prompt: "Name one war fought by the United States in the 1900s.",
            acceptableAnswers: ["World War I", "World War II", "Korean War",
                                "Vietnam War", "(Persian) Gulf War"]),
        CivicsQuestion(number: 79, section: .recentAndOther,
            prompt: "Who was President during World War I?",
            acceptableAnswers: ["(Woodrow) Wilson"]),
        CivicsQuestion(number: 80, section: .recentAndOther,
            prompt: "Who was President during the Great Depression and World War II?",
            acceptableAnswers: ["(Franklin) Roosevelt"]),
        CivicsQuestion(number: 81, section: .recentAndOther,
            prompt: "Who did the United States fight in World War II?",
            acceptableAnswers: ["Japan, Germany, and Italy"]),
        CivicsQuestion(number: 82, section: .recentAndOther,
            prompt: "Before he was President, Eisenhower was a general. What war was he in?",
            acceptableAnswers: ["World War II"]),
        CivicsQuestion(number: 83, section: .recentAndOther,
            prompt: "During the Cold War, what was the main concern of the United States?",
            acceptableAnswers: ["Communism"]),
        CivicsQuestion(number: 84, section: .recentAndOther,
            prompt: "What movement tried to end racial discrimination?",
            acceptableAnswers: ["civil rights (movement)"]),
        CivicsQuestion(number: 85, section: .recentAndOther,
            prompt: "What did Martin Luther King, Jr. do?",
            acceptableAnswers: ["fought for civil rights",
                                "worked for equality for all Americans"]),
        CivicsQuestion(number: 86, section: .recentAndOther,
            prompt: "What major event happened on September 11, 2001, in the United States?",
            acceptableAnswers: ["Terrorists attacked the United States."]),
        CivicsQuestion(number: 87, section: .recentAndOther,
            prompt: "Name one American Indian tribe in the United States.",
            acceptableAnswers: ["Cherokee", "Navajo", "Sioux", "Chippewa", "Choctaw",
                                "Pueblo", "Apache", "Iroquois", "Creek", "Blackfeet",
                                "Seminole", "Cheyenne", "Arawak", "Shawnee", "Mohegan",
                                "Huron", "Oneida", "Lakota", "Crow", "Teton", "Hopi", "Inuit"],
            note: "USCIS officers are supplied a complete list of federally recognized tribes."),

        // ===== INTEGRATED CIVICS — A: Geography (88-95) =====
        CivicsQuestion(number: 88, section: .geography,
            prompt: "Name one of the two longest rivers in the United States.",
            acceptableAnswers: ["Missouri (River)", "Mississippi (River)"]),
        CivicsQuestion(number: 89, section: .geography,
            prompt: "What ocean is on the West Coast of the United States?",
            acceptableAnswers: ["Pacific (Ocean)"]),
        CivicsQuestion(number: 90, section: .geography,
            prompt: "What ocean is on the East Coast of the United States?",
            acceptableAnswers: ["Atlantic (Ocean)"]),
        CivicsQuestion(number: 91, section: .geography,
            prompt: "Name one U.S. territory.",
            acceptableAnswers: ["Puerto Rico", "U.S. Virgin Islands", "American Samoa",
                                "Northern Mariana Islands", "Guam"]),
        CivicsQuestion(number: 92, section: .geography,
            prompt: "Name one state that borders Canada.",
            acceptableAnswers: ["Maine", "New Hampshire", "Vermont", "New York",
                                "Pennsylvania", "Ohio", "Michigan", "Minnesota",
                                "North Dakota", "Montana", "Idaho", "Washington", "Alaska"]),
        CivicsQuestion(number: 93, section: .geography,
            prompt: "Name one state that borders Mexico.",
            acceptableAnswers: ["California", "Arizona", "New Mexico", "Texas"]),
        CivicsQuestion(number: 94, section: .geography,
            prompt: "What is the capital of the United States?",
            acceptableAnswers: ["Washington, D.C."]),
        CivicsQuestion(number: 95, section: .geography,
            prompt: "Where is the Statue of Liberty?",
            acceptableAnswers: ["New York (Harbor)", "Liberty Island",
                                "New Jersey", "near New York City", "on the Hudson (River)"]),

        // ===== INTEGRATED CIVICS — B: Symbols (96-98) =====
        CivicsQuestion(number: 96, section: .symbols,
            prompt: "Why does the flag have 13 stripes?",
            acceptableAnswers: ["because there were 13 original colonies",
                                "because the stripes represent the original colonies"]),
        CivicsQuestion(number: 97, section: .symbols,
            prompt: "Why does the flag have 50 stars?",
            acceptableAnswers: ["because there is one star for each state",
                                "because each star represents a state",
                                "because there are 50 states"]),
        CivicsQuestion(number: 98, section: .symbols,
            prompt: "What is the name of the national anthem?",
            acceptableAnswers: ["The Star-Spangled Banner"]),

        // ===== INTEGRATED CIVICS — C: Holidays (99-100) =====
        CivicsQuestion(number: 99, section: .holidays,
            prompt: "When do we celebrate Independence Day?",
            acceptableAnswers: ["July 4"]),
        CivicsQuestion(number: 100, section: .holidays,
            prompt: "Name two national U.S. holidays.",
            acceptableAnswers: ["New Year\u{2019}s Day", "Martin Luther King, Jr. Day",
                                "Presidents\u{2019} Day", "Memorial Day", "Independence Day",
                                "Labor Day", "Columbus Day", "Veterans Day",
                                "Thanksgiving", "Christmas"]),
    ]

    /// The 20 questions designated by USCIS for the 65/20 special exemption
    /// (applicants 65+ who have been LPRs for 20+ years). Marked with an asterisk
    /// on the official list.
    static let seniorExemptionNumbers: Set<Int> = [
        6, 11, 13, 17, 20, 27, 28, 44, 45, 49,
        54, 56, 70, 75, 78, 85, 94, 95, 97, 99,
    ]

    /// Convenience lookup by question number.
    static func question(number: Int) -> CivicsQuestion? {
        questions.first { $0.number == number }
    }

    static func questions(in category: CivicsCategory) -> [CivicsQuestion] {
        questions.filter { $0.category == category }
    }

    static var seniorQuestions: [CivicsQuestion] {
        questions.filter { seniorExemptionNumbers.contains($0.number) }
    }

    // MARK: - Official reading & writing vocabulary

    static let vocabulary: [VocabWord] = {
        var words: [VocabWord] = []

        func add(_ list: VocabWord.List, _ group: VocabWord.Group, _ items: [String]) {
            for item in items {
                words.append(VocabWord(word: item, list: list, group: group))
            }
        }

        // --- READING vocabulary ---
        add(.reading, .people, ["Abraham Lincoln", "George Washington"])
        add(.reading, .civics, [
            "American flag", "Bill of Rights", "capital", "citizen", "city",
            "Congress", "country", "Father of Our Country", "government", "President",
            "right", "Senators", "state", "states", "White House",
        ])
        add(.reading, .places, ["America", "United States", "U.S."])
        add(.reading, .holidays, [
            "Presidents\u{2019} Day", "Memorial Day", "Flag Day",
            "Independence Day", "Labor Day", "Columbus Day", "Thanksgiving",
        ])
        add(.reading, .questionWords, ["How", "What", "When", "Where", "Who", "Why"])
        add(.reading, .verbs, [
            "can", "come", "do", "does", "elects", "have", "has", "is", "are",
            "was", "be", "lives", "lived", "meet", "name", "pay", "vote", "want",
        ])
        add(.reading, .other, [
            "a", "for", "here", "in", "of", "on", "the", "to", "we",
            "colors", "dollar bill", "first", "largest", "many", "most",
            "north", "one", "people", "second", "south",
        ])

        // --- WRITING vocabulary ---
        add(.writing, .people, ["Adams", "Lincoln", "Washington"])
        add(.writing, .civics, [
            "American Indians", "capital", "citizens", "Civil War", "Congress",
            "Father of Our Country", "flag", "free", "freedom of speech",
            "President", "right", "Senators", "state", "states", "White House",
        ])
        add(.writing, .places, [
            "Alaska", "California", "Canada", "Delaware", "Mexico",
            "New York City", "United States", "Washington", "Washington, D.C.",
        ])
        add(.writing, .holidays, [
            "Presidents\u{2019} Day", "Memorial Day", "Flag Day",
            "Independence Day", "Labor Day", "Columbus Day", "Thanksgiving",
        ])
        add(.writing, .verbs, [
            "can", "come", "elect", "have", "has", "is", "was", "be",
            "lives", "lived", "meets", "pay", "vote", "want",
        ])
        add(.writing, .other, [
            "and", "during", "for", "here", "in", "of", "on", "the", "to", "we",
            "blue", "dollar bill", "fifty", "50", "first", "largest", "most",
            "north", "one", "one hundred", "100", "people", "red", "second",
            "south", "taxes", "white",
        ])

        return words
    }()

    static func vocabulary(list: VocabWord.List) -> [VocabWord] {
        vocabulary.filter { $0.list == list }
    }

    static func vocabulary(list: VocabWord.List, group: VocabWord.Group) -> [VocabWord] {
        vocabulary.filter { $0.list == list && $0.group == group }
    }

    // MARK: - Disclaimer

    static let disclaimer = """
    Citizen is an educational study aid based on the official USCIS 100 civics \
    questions (2008 version). Some answers depend on your state and on current \
    officeholders, which change over time — always verify those on USA.gov and \
    uscis.gov before your interview. Citizen is not affiliated with, endorsed by, \
    or sponsored by USCIS or the U.S. government.
    """
}

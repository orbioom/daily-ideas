import Foundation

/// The curated Learn library. Content is general health information — accurate and
/// non-prescriptive — and always points back to the reader's own clinician.
enum LearnLibrary {

    static let all: [Article] = [
        hotFlashes, triggers, sleepNightSweats, restBuilding,
        moodAnxiety, brainFog, hrtBasics, nonHormonal,
        boneHealth, heartHealth, movement, coolingDiet
    ]

    static func articles(in category: LearnCategory) -> [Article] {
        all.filter { $0.category == category }
    }

    static func article(id: String) -> Article? {
        all.first { $0.id == id }
    }

    // MARK: - Vasomotor

    static let hotFlashes = Article(
        id: "hot_flashes",
        category: .vasomotor,
        title: "What's actually happening in a hot flash",
        summary: "The biology of that sudden wave of heat — and why it's so common.",
        readMinutes: 4,
        isPro: false,
        sections: [
            ArticleSection(heading: "A narrowed comfort zone", paragraphs: [
                "A hot flash is a sudden sensation of heat, usually across the face, neck, and chest, often with flushing and sweating. It can last from a few seconds to several minutes.",
                "The leading explanation is that falling and fluctuating estrogen affects the brain's temperature-regulating centre in the hypothalamus. The body's 'thermoneutral zone' — the comfortable range before it tries to cool or warm you — appears to narrow. Small rises in core temperature that you'd normally never notice can trip the cooling response: blood vessels near the skin widen, you flush, and you sweat."
            ]),
            ArticleSection(heading: "Very common, very variable", paragraphs: [
                "Around three in four women experience hot flashes during the menopause transition. For some they're occasional and mild; for others they arrive many times a day and disrupt sleep and concentration.",
                "On average, vasomotor symptoms last several years, and a meaningful number of women have them for a decade or longer. Tracking yours over time — as you're doing in Equinox — helps you and your clinician see the real pattern rather than relying on memory."
            ]),
            ArticleSection(heading: "When to check in", paragraphs: [
                "Hot flashes are normal, but it's worth talking to your clinician if they're frequent, drenching, disrupting sleep, or affecting your daily life — there are effective options. Also mention flashes that are strongly one-sided, come with chest pain or a racing heart, or feel different from your usual pattern."
            ])
        ]
    )

    static let triggers = Article(
        id: "triggers",
        category: .vasomotor,
        title: "Common triggers — and how to spot yours",
        summary: "Heat, alcohol, caffeine, stress: small changes that can take the edge off.",
        readMinutes: 4,
        isPro: false,
        sections: [
            ArticleSection(heading: "Usual suspects", paragraphs: [
                "Triggers vary from person to person, but frequently reported ones include hot drinks, spicy food, alcohol (red wine especially), caffeine, warm rooms, tight or synthetic clothing, and stressful moments.",
                "A trigger doesn't cause menopause symptoms — it nudges an already-sensitive system over the edge. Removing one won't end hot flashes, but reducing a few of your personal triggers can genuinely lower how often and how hard they hit."
            ]),
            ArticleSection(heading: "Find your pattern", paragraphs: [
                "Because triggers are individual, the most useful thing you can do is notice your own. The notes field on each day's log is ideal for jotting what preceded a bad flash — a glass of wine, a heated meeting, a stuffy commute.",
                "After a few weeks, look back through Calendar and Insights for repeated pairings. Even a loose pattern ('worse on wine nights') gives you something concrete to experiment with."
            ]),
            ArticleSection(heading: "Gentle experiments", paragraphs: [
                "Try changing one thing at a time so you can tell what helped: swap an evening coffee for decaf, keep the bedroom cooler, dress in breathable layers you can shed, and have cold water within reach.",
                "If lifestyle tweaks aren't enough, that's not a failure — it's useful information to bring to your clinician, who can talk through medical options."
            ])
        ]
    )

    // MARK: - Sleep

    static let sleepNightSweats = Article(
        id: "night_sweats",
        category: .sleep,
        title: "Night sweats and broken sleep",
        summary: "Why menopause disrupts sleep, and practical ways to protect your nights.",
        readMinutes: 5,
        isPro: false,
        sections: [
            ArticleSection(heading: "Hot flashes after dark", paragraphs: [
                "Night sweats are simply hot flashes that happen while you sleep. They can wake you drenched, and even when they don't fully wake you, they fragment sleep and leave you groggy.",
                "Sleep problems in midlife aren't only about sweats, though. Shifting hormones, increased anxiety, and a higher rate of conditions like sleep apnoea all play a part, which is why rest can feel harder to come by even on cooler nights."
            ]),
            ArticleSection(heading: "Set the stage for cooler nights", paragraphs: [
                "Keep the bedroom cool and dark. Breathable cotton or moisture-wicking nightwear and bedding help, and many people find layered bedding they can throw off useful.",
                "A fan, a cool pillow, and a glass of cold water on the nightstand give you quick ways to recover without fully waking. Limiting alcohol and large meals close to bedtime can reduce night-time flashes for some."
            ]),
            ArticleSection(heading: "Protect your sleep rhythm", paragraphs: [
                "Consistency matters more than perfection: aim for similar sleep and wake times, wind down without bright screens, and get some daylight earlier in the day to anchor your body clock.",
                "If you regularly snore loudly, gasp, or feel unrefreshed despite enough hours, ask your clinician about sleep apnoea — it becomes more common after menopause and is very treatable."
            ])
        ]
    )

    static let restBuilding = Article(
        id: "rest_building",
        category: .sleep,
        title: "Rebuilding rest, one habit at a time",
        summary: "A calm, evidence-based wind-down routine for restless midlife nights.",
        readMinutes: 4,
        isPro: true,
        sections: [
            ArticleSection(heading: "The case for a routine", paragraphs: [
                "Cognitive behavioural therapy for insomnia (CBT-I) is the best-supported non-drug approach to long-term sleep problems, and it works in midlife too. Its core ideas are simple and you can start some of them yourself.",
                "The goal is to rebuild a strong association between your bed and sleep, and to stop the anxious 'why am I still awake' spiral that keeps so many of us staring at the ceiling at 3am."
            ]),
            ArticleSection(heading: "Practical building blocks", paragraphs: [
                "Keep a steady wake-up time, even after a bad night. Use the bed mainly for sleep. If you're wide awake after about 20 minutes, get up, do something calm and dim, and return when sleepy.",
                "Build a 30–60 minute wind-down: lower the lights, step away from screens or use night settings, and do something soothing — a warm (not hot) shower, gentle stretching, reading, or slow breathing."
            ]),
            ArticleSection(heading: "Be kind to the process", paragraphs: [
                "Sleep improves gradually, and the occasional rough night is normal. Track how you sleep in Equinox so you can see the trend rather than judging any single night.",
                "If insomnia persists for weeks, talk to your clinician — they can point you to structured CBT-I programmes and review anything (including night sweats) that's getting in the way."
            ])
        ]
    )

    // MARK: - Mood

    static let moodAnxiety = Article(
        id: "mood_anxiety",
        category: .mood,
        title: "Mood, anxiety and irritability in midlife",
        summary: "Why feelings can shift during perimenopause — and what helps.",
        readMinutes: 5,
        isPro: false,
        sections: [
            ArticleSection(heading: "It's not 'all in your head'", paragraphs: [
                "Many women notice more mood swings, anxiety, low mood, or a shorter fuse during perimenopause. Hormonal fluctuations interact with sleep loss, life stress, and the brain's mood chemistry, so it's rarely one single cause.",
                "Perimenopause is also a window of higher risk for depression, particularly for those who've had depression before or who have severe hot flashes and poor sleep. Recognising this isn't alarmist — it means support is appropriate and effective."
            ]),
            ArticleSection(heading: "What tends to help", paragraphs: [
                "Protecting sleep, regular movement, time outdoors, and staying connected to people all support mood. Talking therapies such as CBT have good evidence for low mood and anxiety around menopause.",
                "For some, treating disruptive hot flashes and night sweats lifts mood indirectly by restoring sleep. Others benefit from specific mood treatments. There's no single right path — it's a conversation worth having."
            ]),
            ArticleSection(heading: "When to reach out sooner", paragraphs: [
                "Please speak to a clinician promptly if low mood lasts more than a couple of weeks, if you lose interest in things you usually enjoy, or if anxiety is hard to control. And if you ever have thoughts of harming yourself, seek urgent help — you deserve support right away."
            ])
        ]
    )

    static let brainFog = Article(
        id: "brain_fog",
        category: .mood,
        title: "Brain fog: real, common, usually temporary",
        summary: "Forgetfulness and fuzzy focus around menopause — and reassurance.",
        readMinutes: 3,
        isPro: false,
        sections: [
            ArticleSection(heading: "What the research says", paragraphs: [
                "Many women report 'brain fog' — word-finding trouble, forgetfulness, and harder concentration — during the transition. Studies do show small, measurable dips in some memory and processing tasks, especially in perimenopause.",
                "The reassuring part: for most people these changes are mild and tend to recover after the transition settles. They're strongly linked to poor sleep, hot flashes, stress, and mood — all of which are addressable."
            ]),
            ArticleSection(heading: "Working with your brain", paragraphs: [
                "Reduce the load: write things down, use reminders, and tackle demanding tasks when you're freshest. Protecting sleep and managing hot flashes often does more for focus than any 'brain' supplement.",
                "Movement, social connection, and mentally engaging activities all support cognition over time. If memory problems are severe, worsening, or interfering with daily function, mention them to your clinician to rule out other causes."
            ])
        ]
    )

    // MARK: - Hormones

    static let hrtBasics = Article(
        id: "hrt_basics",
        category: .hormones,
        title: "HRT basics, in plain language",
        summary: "What hormone therapy is, who it's for, and questions to ask.",
        readMinutes: 6,
        isPro: false,
        sections: [
            ArticleSection(heading: "What it is", paragraphs: [
                "Hormone replacement therapy (HRT, also called menopausal hormone therapy) replaces some of the estrogen the body makes less of around menopause, usually with progesterone added if you still have a uterus to protect the womb lining.",
                "It comes in several forms — tablets, skin patches, gels, sprays, and vaginal preparations — and the right choice depends on your symptoms, health history, and preferences."
            ]),
            ArticleSection(heading: "What it can help with", paragraphs: [
                "HRT is the most effective treatment for hot flashes and night sweats, and it helps many people with sleep, mood, and vaginal dryness. Started around the time of menopause, it also helps protect bone density.",
                "Low-dose vaginal estrogen specifically targets dryness, discomfort, and urinary symptoms, and works locally with very little absorbed into the body."
            ]),
            ArticleSection(heading: "Balancing benefits and risks", paragraphs: [
                "For most healthy women under 60 or within about 10 years of menopause, the benefits of HRT for symptom relief generally outweigh the risks. Risks vary by type, dose, route, your age, and personal and family history — which is exactly why it's an individual decision.",
                "This is general information, not advice for you specifically. A clinician can weigh your situation and tailor the type and dose, and review it over time."
            ]),
            ArticleSection(heading: "Good questions to bring", paragraphs: [
                "Consider asking: Is HRT suitable for me given my history? Which type and route would you suggest, and why? What benefits and risks apply to me? How will we review whether it's working? And what are my non-hormonal options if I'd prefer them?",
                "Your Equinox doctor report — your symptom range, hot-flash frequency, and cycle changes — gives that conversation a concrete starting point."
            ])
        ]
    )

    static let nonHormonal = Article(
        id: "non_hormonal",
        category: .hormones,
        title: "Non-hormonal options",
        summary: "Prescription and complementary approaches when HRT isn't right for you.",
        readMinutes: 5,
        isPro: true,
        sections: [
            ArticleSection(heading: "Why someone might choose them", paragraphs: [
                "Some people can't take HRT, others prefer not to. The good news is there are non-hormonal routes that can meaningfully reduce hot flashes and support mood and sleep.",
                "As always, what's appropriate depends on your health, other medications, and goals — a clinician can help you weigh them."
            ]),
            ArticleSection(heading: "Prescription approaches", paragraphs: [
                "Certain antidepressants (some SSRIs and SNRIs) can reduce hot flashes for some people, and may help mood too. Other prescription medicines used for hot flashes include gabapentin and clonidine, and newer non-hormonal options targeting the brain's temperature pathway have emerged in some countries.",
                "These have their own benefits and side effects, so they're prescribed and reviewed individually."
            ]),
            ArticleSection(heading: "Therapies and supplements", paragraphs: [
                "Cognitive behavioural therapy has good evidence for the distress of hot flashes, sleep, and mood. Mindfulness and paced breathing help some people cope, even if they don't eliminate symptoms.",
                "Supplements such as black cohosh, soy isoflavones, and evening primrose are widely used, but the evidence is mixed and quality varies between products. Importantly, 'natural' doesn't mean risk-free — some interact with medications or aren't suitable with certain conditions. Tell your clinician what you're taking."
            ])
        ]
    )

    // MARK: - Long term

    static let boneHealth = Article(
        id: "bone_health",
        category: .longTerm,
        title: "Protecting your bones",
        summary: "Estrogen and bone density — and steps that pay off for decades.",
        readMinutes: 4,
        isPro: false,
        sections: [
            ArticleSection(heading: "Why menopause matters for bone", paragraphs: [
                "Estrogen helps maintain bone. As levels fall around menopause, bone loss speeds up for several years, which raises the long-term risk of osteoporosis and fractures.",
                "This happens quietly — there are usually no symptoms until a break — which is why prevention is worth attention now rather than later."
            ]),
            ArticleSection(heading: "What builds and keeps bone", paragraphs: [
                "Weight-bearing and resistance exercise (walking, dancing, stair-climbing, strength training) signals bones to stay strong. Enough dietary calcium and adequate vitamin D support the raw materials.",
                "Not smoking and keeping alcohol moderate both protect bone. HRT also helps preserve bone density for those who use it, which can be part of the wider conversation with your clinician."
            ]),
            ArticleSection(heading: "Know your risk", paragraphs: [
                "Risk is higher with a family history of osteoporosis, early menopause, certain medications, low body weight, and some medical conditions. Ask your clinician whether a bone-density scan is appropriate for you, especially if several of these apply."
            ])
        ]
    )

    static let heartHealth = Article(
        id: "heart_health",
        category: .longTerm,
        title: "Heart health after menopause",
        summary: "Why cardiovascular risk shifts in midlife, and what helps most.",
        readMinutes: 4,
        isPro: true,
        sections: [
            ArticleSection(heading: "A quiet shift", paragraphs: [
                "After menopause, the risk of heart disease rises and gradually catches up with men's. Changes in cholesterol, blood pressure, and where the body stores fat all play a part, alongside ageing itself.",
                "Heart disease is the leading cause of death in women, yet it's often under-recognised — so midlife is a good moment to pay it some attention."
            ]),
            ArticleSection(heading: "The high-impact basics", paragraphs: [
                "The fundamentals do the heavy lifting: regular physical activity, a diet rich in vegetables, fruit, whole grains, legumes, and healthy fats, not smoking, moderate alcohol, and managing stress and sleep.",
                "Keeping an eye on blood pressure, cholesterol, and blood sugar lets problems be caught early. These check-ups are a normal, sensible part of midlife care."
            ]),
            ArticleSection(heading: "Worth a conversation", paragraphs: [
                "Ask your clinician about your personal cardiovascular risk and what screening makes sense for you. If you have new chest pain, breathlessness, or palpitations, get them checked rather than assuming they're 'just menopause'."
            ])
        ]
    )

    // MARK: - Lifestyle

    static let movement = Article(
        id: "movement",
        category: .lifestyle,
        title: "Movement that fits midlife",
        summary: "How exercise helps symptoms, mood, bones, and heart all at once.",
        readMinutes: 4,
        isPro: false,
        sections: [
            ArticleSection(heading: "One habit, many wins", paragraphs: [
                "Regular movement is one of the few things that helps across the board in midlife: mood, sleep, energy, bone strength, heart health, and weight management all benefit.",
                "It won't switch off hot flashes for everyone, but the wider gains — and the sense of feeling more like yourself — make it one of the highest-value habits you can build."
            ]),
            ArticleSection(heading: "A balanced week", paragraphs: [
                "A good mix includes aerobic activity you enjoy (brisk walking, cycling, swimming, dancing), strength training a couple of times a week to protect muscle and bone, and some flexibility or balance work.",
                "General guidance suggests aiming for around 150 minutes of moderate activity a week plus two strength sessions — but the best routine is the one you'll actually keep. Start small and build."
            ]),
            ArticleSection(heading: "Start where you are", paragraphs: [
                "If you're new to exercise or have health conditions, begin gently and increase gradually; a clinician or physiotherapist can help you start safely. Logging your energy in Equinox can show you, over time, how movement and rest affect how you feel."
            ])
        ]
    )

    static let coolingDiet = Article(
        id: "cooling_diet",
        category: .lifestyle,
        title: "Cooling and eating for comfort",
        summary: "Simple cooling tactics and a menopause-friendly way of eating.",
        readMinutes: 4,
        isPro: true,
        sections: [
            ArticleSection(heading: "Staying cool", paragraphs: [
                "Keeping cool reduces both the frequency and the misery of hot flashes for many people. Dress in breathable layers you can remove, keep rooms and your bed cool, and have cold water and a small fan within reach.",
                "Whether you think in Celsius or Fahrenheit, the principle is the same: a slightly cooler environment gives your narrowed comfort zone more room before a flash is triggered."
            ]),
            ArticleSection(heading: "Eating with menopause in mind", paragraphs: [
                "There's no single 'menopause diet', but a pattern rich in vegetables, fruit, whole grains, legumes, nuts, and healthy fats (often described as Mediterranean-style) supports heart, bone, and overall health during these years.",
                "Enough calcium and vitamin D matter for bone. Limiting ultra-processed food, excess added sugar, and heavy alcohol tends to help energy, sleep, and weight — and for some, easing alcohol and caffeine reduces flashes too."
            ]),
            ArticleSection(heading: "Make it sustainable", paragraphs: [
                "Crash diets rarely help and can backfire. Small, consistent changes you can live with — an extra portion of vegetables, swapping a nightly drink, a regular eating rhythm — add up.",
                "If you have specific dietary needs or conditions, a clinician or dietitian can tailor this to you."
            ])
        ]
    )
}

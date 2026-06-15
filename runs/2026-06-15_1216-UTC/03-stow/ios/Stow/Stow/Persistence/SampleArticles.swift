import Foundation

/// Bundled, fully-readable sample articles seeded on first launch so every
/// screen is alive and the app works completely offline. Text is original or
/// public-domain-style essay prose written for Stow.
enum SampleArticles {

    struct Seed {
        var url: String
        var title: String
        var byline: String
        var siteName: String
        var tagNames: [String]
        var isFavorite: Bool
        var readingProgress: Double
        var blocks: [ContentBlock]
    }

    static func all(wpm: Int) -> [Article] {
        seeds.map { seed in
            let words = seed.blocks.reduce(0) { $0 + ArticleExtractor.wordCount(of: $1.text) }
            let minutes = max(1, Int((Double(words) / Double(max(60, wpm))).rounded(.up)))
            let excerpt = seed.blocks.first(where: { $0.kind == .paragraph })
                .map { String($0.text.prefix(180)) } ?? ""
            let article = Article(
                url: seed.url,
                title: seed.title,
                byline: seed.byline,
                siteName: seed.siteName,
                isFavorite: seed.isFavorite,
                readingProgress: seed.readingProgress,
                wordCount: words,
                estMinutes: minutes,
                excerpt: excerpt.count >= 180 ? excerpt + "…" : excerpt,
                source: .sample,
                blocks: seed.blocks
            )
            return article
        }
    }

    private static func h(_ t: String) -> ContentBlock { ContentBlock(kind: .heading, text: t) }
    private static func p(_ t: String) -> ContentBlock { ContentBlock(kind: .paragraph, text: t) }

    static let seeds: [Seed] = [
        Seed(
            url: "https://stow.app/samples/slow-web",
            title: "The Case for a Slower Web",
            byline: "Maya Ellison",
            siteName: "Field Notes",
            tagNames: ["Tech", "Essays"],
            isFavorite: true,
            readingProgress: 0.32,
            blocks: [
                p("Somewhere along the way, reading on the internet stopped feeling like reading. It became a kind of grazing — a restless sampling of headlines and fragments, punctuated by the small electric jolt of a new notification. We tell ourselves we are well informed, but mostly we are well interrupted."),
                p("The promise of the early web was abundance: every essay, every archive, every half-finished thought, all within reach. That promise was kept. What we did not anticipate was that abundance without attention is just noise with a search bar."),
                h("What we lost"),
                p("A long article asks something of you. It asks for fifteen quiet minutes and the willingness to follow a thought to its end. Those minutes have become strangely expensive. The same screen that holds the essay also holds your messages, your feeds, and a thousand other invitations to be somewhere else."),
                p("Reading-it-later was supposed to fix this. Save the article now, the thinking went, and read it in a calmer moment. But the calmer moment rarely arrives, and the saved articles pile up like unopened mail — a museum of intentions."),
                h("A different rhythm"),
                p("The fix is not another folder. It is a different rhythm. Strip the page down to its words. Remove the chrome, the ads, the related-content carousels engineered to pull you away. Let the text breathe on a warm background, in a typeface chosen for reading rather than for branding."),
                p("When you do this, something quietly remarkable happens. The article stops competing for your attention and simply offers itself. You read to the end. You remember what you read. You might even underline a sentence, the way you would in a paperback."),
                p("A slower web is not a nostalgic one. It is a deliberate one. It treats your attention as the scarce resource it actually is, and it builds tools that protect that resource instead of mining it. The technology to do this has existed for years. What has been missing is the will to value calm over engagement."),
                p("So save the long thing. Then actually read it, offline, with nothing else on the screen. You will be surprised how much you have been missing — not in volume, but in depth.")
            ]
        ),
        Seed(
            url: "https://stow.app/samples/owning-your-library",
            title: "On Owning Your Reading Library",
            byline: "Daniel Okafor",
            siteName: "The Margin",
            tagNames: ["Tech", "Privacy"],
            isFavorite: false,
            readingProgress: 0,
            blocks: [
                p("In 2025, a service that millions trusted to hold their saved articles announced it would shut down. Overnight, years of carefully collected reading lists became something fragile — exportable, perhaps, but no longer alive. It was a reminder that a library you do not control is a library on loan."),
                p("We have grown comfortable renting our digital lives. Our photos live on someone else's servers. Our notes sync through accounts we do not own. Our reading lists, too, have been entrusted to companies whose interests rarely align with ours for very long."),
                h("The quiet cost of the cloud"),
                p("There is nothing wrong with the cloud as a convenience. The trouble begins when convenience becomes dependence — when the only copy of something you care about lives on a machine you cannot reach, governed by terms you did not write."),
                p("An article you saved is a small thing. But a thousand of them, gathered over years, becomes a portrait of your curiosity. It is worth keeping that portrait where it cannot be deleted by a press release."),
                h("Local first"),
                p("The alternative is not complicated. Store the things you save on your own device. Extract the text once, keep it, and read it whether or not the original site still exists. No account to create, no server to trust, no monthly fee to forget to cancel."),
                p("This is what people mean by local-first software. The data is yours, on your hardware, fully usable offline. Sync, if you want it, is an option layered on top — never a precondition for access."),
                p("Owning your library will not make you read more. But it will mean that what you have chosen to keep stays kept, on your terms, for as long as you care to keep it. In a world of disappearing services, that quiet permanence is its own kind of luxury.")
            ]
        ),
        Seed(
            url: "https://stow.app/samples/walking",
            title: "Walking, and the Art of Noticing",
            byline: "Henry David Thoreau",
            siteName: "Public Domain",
            tagNames: ["Essays", "Nature"],
            isFavorite: true,
            readingProgress: 0.66,
            blocks: [
                p("I have met with but one or two persons in the course of my life who understood the art of Walking, that is, of taking walks, who had a genius, so to speak, for sauntering. The word is beautifully derived from idle people who roved about the country in the Middle Ages and asked charity under pretense of going to the Holy Land."),
                p("We should go forth on the shortest walk in the spirit of undying adventure, never to return; prepared to send back our embalmed hearts only, as relics to our desolate kingdoms. If you are ready to leave father and mother, and brother and sister, and wife and child and friends, and never see them again, then you are ready for a walk."),
                h("The wildness of the world"),
                p("I wish to speak a word for Nature, for absolute freedom and wildness, as contrasted with a freedom and culture merely civil — to regard man as an inhabitant, or a part and parcel of Nature, rather than a member of society."),
                p("In wildness is the preservation of the world. Every tree sends its fibers forth in search of the wild. The cities import it at any price. From the forest and wilderness come the tonics and barks which brace mankind."),
                p("When I would recreate myself, I seek the darkest wood, the thickest and most interminable, and to the citizen, most dismal swamp. I enter as a sacred place, a sanctum sanctorum. There is the strength, the marrow of Nature."),
                h("A return"),
                p("So we saunter toward the Holy Land, till one day the sun shall shine more brightly than ever he has done, shall perchance shine into our minds and hearts, and light up our whole lives with a great awakening light, as warm and serene and golden as on a bankside in autumn.")
            ]
        ),
        Seed(
            url: "https://stow.app/samples/attention-economy",
            title: "Reclaiming Attention in an Economy Built to Steal It",
            byline: "Priya Nair",
            siteName: "Long Form Weekly",
            tagNames: ["Tech", "Focus"],
            isFavorite: false,
            readingProgress: 0,
            blocks: [
                p("Attention is the only truly nonrenewable resource you possess. You can earn more money, build more skills, even, with luck, buy back some time. But the minutes of focus you spend today are gone for good. It is strange, then, how cheaply we give them away."),
                p("An entire industry has organized itself around capturing those minutes and reselling them. The feed is not designed to inform you; it is designed to retain you. Every autoplay, every infinite scroll, every red badge is a small machine optimized to keep you from leaving."),
                h("The myth of staying informed"),
                p("We justify the grazing as a duty. We must stay informed, we say. But staying informed and staying engaged are not the same thing. Real understanding comes from sustained attention to a single thing, not from skimming the surface of a thousand."),
                p("Consider how little you remember of yesterday's feed. Now consider how vividly you recall the last book that genuinely moved you. The difference is not the subject matter. It is the depth of attention the format allowed."),
                h("Building a wall around the work"),
                p("Reclaiming attention is less about willpower and more about design. Remove the slot machine from your reading. Put the article somewhere quiet, where no algorithm can reach in and tap you on the shoulder. Read one thing to its end before you allow yourself the next."),
                p("This is not asceticism. It is a refusal to let your most valuable resource be auctioned off in fractions of a second to the highest bidder. The reward is not merely productivity. It is the recovery of a kind of inner quiet that the feed has spent a decade eroding."),
                p("Start small. Choose one long article today. Read it without a second screen. Notice how your mind, given room, begins to actually think again. That feeling — slow, deep, uninterrupted — is what attention was always for.")
            ]
        ),
        Seed(
            url: "https://stow.app/samples/typography",
            title: "Why Good Typography Makes You Read More",
            byline: "Sol Bergmann",
            siteName: "Type & Tide",
            tagNames: ["Design"],
            isFavorite: false,
            readingProgress: 0.1,
            blocks: [
                p("Typography is the quiet craft of getting out of the way. When it works, you do not notice it at all; you simply find yourself reading, sentence after sentence, with an ease you cannot quite explain. When it fails, you feel the friction in your eyes long before you can name its cause."),
                p("Good reading typography is not about beauty for its own sake. It is about reducing the small frictions that accumulate over a thousand words and quietly exhaust the reader."),
                h("Measure, leading, and rest"),
                p("The first variable is measure — the width of the line. Too wide, and your eye loses its place on the return journey to the next line. Too narrow, and the rhythm of reading shatters into staccato fragments. A comfortable measure runs roughly sixty to seventy characters."),
                p("The second is leading — the space between lines. Generous leading gives each line room to breathe and keeps the eye from drifting upward into the line above. Cramped text feels claustrophobic in a way most readers feel but cannot articulate."),
                p("The third is contrast and warmth. Pure black on pure white is harsh under a bright screen; a softer ink on a warm paper-toned background is gentler over a long read. This is why so many readers instinctively reach for a sepia mode at night."),
                h("Letting the reader choose"),
                p("No single setting suits everyone. Some eyes prefer a serif; others read faster in a humanist sans. The kindest thing a reading tool can do is hand these controls to the reader and then disappear, letting each person tune the page to their own comfort."),
                p("Get these details right and something lovely happens: the reader stops fighting the page and starts inhabiting the text. They read longer, understand more, and remember it afterward. That is the whole job of typography — to make the act of reading feel like no effort at all.")
            ]
        ),
        Seed(
            url: "https://stow.app/samples/sea",
            title: "The Open Boat: Notes from the Sea",
            byline: "Stephen Crane",
            siteName: "Public Domain",
            tagNames: ["Essays", "Nature"],
            isFavorite: false,
            readingProgress: 0,
            blocks: [
                p("None of them knew the color of the sky. Their eyes glanced level, and were fastened upon the waves that swept toward them. These waves were of the hue of slate, save for the tops, which were of foaming white, and all of the men knew the colors of the sea."),
                p("The horizon narrowed and widened, and dipped and rose, and at all times its edge was jagged with waves that seemed thrust up in points like rocks. Many a man ought to have a bathtub larger than the boat which here rode upon the sea."),
                h("A correspondence with nature"),
                p("When it occurs to a man that nature does not regard him as important, and that she feels she would not maim the universe by disposing of him, he at first wishes to throw bricks at the temple, and he hates deeply the fact that there are no bricks and no temples."),
                p("A high cold star on a winter's night is the word he feels that she says to him. Thereafter he knows the pathos of his situation. The men in the boat had not discussed these matters, but each had probably reflected upon them in silence and according to his mind."),
                h("Comradeship"),
                p("It would be difficult to describe the subtle brotherhood of men that was here established on the seas. No one said that it was so. No one mentioned it. But it dwelt in the boat, and each man felt it warm him. They were a captain, an oiler, a cook, and a correspondent, and they were friends — friends in a more curiously iron-bound degree than may be common."),
                p("And after this devotion to the commander of the boat, there was this comradeship, that the correspondent, for instance, who had been taught to be cynical of men, knew even at the time was the best experience of his life.")
            ]
        )
    ]
}

import Foundation
import SwiftData

/// Seeds a small book of public-domain / traditional songs with chord charts and
/// two setlists, so every screen is populated on first launch.
enum SampleData {

    static func seed(into context: ModelContext) {
        let songs = [
            makeSong(context, "Amazing Grace", "John Newton (trad.)", "G", 72, 0, "3/4", [
                ("Verse 1", "[G]Amazing [G7]grace how [C]sweet the [G]sound\nThat [G]saved a [Em]wretch like [D]me\nI [G]once was [G7]lost but [C]now am [G]found\nWas [G]blind but [D]now I [G]see"),
                ("Verse 2", "'Twas [G]grace that [G7]taught my [C]heart to [G]fear\nAnd [G]grace my [Em]fears re[D]lieved\nHow [G]precious [G7]did that [C]grace ap[G]pear\nThe [G]hour I [D]first be[G]lieved")
            ]),
            makeSong(context, "House of the Rising Sun", "Traditional", "Am", 78, 0, "6/8", [
                ("Verse 1", "There [Am]is a [C]house in [D]New Or[F]leans\nThey [Am]call the [C]Rising [E]Sun\nAnd it's [Am]been the [C]ruin of [D]many a poor [F]boy\nAnd [Am]God I [E]know I'm [Am]one"),
                ("Verse 2", "My [Am]mother [C]was a [D]tailor [F]\nShe [Am]sewed my [C]new blue [E]jeans\nMy [Am]father [C]was a [D]gambling [F]man\nDown in [Am]New Or[E]leans")
            ]),
            makeSong(context, "Scarborough Fair", "Traditional", "Em", 96, 2, "3/4", [
                ("Verse 1", "[Em]Are you going to [D]Scarborough [Em]Fair?\n[G]Parsley, [Em]sage, rose[G]mary and [D]thyme\nRe[Em]member me to [G]one who lives [D]there\nFor [Em]once she [D]was a true love of [Em]mine")
            ]),
            makeSong(context, "Wayfaring Stranger", "Traditional", "Dm", 68, 0, "4/4", [
                ("Verse 1", "I'm [Dm]just a poor way[A]faring [Dm]stranger\nA[Dm]travelling through this [Gm]world of [Dm]woe\nBut [F]there's no sickness, [Dm]toil nor [A]danger\nIn [Dm]that bright [A]land to [Dm]which I go")
            ]),
            makeSong(context, "Will the Circle Be Unbroken", "Traditional", "C", 100, 0, "4/4", [
                ("Chorus", "Will the [C]circle be un[F]broken\nBy and [C]by, Lord, by and [G]by\nThere's a [C]better home a-[F]waiting\nIn the [C]sky, Lord, [G]in the [C]sky"),
                ("Verse 1", "I was [C]standing by my [F]window\nOn one [C]cold and cloudy [G]day\nWhen I [C]saw the hearse come [F]rolling\nFor to [C]carry my [G]mother a[C]way")
            ]),
            makeSong(context, "Down in the Valley", "Traditional", "D", 84, 0, "3/4", [
                ("Verse 1", "[D]Down in the valley, the [A7]valley so low\n[A7]Hang your head over, hear the wind [D]blow\nHear the wind [D]blow, dear, hear the wind [A7]blow\n[A7]Hang your head over, hear the wind [D]blow")
            ]),
            makeSong(context, "Shenandoah", "Traditional", "F", 60, 3, "4/4", [
                ("Verse 1", "Oh [F]Shenan[Bb]doah, I [F]long to [Dm]hear you\nA[Bb]way you [F]rolling [C]river\nOh [F]Shenan[Bb]doah, I [Dm]long to [F]hear you\nA[Bb]way, I'm [F]bound a[C]way, 'cross the [F]wide Missouri")
            ])
        ]

        // Setlist 1 — coffeehouse set with a couple transposed
        let set1 = Setlist(name: "Coffeehouse Set", venue: "The Wren", date: Date())
        context.insert(set1)
        let picks1: [(Int, Int, Int, String)] = [   // songIndex, transpose, capo, note
            (0, 0, 0, "Open soft"),
            (5, 2, 2, "Up to E"),
            (2, 0, 2, ""),
            (4, 0, 0, "Crowd sing-along")
        ]
        for (i, p) in picks1.enumerated() {
            let item = SetlistItem(order: i, song: songs[p.0], transpose: p.1, capo: p.2, note: p.3)
            item.setlist = set1
            context.insert(item)
        }

        // Setlist 2 — somber acoustic
        let set2 = Setlist(name: "Late Night Acoustic", venue: "Home", date: Date().addingTimeInterval(86400 * 7))
        context.insert(set2)
        let picks2: [(Int, Int, Int, String)] = [
            (1, 0, 0, ""), (3, 0, 0, ""), (6, 0, 3, "Fingerpick"), (0, -2, 0, "Lower for voice")
        ]
        for (i, p) in picks2.enumerated() {
            let item = SetlistItem(order: i, song: songs[p.0], transpose: p.1, capo: p.2, note: p.3)
            item.setlist = set2
            context.insert(item)
        }

        try? context.save()
    }

    @discardableResult
    private static func makeSong(_ context: ModelContext, _ title: String, _ artist: String,
                                 _ key: String, _ bpm: Int, _ capo: Int, _ time: String,
                                 _ sections: [(String, String)]) -> Song {
        let song = Song(title: title, artist: artist, key: key, bpm: bpm, capo: capo, timeSignature: time)
        context.insert(song)
        for (i, sec) in sections.enumerated() {
            let s = Section(name: sec.0, order: i, content: sec.1)
            s.song = song
            context.insert(s)
        }
        return song
    }
}

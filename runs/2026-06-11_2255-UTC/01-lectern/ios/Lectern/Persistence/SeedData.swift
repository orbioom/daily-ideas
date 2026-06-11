import Foundation

enum SeedData {
    static var samples: [Script] {
        [
            Script(
                title: "Welcome to Lectern",
                body: """
                This is a sample script so you can try the prompter right away. Tap the play button on this row and the text will roll past the amber guide line at a steady, even pace.

                While it rolls, tap once anywhere to show the controls. You can speed up or slow down in words per minute, grow or shrink the text, and drag the script up or down to seek.

                If you film yourself through teleprompter glass, flip the mirroring switches in the menu at the top right and the reflection will read the right way around.

                When you reach the end, Lectern logs the rehearsal — how long you read and at what pace — so you can watch your delivery improve in the Rehearsals tab.

                Now write something worth saying.
                """
            ),
            Script(
                title: "30-second video intro",
                body: """
                Hey, welcome back to the channel. Today we're covering the one thing almost everyone gets wrong when they start out — and the five-minute fix that solves it for good.

                Before we dive in: if you find this useful, the like button genuinely helps, and subscribing means you won't miss the follow-up where we go deeper.

                Alright. Let's get into it.
                """
            ),
            Script(
                title: "Wedding toast — draft",
                body: """
                Good evening everyone. For those who don't know me, I've had the questionable privilege of being this man's best friend for fifteen years.

                When he first told me about her, he talked for twenty minutes straight without taking a breath. I'd never seen him like that. I knew right then this day was coming.

                To the two of you: may your life together be long, loud, and full of the kind of laughter we've heard from your table all night.

                Please raise your glasses — to the happy couple.
                """
            ),
        ]
    }
}

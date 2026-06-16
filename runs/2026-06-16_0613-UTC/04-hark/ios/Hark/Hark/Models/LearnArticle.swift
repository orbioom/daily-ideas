import Foundation

/// Authored hearing-health articles. Static content, no network.
struct LearnArticle: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let summary: String
    /// Body as an ordered list of (heading, paragraph) sections.
    let sections: [Section]

    struct Section: Identifiable {
        let id = UUID()
        let heading: String
        let body: String
    }

    static let all: [LearnArticle] = [
        LearnArticle(
            icon: "ear.badge.checkmark",
            title: "How a pure-tone screening works",
            summary: "Why we play soft beeps at different pitches — and what a threshold actually means.",
            sections: [
                .init(heading: "The idea",
                      body: "Hearing isn't one number. You might hear low rumbles fine but miss high chirps. A pure-tone screening plays single pitches (frequencies) one at a time and finds the softest level you can still detect — that level is your threshold for that pitch."),
                .init(heading: "Up and down",
                      body: "Hark uses a classic up-down method. When you hear a tone, it gets quieter. When you miss one, it gets a little louder. Closing in from both directions lands on a stable threshold without taking all day."),
                .init(heading: "What the chart shows",
                      body: "Your thresholds plot onto an audiogram: pitch across the bottom, softness up the side (quieter is higher). Lower lines mean you heard softer tones. It's a picture of your screening, ear by ear.")
            ]
        ),
        LearnArticle(
            icon: "headphones",
            title: "Why headphones (and a quiet room) matter",
            summary: "A screening is only as honest as its conditions. Here's how to get a fair result.",
            sections: [
                .init(heading: "Headphones, always",
                      body: "Phone speakers leak sound to both ears and bounce off walls. Wired or sealed headphones keep each ear's test separate and consistent, which is the whole point of testing ears one at a time."),
                .init(heading: "Find quiet",
                      body: "Background noise masks soft tones, so you'll seem to hear worse than you do. A quiet room, no music, no fan — give the softest beeps a fair chance."),
                .init(heading: "Same setup each time",
                      body: "Trends matter more than any single number. Using the same headphones and a similar volume each time makes your history comparable to itself.")
            ]
        ),
        LearnArticle(
            icon: "exclamationmark.shield",
            title: "Screening vs. diagnosis",
            summary: "What Hark can and can't tell you — and when to see a professional.",
            sections: [
                .init(heading: "Hark is a screener",
                      body: "Hark is uncalibrated: it doesn't know your exact headphone output or room. It's great for spotting changes over time and nudging you to act — but it can't replace a calibrated audiogram from a clinic."),
                .init(heading: "Red flags",
                      body: "See a professional promptly for sudden hearing loss in one ear, ringing that starts abruptly, pain, drainage, or dizziness. These aren't things to track — they're things to get checked."),
                .init(heading: "Bring your data",
                      body: "If you do book an appointment, export your Hark history. A trend of your own measurements is a genuinely useful conversation starter.")
            ]
        ),
        LearnArticle(
            icon: "speaker.wave.3",
            title: "Protecting the hearing you have",
            summary: "Hearing loss from noise is common — and largely preventable.",
            sections: [
                .init(heading: "Loud + long = risk",
                      body: "Damage depends on both volume and time. A loud concert, a noisy commute, hours of high-volume earbuds — they add up. The higher the level, the less time it takes to do harm."),
                .init(heading: "Simple habits",
                      body: "Turn it down a notch, take quiet breaks, and use earplugs at loud events. Foam earplugs at a concert can protect the very high-frequency hearing that fades first."),
                .init(heading: "Re-check now and then",
                      body: "A quick monthly screening with Hark won't catch everything, but a drifting trend can prompt you to protect your ears before a small change becomes a big one.")
            ]
        )
    ]
}

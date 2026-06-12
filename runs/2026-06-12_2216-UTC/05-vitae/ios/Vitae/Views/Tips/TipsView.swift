import SwiftUI

private struct Tip: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let body: String
}

struct TipsView: View {
    private let sections: [(title: String, tips: [Tip])] = [
        ("Structure", [
            Tip(
                title: "One page until ~10 years in",
                icon: "doc.plaintext",
                body: "Recruiters spend well under a minute on a first pass. One tight page beats two loose ones; the Compact template exists for exactly this."
            ),
            Tip(
                title: "Most recent first, always",
                icon: "arrow.up.doc",
                body: "Reverse-chronological is what both humans and applicant-tracking systems expect. Don't get creative with the order — get creative inside the bullets."
            ),
            Tip(
                title: "The top third is prime real estate",
                icon: "rectangle.topthird.inset.filled",
                body: "Name, headline, and a summary that actually says something. 'Results-oriented team player' says nothing; 'shipped 3 consumer apps to 4M users' does."
            ),
        ]),
        ("Bullets", [
            Tip(
                title: "Start with a verb, end with a number",
                icon: "number",
                body: "'Led redesign of onboarding, lifting day-7 retention 18%.' Verb first shows action; the number proves it mattered. Even rough numbers ('cut build times in half') beat none."
            ),
            Tip(
                title: "Three to five bullets per role",
                icon: "list.bullet",
                body: "More than five and nobody reads any of them. Pick the achievements that match the job you want, not everything you did."
            ),
            Tip(
                title: "Achievements, not duties",
                icon: "trophy",
                body: "'Responsible for the newsletter' is a duty. 'Grew the newsletter from 2k to 18k subscribers' is a reason to hire you."
            ),
        ]),
        ("Polish", [
            Tip(
                title: "Match the ad's vocabulary",
                icon: "text.magnifyingglass",
                body: "ATS filters and tired recruiters both scan for the job ad's exact words. If the ad says 'stakeholder management', don't only write 'partner alignment'."
            ),
            Tip(
                title: "PDF, never a screenshot",
                icon: "doc.badge.arrow.up",
                body: "Vitae exports a real, crisp PDF with selectable text layout fidelity. Send that — never a photo or a .docx that breaks formatting on other machines."
            ),
            Tip(
                title: "Read it aloud once",
                icon: "waveform",
                body: "Anything you stumble over, a recruiter stumbles over. Cut clauses until each bullet reads in one breath."
            ),
        ]),
    ]

    var body: some View {
        NavigationStack {
            List {
                ForEach(sections, id: \.title) { section in
                    Section(section.title) {
                        ForEach(section.tips) { tip in
                            HStack(alignment: .top, spacing: 14) {
                                Image(systemName: tip.icon)
                                    .font(.body)
                                    .foregroundStyle(VitaeTheme.blue)
                                    .frame(width: 28)
                                    .accessibilityHidden(true)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(tip.title)
                                        .font(.body.weight(.semibold))
                                    Text(tip.body)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                            .accessibilityElement(children: .combine)
                        }
                    }
                }
            }
            .navigationTitle("Resume Guide")
        }
    }
}

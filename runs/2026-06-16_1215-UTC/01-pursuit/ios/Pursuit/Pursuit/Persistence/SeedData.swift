import Foundation
import SwiftData

/// Seeds a realistic sample pipeline on first launch. Guarded so it runs exactly once.
enum SeedData {
    /// Compact tuple describing one seed application.
    private struct Spec {
        let company: String
        let role: String
        let location: String
        let mode: WorkMode
        let status: AppStatus
        let salaryMin: Int?
        let salaryMax: Int?
        let source: AppSource
        let priority: Priority
        let excitement: Int
        let weeksAgoApplied: Int?      // nil = not yet applied (saved)
        let interviews: [(String, Int, InterviewMode, InterviewOutcome, Int)] // round, daysFromApply, mode, outcome, durationMin
        let contacts: [(String, ContactRole)]
        let tags: [String]
        let notes: String
        let url: String
        let followUpInDays: Int?       // nil = no follow-up
    }

    @MainActor
    static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<Application>()
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else { return }

        let now = Date()
        let cal = Calendar.current

        // Build a tag registry first.
        let tagColors: [String: String] = [
            "Dream role": "CB3A4A",
            "Backend": "1F9D5B",
            "Frontend": "2C6FD6",
            "Startup": "C9871A",
            "Big Tech": "7A5BD4",
            "Remote-first": "2C9CB0",
            "Referral": "D45B9A",
            "Quick apply": "5A5E73"
        ]
        var tagLookup: [String: Tag] = [:]
        for (name, hex) in tagColors {
            let tag = Tag(name: name, colorHex: hex)
            context.insert(tag)
            tagLookup[name] = tag
        }

        for spec in specs {
            let appliedDate: Date? = spec.weeksAgoApplied.flatMap {
                cal.date(byAdding: .day, value: -($0 * 7) - Int.random(in: 0...4), to: now)
            }
            let addedDate: Date = {
                if let applied = appliedDate {
                    return cal.date(byAdding: .day, value: -Int.random(in: 0...3), to: applied) ?? applied
                }
                return cal.date(byAdding: .day, value: -Int.random(in: 0...6), to: now) ?? now
            }()

            let app = Application(
                company: spec.company,
                role: spec.role,
                location: spec.location,
                workMode: spec.mode,
                status: spec.status,
                salaryMin: spec.salaryMin.map { Decimal($0) },
                salaryMax: spec.salaryMax.map { Decimal($0) },
                currencyCode: "USD",
                source: spec.source,
                urlString: spec.url,
                appliedDate: appliedDate,
                dateAdded: addedDate,
                priority: spec.priority,
                excitement: spec.excitement,
                notes: spec.notes
            )
            context.insert(app)

            // Tags
            for tagName in spec.tags {
                if let tag = tagLookup[tagName] {
                    app.tags.append(tag)
                }
            }

            // Creation event
            let created = ActivityEvent(kind: .created, date: addedDate,
                                        detail: "Added \(spec.company) — \(spec.role)")
            created.application = app
            context.insert(created)
            app.events.append(created)

            // Applied event
            if let applied = appliedDate {
                let ev = ActivityEvent(kind: .statusChanged, date: applied,
                                       detail: "Applied via \(spec.source.label)", status: .applied)
                ev.application = app
                context.insert(ev)
                app.events.append(ev)
            }

            // Status-progression events leading up to current status
            if let applied = appliedDate {
                let progression = progressionStages(to: spec.status)
                for (idx, stage) in progression.enumerated() {
                    let date = cal.date(byAdding: .day, value: (idx + 1) * Int.random(in: 4...9), to: applied) ?? applied
                    let clamped = min(date, now)
                    let ev = ActivityEvent(kind: .statusChanged, date: clamped,
                                           detail: "Moved to \(stage.label)", status: stage)
                    ev.application = app
                    context.insert(ev)
                    app.events.append(ev)
                }
            }

            // Interviews
            for (round, dayOffset, mode, outcome, dur) in spec.interviews {
                let base = appliedDate ?? addedDate
                let date = cal.date(byAdding: .day, value: dayOffset, to: base)
                let interview = Interview(
                    roundName: round,
                    scheduledDate: date,
                    durationMin: dur,
                    mode: mode,
                    interviewers: sampleInterviewers(),
                    prepNotes: prepNote(for: round),
                    notes: outcome == .pending ? "" : "Went \(outcome == .passed ? "well" : "okay").",
                    outcome: outcome
                )
                interview.application = app
                context.insert(interview)
                app.interviews.append(interview)

                if let date {
                    let ev = ActivityEvent(kind: .interviewScheduled, date: cal.date(byAdding: .day, value: -2, to: date) ?? date,
                                           detail: "Scheduled \(round) (\(mode.label))")
                    ev.application = app
                    context.insert(ev)
                    app.events.append(ev)
                }
            }

            // Contacts
            for (name, role) in spec.contacts {
                let contact = Contact(
                    name: name,
                    role: role,
                    email: emailFor(name: name, company: spec.company),
                    phone: "",
                    linkedIn: "linkedin.com/in/" + name.lowercased().replacingOccurrences(of: " ", with: ""),
                    notes: ""
                )
                contact.application = app
                context.insert(contact)
                app.contacts.append(contact)
            }

            // Follow-up
            if let days = spec.followUpInDays, !spec.status.isTerminal {
                app.followUpEnabled = true
                app.followUpDate = cal.date(byAdding: .day, value: days, to: now)
                let ev = ActivityEvent(kind: .followUp, date: now,
                                       detail: "Follow-up reminder set")
                ev.application = app
                context.insert(ev)
                app.events.append(ev)
            }
        }
    }

    /// Status stages crossed to arrive at `target` (excludes saved & applied which are handled separately).
    private static func progressionStages(to target: AppStatus) -> [AppStatus] {
        switch target {
        case .saved, .applied:
            return []
        case .screening:
            return [.screening]
        case .interview:
            return [.screening, .interview]
        case .offer:
            return [.screening, .interview, .offer]
        case .accepted:
            return [.screening, .interview, .offer, .accepted]
        case .rejected:
            return [.rejected]
        case .withdrawn:
            return [.withdrawn]
        }
    }

    private static func sampleInterviewers() -> String {
        let pool = ["Priya Shah", "Marcus Lee", "Dana Whitfield", "Aiden Brooks",
                    "Sofia Romero", "James Okafor", "Lena Müller", "Wei Chen"]
        let count = Int.random(in: 1...2)
        return pool.shuffled().prefix(count).joined(separator: ", ")
    }

    private static func prepNote(for round: String) -> String {
        if round.lowercased().contains("system") { return "Review distributed systems, caching, sharding." }
        if round.lowercased().contains("coding") { return "LeetCode mediums; arrays, graphs, DP." }
        if round.lowercased().contains("behavior") { return "Prepare STAR stories on conflict & leadership." }
        if round.lowercased().contains("recruiter") || round.lowercased().contains("screen") {
            return "Confirm comp range, timeline, and team fit."
        }
        return "Research the team, product, and recent launches."
    }

    private static func emailFor(name: String, company: String) -> String {
        let handle = name.lowercased().replacingOccurrences(of: " ", with: ".")
        let domain = company.lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: "")
        return "\(handle)@\(domain).com"
    }

    // MARK: - The 35 specs (spread across 10 weeks, all statuses)

    private static let specs: [Spec] = [
        Spec(company: "Stripe", role: "Senior iOS Engineer", location: "Remote (US)", mode: .remote,
             status: .interview, salaryMin: 185_000, salaryMax: 230_000, source: .referral, priority: .high, excitement: 5,
             weeksAgoApplied: 3,
             interviews: [("Recruiter screen", 4, .phone, .passed, 30), ("Coding round", 11, .video, .passed, 60), ("System design", 18, .video, .pending, 60)],
             contacts: [("Priya Shah", .recruiter), ("Marcus Lee", .hiringManager)],
             tags: ["Dream role", "Backend", "Remote-first"], notes: "Strong referral from a former teammate. Comp looks competitive.",
             url: "https://stripe.com/jobs", followUpInDays: 3),

        Spec(company: "Notion", role: "Product Engineer", location: "San Francisco, CA", mode: .hybrid,
             status: .offer, salaryMin: 170_000, salaryMax: 210_000, source: .linkedIn, priority: .high, excitement: 5,
             weeksAgoApplied: 6,
             interviews: [("Recruiter screen", 3, .phone, .passed, 30), ("Take-home", 8, .take_home, .passed, 0), ("Onsite loop", 20, .onsite, .passed, 240)],
             contacts: [("Dana Whitfield", .recruiter)],
             tags: ["Dream role", "Frontend"], notes: "Verbal offer received — negotiating equity.",
             url: "https://notion.so/careers", followUpInDays: 2),

        Spec(company: "Linear", role: "Frontend Engineer", location: "Remote (Global)", mode: .remote,
             status: .accepted, salaryMin: 160_000, salaryMax: 195_000, source: .companySite, priority: .high, excitement: 5,
             weeksAgoApplied: 9,
             interviews: [("Recruiter screen", 2, .phone, .passed, 30), ("Technical", 7, .video, .passed, 60), ("Final", 14, .video, .passed, 45)],
             contacts: [("Aiden Brooks", .hiringManager)],
             tags: ["Startup", "Remote-first", "Frontend"], notes: "Accepted! Start date confirmed.",
             url: "https://linear.app/careers", followUpInDays: nil),

        Spec(company: "Airbnb", role: "Staff Software Engineer", location: "Remote (US)", mode: .remote,
             status: .rejected, salaryMin: 210_000, salaryMax: 260_000, source: .recruiter, priority: .med, excitement: 4,
             weeksAgoApplied: 8,
             interviews: [("Recruiter screen", 3, .phone, .passed, 30), ("System design", 12, .video, .failed, 60)],
             contacts: [("Sofia Romero", .recruiter)],
             tags: ["Big Tech", "Backend"], notes: "Didn't pass system design — good feedback on scalability tradeoffs.",
             url: "https://careers.airbnb.com", followUpInDays: nil),

        Spec(company: "Figma", role: "Senior Frontend Engineer", location: "New York, NY", mode: .hybrid,
             status: .screening, salaryMin: 180_000, salaryMax: 220_000, source: .linkedIn, priority: .high, excitement: 5,
             weeksAgoApplied: 1,
             interviews: [("Recruiter screen", 5, .phone, .pending, 30)],
             contacts: [("James Okafor", .recruiter)],
             tags: ["Dream role", "Frontend", "Big Tech"], notes: "Recruiter reached out — scheduling first call.",
             url: "https://figma.com/careers", followUpInDays: 5),

        Spec(company: "Vercel", role: "Developer Experience Engineer", location: "Remote (Global)", mode: .remote,
             status: .applied, salaryMin: 150_000, salaryMax: 185_000, source: .companySite, priority: .med, excitement: 4,
             weeksAgoApplied: 2,
             interviews: [], contacts: [], tags: ["Startup", "Remote-first"], notes: "Applied with a tailored cover letter.",
             url: "https://vercel.com/careers", followUpInDays: 4),

        Spec(company: "Datadog", role: "Backend Engineer", location: "New York, NY", mode: .onsite,
             status: .applied, salaryMin: 165_000, salaryMax: 200_000, source: .indeed, priority: .med, excitement: 3,
             weeksAgoApplied: 3,
             interviews: [], contacts: [], tags: ["Backend", "Big Tech"], notes: "",
             url: "https://careers.datadoghq.com", followUpInDays: nil),

        Spec(company: "Ramp", role: "Full-Stack Engineer", location: "New York, NY", mode: .hybrid,
             status: .interview, salaryMin: 175_000, salaryMax: 215_000, source: .referral, priority: .high, excitement: 4,
             weeksAgoApplied: 4,
             interviews: [("Recruiter screen", 3, .phone, .passed, 30), ("Coding round", 9, .video, .passed, 60), ("Behavioral", 16, .video, .pending, 45)],
             contacts: [("Lena Müller", .recruiter), ("Wei Chen", .referral)],
             tags: ["Startup", "Referral"], notes: "Fast-moving process. Team seems sharp.",
             url: "https://ramp.com/careers", followUpInDays: 6),

        Spec(company: "Coinbase", role: "iOS Engineer", location: "Remote (US)", mode: .remote,
             status: .withdrawn, salaryMin: 160_000, salaryMax: 200_000, source: .linkedIn, priority: .low, excitement: 2,
             weeksAgoApplied: 5,
             interviews: [("Recruiter screen", 4, .phone, .passed, 30)],
             contacts: [], tags: ["Big Tech"], notes: "Withdrew — accepted competing process.",
             url: "https://coinbase.com/careers", followUpInDays: nil),

        Spec(company: "Retool", role: "Software Engineer, Platform", location: "San Francisco, CA", mode: .onsite,
             status: .applied, salaryMin: 170_000, salaryMax: 205_000, source: .companySite, priority: .med, excitement: 3,
             weeksAgoApplied: 1,
             interviews: [], contacts: [], tags: ["Startup", "Backend"], notes: "",
             url: "https://retool.com/careers", followUpInDays: 7),

        Spec(company: "Plaid", role: "Senior Backend Engineer", location: "Remote (US)", mode: .remote,
             status: .screening, salaryMin: 175_000, salaryMax: 215_000, source: .recruiter, priority: .high, excitement: 4,
             weeksAgoApplied: 2,
             interviews: [("Recruiter screen", 6, .phone, .pending, 30)],
             contacts: [("Priya Shah", .recruiter)],
             tags: ["Backend", "Remote-first"], notes: "Recruiter very responsive.",
             url: "https://plaid.com/careers", followUpInDays: 3),

        Spec(company: "Discord", role: "Mobile Engineer (iOS)", location: "Remote (US)", mode: .remote,
             status: .applied, salaryMin: 170_000, salaryMax: 210_000, source: .linkedIn, priority: .high, excitement: 5,
             weeksAgoApplied: 4,
             interviews: [], contacts: [], tags: ["Dream role", "Remote-first"], notes: "Big fan of the product.",
             url: "https://discord.com/careers", followUpInDays: nil),

        Spec(company: "Robinhood", role: "Software Engineer II", location: "Menlo Park, CA", mode: .hybrid,
             status: .rejected, salaryMin: 165_000, salaryMax: 195_000, source: .indeed, priority: .low, excitement: 2,
             weeksAgoApplied: 7,
             interviews: [], contacts: [], tags: ["Big Tech", "Quick apply"], notes: "Auto-rejection email.",
             url: "https://robinhood.com/careers", followUpInDays: nil),

        Spec(company: "Webflow", role: "Frontend Engineer", location: "Remote (Global)", mode: .remote,
             status: .interview, salaryMin: 150_000, salaryMax: 185_000, source: .companySite, priority: .med, excitement: 4,
             weeksAgoApplied: 3,
             interviews: [("Recruiter screen", 4, .phone, .passed, 30), ("Pair programming", 12, .video, .pending, 90)],
             contacts: [("Marcus Lee", .hiringManager)],
             tags: ["Frontend", "Remote-first"], notes: "Loved the pairing format.",
             url: "https://webflow.com/careers", followUpInDays: 5),

        Spec(company: "Brex", role: "Backend Engineer", location: "New York, NY", mode: .hybrid,
             status: .applied, salaryMin: 160_000, salaryMax: 200_000, source: .referral, priority: .med, excitement: 3,
             weeksAgoApplied: 2,
             interviews: [], contacts: [("Wei Chen", .referral)], tags: ["Referral", "Backend"], notes: "Referral submitted.",
             url: "https://brex.com/careers", followUpInDays: 4),

        Spec(company: "Asana", role: "Senior Software Engineer", location: "San Francisco, CA", mode: .hybrid,
             status: .saved, salaryMin: 175_000, salaryMax: 215_000, source: .linkedIn, priority: .med, excitement: 3,
             weeksAgoApplied: nil,
             interviews: [], contacts: [], tags: ["Big Tech"], notes: "Need to tailor resume before applying.",
             url: "https://asana.com/jobs", followUpInDays: nil),

        Spec(company: "Dropbox", role: "Staff iOS Engineer", location: "Remote (US)", mode: .remote,
             status: .saved, salaryMin: 200_000, salaryMax: 245_000, source: .companySite, priority: .high, excitement: 4,
             weeksAgoApplied: nil,
             interviews: [], contacts: [], tags: ["Dream role", "Remote-first"], notes: "Bookmark — closes in 2 weeks.",
             url: "https://dropbox.com/jobs", followUpInDays: nil),

        Spec(company: "Squarespace", role: "Frontend Engineer", location: "New York, NY", mode: .onsite,
             status: .saved, salaryMin: 150_000, salaryMax: 180_000, source: .indeed, priority: .low, excitement: 2,
             weeksAgoApplied: nil,
             interviews: [], contacts: [], tags: ["Frontend"], notes: "",
             url: "https://squarespace.com/careers", followUpInDays: nil),

        Spec(company: "Twilio", role: "Senior Backend Engineer", location: "Remote (US)", mode: .remote,
             status: .applied, salaryMin: 165_000, salaryMax: 205_000, source: .linkedIn, priority: .med, excitement: 3,
             weeksAgoApplied: 5,
             interviews: [], contacts: [], tags: ["Backend", "Remote-first"], notes: "No response yet — may be stale.",
             url: "https://twilio.com/company/jobs", followUpInDays: nil),

        Spec(company: "Cloudflare", role: "Systems Engineer", location: "Austin, TX", mode: .hybrid,
             status: .screening, salaryMin: 160_000, salaryMax: 200_000, source: .recruiter, priority: .med, excitement: 3,
             weeksAgoApplied: 2,
             interviews: [("Recruiter screen", 5, .phone, .pending, 30)],
             contacts: [("Sofia Romero", .recruiter)], tags: ["Backend"], notes: "",
             url: "https://cloudflare.com/careers", followUpInDays: 5),

        Spec(company: "Shopify", role: "Senior Developer", location: "Remote (Global)", mode: .remote,
             status: .applied, salaryMin: 155_000, salaryMax: 195_000, source: .companySite, priority: .med, excitement: 4,
             weeksAgoApplied: 6,
             interviews: [], contacts: [], tags: ["Remote-first"], notes: "Long time since applying.",
             url: "https://shopify.com/careers", followUpInDays: nil),

        Spec(company: "GitLab", role: "Backend Engineer (Go)", location: "Remote (Global)", mode: .remote,
             status: .interview, salaryMin: 150_000, salaryMax: 190_000, source: .companySite, priority: .high, excitement: 4,
             weeksAgoApplied: 4,
             interviews: [("Screening call", 3, .video, .passed, 45), ("Technical deep-dive", 11, .video, .pending, 60)],
             contacts: [("Aiden Brooks", .hiringManager)], tags: ["Backend", "Remote-first"], notes: "Async-friendly culture.",
             url: "https://about.gitlab.com/jobs", followUpInDays: 6),

        Spec(company: "Atlassian", role: "Senior Software Engineer", location: "Remote (US)", mode: .remote,
             status: .rejected, salaryMin: 170_000, salaryMax: 210_000, source: .linkedIn, priority: .med, excitement: 3,
             weeksAgoApplied: 7,
             interviews: [("Recruiter screen", 4, .phone, .passed, 30), ("Coding round", 10, .video, .failed, 60)],
             contacts: [], tags: ["Big Tech"], notes: "Coding round was tough.",
             url: "https://atlassian.com/careers", followUpInDays: nil),

        Spec(company: "HashiCorp", role: "Software Engineer, Terraform", location: "Remote (US)", mode: .remote,
             status: .applied, salaryMin: 160_000, salaryMax: 200_000, source: .referral, priority: .med, excitement: 4,
             weeksAgoApplied: 1,
             interviews: [], contacts: [("Wei Chen", .referral)], tags: ["Referral", "Backend"], notes: "",
             url: "https://hashicorp.com/careers", followUpInDays: 7),

        Spec(company: "Instacart", role: "iOS Engineer", location: "San Francisco, CA", mode: .hybrid,
             status: .applied, salaryMin: 165_000, salaryMax: 200_000, source: .indeed, priority: .low, excitement: 2,
             weeksAgoApplied: 3,
             interviews: [], contacts: [], tags: ["Quick apply"], notes: "",
             url: "https://instacart.careers", followUpInDays: nil),

        Spec(company: "Reddit", role: "Senior Backend Engineer", location: "Remote (US)", mode: .remote,
             status: .screening, salaryMin: 180_000, salaryMax: 220_000, source: .recruiter, priority: .high, excitement: 4,
             weeksAgoApplied: 2,
             interviews: [("Recruiter screen", 4, .phone, .pending, 30)],
             contacts: [("Dana Whitfield", .recruiter)], tags: ["Big Tech", "Backend"], notes: "",
             url: "https://redditinc.com/careers", followUpInDays: 4),

        Spec(company: "Affirm", role: "Full-Stack Engineer", location: "Remote (US)", mode: .remote,
             status: .applied, salaryMin: 160_000, salaryMax: 195_000, source: .linkedIn, priority: .med, excitement: 3,
             weeksAgoApplied: 4,
             interviews: [], contacts: [], tags: ["Remote-first"], notes: "",
             url: "https://affirm.com/careers", followUpInDays: nil),

        Spec(company: "Gusto", role: "Software Engineer", location: "Denver, CO", mode: .hybrid,
             status: .saved, salaryMin: 150_000, salaryMax: 185_000, source: .companySite, priority: .low, excitement: 3,
             weeksAgoApplied: nil,
             interviews: [], contacts: [], tags: ["Quick apply"], notes: "Consider — strong benefits.",
             url: "https://gusto.com/about/careers", followUpInDays: nil),

        Spec(company: "DoorDash", role: "Mobile Engineer", location: "Remote (US)", mode: .remote,
             status: .applied, salaryMin: 165_000, salaryMax: 205_000, source: .indeed, priority: .low, excitement: 2,
             weeksAgoApplied: 6,
             interviews: [], contacts: [], tags: ["Big Tech", "Quick apply"], notes: "Probably stale.",
             url: "https://doordash.com/careers", followUpInDays: nil),

        Spec(company: "Pinterest", role: "Senior iOS Engineer", location: "San Francisco, CA", mode: .hybrid,
             status: .interview, salaryMin: 180_000, salaryMax: 220_000, source: .referral, priority: .high, excitement: 5,
             weeksAgoApplied: 5,
             interviews: [("Recruiter screen", 3, .phone, .passed, 30), ("Coding round", 10, .video, .passed, 60), ("Onsite loop", 22, .onsite, .pending, 240)],
             contacts: [("James Okafor", .recruiter), ("Marcus Lee", .hiringManager)],
             tags: ["Dream role", "Referral"], notes: "Onsite next week — prepping hard.",
             url: "https://pinterestcareers.com", followUpInDays: 2),

        Spec(company: "Square", role: "Backend Engineer", location: "Remote (US)", mode: .remote,
             status: .applied, salaryMin: 165_000, salaryMax: 200_000, source: .companySite, priority: .med, excitement: 3,
             weeksAgoApplied: 2,
             interviews: [], contacts: [], tags: ["Backend"], notes: "",
             url: "https://block.xyz/careers", followUpInDays: 5),

        Spec(company: "Mercury", role: "Product Engineer", location: "Remote (US)", mode: .remote,
             status: .offer, salaryMin: 170_000, salaryMax: 205_000, source: .referral, priority: .high, excitement: 5,
             weeksAgoApplied: 7,
             interviews: [("Recruiter screen", 2, .phone, .passed, 30), ("Take-home review", 9, .video, .passed, 45), ("Final round", 18, .video, .passed, 120)],
             contacts: [("Lena Müller", .recruiter), ("Wei Chen", .referral)],
             tags: ["Dream role", "Startup", "Referral"], notes: "Offer in hand — comparing with Notion.",
             url: "https://mercury.com/jobs", followUpInDays: 2),

        Spec(company: "Zapier", role: "Frontend Engineer", location: "Remote (Global)", mode: .remote,
             status: .screening, salaryMin: 145_000, salaryMax: 180_000, source: .companySite, priority: .med, excitement: 4,
             weeksAgoApplied: 1,
             interviews: [("Intro call", 5, .video, .pending, 30)],
             contacts: [("Sofia Romero", .recruiter)], tags: ["Frontend", "Remote-first"], notes: "All-remote — great fit.",
             url: "https://zapier.com/jobs", followUpInDays: 6),

        Spec(company: "1Password", role: "Senior Software Developer", location: "Remote (Global)", mode: .remote,
             status: .applied, salaryMin: 155_000, salaryMax: 195_000, source: .linkedIn, priority: .med, excitement: 4,
             weeksAgoApplied: 3,
             interviews: [], contacts: [], tags: ["Remote-first"], notes: "",
             url: "https://1password.com/careers", followUpInDays: nil),

        Spec(company: "Postman", role: "Backend Engineer", location: "Remote (US)", mode: .remote,
             status: .saved, salaryMin: 150_000, salaryMax: 185_000, source: .indeed, priority: .low, excitement: 3,
             weeksAgoApplied: nil,
             interviews: [], contacts: [], tags: ["Backend"], notes: "",
             url: "https://postman.com/company/careers", followUpInDays: nil)
    ]
}

import SwiftUI
import SwiftData

struct ResumesListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Resume.updatedAt, order: .reverse) private var resumes: [Resume]

    var body: some View {
        NavigationStack {
            Group {
                if resumes.isEmpty {
                    ContentUnavailableView {
                        Label("No Resumes Yet", systemImage: "doc.text")
                    } description: {
                        Text("Create a blank resume, or start from a worked example to see how the pieces fit.")
                    } actions: {
                        Button("New Resume") {
                            createBlank()
                        }
                        .buttonStyle(.borderedProminent)
                        Button("Start from Example") {
                            createExample()
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    List {
                        ForEach(resumes) { resume in
                            NavigationLink {
                                EditorView(resume: resume)
                            } label: {
                                row(resume)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    modelContext.delete(resume)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                Button {
                                    duplicate(resume)
                                } label: {
                                    Label("Duplicate", systemImage: "plus.square.on.square")
                                }
                                .tint(VitaeTheme.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Vitae")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        createBlank()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("New resume")
                }
            }
        }
    }

    private func row(_ resume: Resume) -> some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color(hex: resume.accentHex))
                .frame(width: 34, height: 46)
                .overlay(
                    VStack(spacing: 3) {
                        ForEach(0..<4, id: \.self) { _ in
                            Capsule().fill(.white.opacity(0.8)).frame(height: 2)
                        }
                    }
                    .padding(7)
                )
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(resume.fullName.isEmpty ? "Untitled resume" : resume.fullName)
                    .font(.body.weight(.semibold))
                Text("\(resume.template.displayName) · edited \(resume.updatedAt.formatted(.relative(presentation: .named)))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ProgressView(value: resume.completeness)
                    .tint(Color(hex: resume.accentHex))
                    .frame(maxWidth: 160)
                    .accessibilityLabel("\(Int(resume.completeness * 100)) percent complete")
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func createBlank() {
        Haptics.tap()
        let raw = UserDefaults.standard.string(forKey: "defaultTemplate") ?? TemplateKind.classic.rawValue
        modelContext.insert(Resume(template: TemplateKind(rawValue: raw) ?? .classic))
    }

    private func duplicate(_ source: Resume) {
        Haptics.tap()
        let copy = Resume(
            fullName: source.fullName,
            headline: source.headline,
            email: source.email,
            phone: source.phone,
            location: source.location,
            website: source.website,
            summary: source.summary,
            accentHex: source.accentHex,
            template: source.template
        )
        modelContext.insert(copy)
        for item in source.sortedExperience {
            let e = ExperienceItem(company: item.company, role: item.role, period: item.period, details: item.details, orderIndex: item.orderIndex)
            e.resume = copy
            modelContext.insert(e)
        }
        for item in source.sortedEducation {
            let e = EducationItem(institution: item.institution, degree: item.degree, period: item.period, note: item.note, orderIndex: item.orderIndex)
            e.resume = copy
            modelContext.insert(e)
        }
        for group in source.sortedSkillGroups {
            let s = SkillGroup(name: group.name, skills: group.skills, orderIndex: group.orderIndex)
            s.resume = copy
            modelContext.insert(s)
        }
    }

    private func createExample() {
        Haptics.tap()
        let resume = Resume(
            fullName: "Jordan Reyes",
            headline: "Senior Product Designer",
            email: "jordan.reyes@example.com",
            phone: "+1 (415) 555-0146",
            location: "Portland, OR",
            website: "jordanreyes.design",
            summary: "Product designer with 8 years shipping consumer mobile apps end-to-end — research, systems, and polished UI. Led design for products used by 4M+ people; happiest pairing with engineers to cut scope without cutting quality.",
            accentHex: "2F6BD8",
            template: .classic
        )
        modelContext.insert(resume)

        let jobs: [(String, String, String, String)] = [
            ("Meridian Labs", "Senior Product Designer", "2022 — Present",
             "Led redesign of onboarding, lifting day-7 retention 18%\nBuilt and documented the design system used by 3 product teams\nRan monthly usability sessions; turned findings into a prioritized fix list"),
            ("Northwind Apps", "Product Designer", "2019 — 2022",
             "Designed the budgeting feature rated 4.8★ across 40k reviews\nPartnered with engineering to ship weekly without design debt\nMentored two junior designers to mid-level"),
            ("Freelance", "UI Designer", "2016 — 2019",
             "Delivered 20+ app and brand projects for early-stage startups"),
        ]
        for (index, job) in jobs.enumerated() {
            let item = ExperienceItem(company: job.0, role: job.1, period: job.2, details: job.3, orderIndex: index)
            item.resume = resume
            modelContext.insert(item)
        }

        let education = EducationItem(
            institution: "University of Washington",
            degree: "BDes, Interaction Design",
            period: "2012 — 2016",
            note: "Graduated with honors; HCI research assistant.",
            orderIndex: 0
        )
        education.resume = resume
        modelContext.insert(education)

        let groups: [(String, String)] = [
            ("Design", "Figma, prototyping, design systems, motion"),
            ("Research", "usability testing, interviews, surveys"),
            ("Collaboration", "roadmapping, agile, design critique"),
        ]
        for (index, group) in groups.enumerated() {
            let s = SkillGroup(name: group.0, skills: group.1, orderIndex: index)
            s.resume = resume
            modelContext.insert(s)
        }
    }
}

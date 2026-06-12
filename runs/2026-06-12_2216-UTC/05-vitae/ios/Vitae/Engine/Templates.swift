import SwiftUI

/// Renders a resume as a fixed-width paper document. Used for both the
/// on-screen preview and the PDF export, so what you see is what prints.
/// Documents are always ink-on-paper regardless of the app's color scheme.
struct ResumeDocumentView: View {
    let resume: Resume
    let width: CGFloat

    private var accent: Color { Color(hex: resume.accentHex) }

    var body: some View {
        Group {
            switch resume.template {
            case .classic: classic
            case .banner: banner
            case .compact: compact
            }
        }
        .frame(width: width)
        .background(Color.white)
        .environment(\.colorScheme, .light)
    }

    private var ink: Color { Color(red: 0.13, green: 0.14, blue: 0.17) }
    private var inkSoft: Color { Color(red: 0.38, green: 0.40, blue: 0.45) }

    // MARK: - Classic (centered serif)

    private var classic: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(spacing: 4) {
                Text(resume.fullName.isEmpty ? "Your Name" : resume.fullName)
                    .font(.system(size: 26, weight: .semibold, design: .serif))
                    .foregroundStyle(ink)
                if !resume.headline.isEmpty {
                    Text(resume.headline)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(accent)
                }
                if !resume.contactLine.isEmpty {
                    Text(resume.contactLine)
                        .font(.system(size: 9))
                        .foregroundStyle(inkSoft)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 12)

            if !resume.summary.trimmingCharacters(in: .whitespaces).isEmpty {
                sectionHeader("Profile", style: .classic)
                Text(resume.summary)
                    .font(.system(size: 10))
                    .foregroundStyle(ink)
                    .padding(.bottom, 10)
            }
            if !resume.sortedExperience.isEmpty {
                sectionHeader("Experience", style: .classic)
                ForEach(resume.sortedExperience) { item in
                    experienceBlock(item)
                }
            }
            if !resume.sortedEducation.isEmpty {
                sectionHeader("Education", style: .classic)
                ForEach(resume.sortedEducation) { item in
                    educationBlock(item)
                }
            }
            if !resume.sortedSkillGroups.isEmpty {
                sectionHeader("Skills", style: .classic)
                skillsBlock
            }
        }
        .padding(36)
    }

    // MARK: - Banner (accent header)

    private var banner: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(resume.fullName.isEmpty ? "Your Name" : resume.fullName)
                    .font(.system(size: 27, weight: .bold))
                    .foregroundStyle(.white)
                if !resume.headline.isEmpty {
                    Text(resume.headline)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.92))
                }
                if !resume.contactLine.isEmpty {
                    Text(resume.contactLine)
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 36)
            .padding(.vertical, 22)
            .background(accent)

            VStack(alignment: .leading, spacing: 0) {
                if !resume.summary.trimmingCharacters(in: .whitespaces).isEmpty {
                    sectionHeader("Profile", style: .banner)
                    Text(resume.summary)
                        .font(.system(size: 10))
                        .foregroundStyle(ink)
                        .padding(.bottom, 10)
                }
                if !resume.sortedExperience.isEmpty {
                    sectionHeader("Experience", style: .banner)
                    ForEach(resume.sortedExperience) { item in
                        experienceBlock(item)
                    }
                }
                if !resume.sortedEducation.isEmpty {
                    sectionHeader("Education", style: .banner)
                    ForEach(resume.sortedEducation) { item in
                        educationBlock(item)
                    }
                }
                if !resume.sortedSkillGroups.isEmpty {
                    sectionHeader("Skills", style: .banner)
                    skillsBlock
                }
            }
            .padding(.horizontal, 36)
            .padding(.vertical, 20)
        }
    }

    // MARK: - Compact (dense single column)

    private var compact: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(resume.fullName.isEmpty ? "Your Name" : resume.fullName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(ink)
                Spacer()
                if !resume.headline.isEmpty {
                    Text(resume.headline)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(accent)
                }
            }
            if !resume.contactLine.isEmpty {
                Text(resume.contactLine)
                    .font(.system(size: 8.5))
                    .foregroundStyle(inkSoft)
                    .padding(.top, 2)
            }
            Rectangle()
                .fill(accent)
                .frame(height: 2)
                .padding(.vertical, 8)

            if !resume.summary.trimmingCharacters(in: .whitespaces).isEmpty {
                Text(resume.summary)
                    .font(.system(size: 9))
                    .foregroundStyle(ink)
                    .padding(.bottom, 8)
            }
            if !resume.sortedExperience.isEmpty {
                sectionHeader("Experience", style: .compact)
                ForEach(resume.sortedExperience) { item in
                    experienceBlock(item, compact: true)
                }
            }
            if !resume.sortedEducation.isEmpty {
                sectionHeader("Education", style: .compact)
                ForEach(resume.sortedEducation) { item in
                    educationBlock(item, compact: true)
                }
            }
            if !resume.sortedSkillGroups.isEmpty {
                sectionHeader("Skills", style: .compact)
                skillsBlock
            }
        }
        .padding(28)
    }

    // MARK: - Shared blocks

    private enum HeaderStyle { case classic, banner, compact }

    @ViewBuilder
    private func sectionHeader(_ title: String, style: HeaderStyle) -> some View {
        switch style {
        case .classic:
            VStack(spacing: 3) {
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .semibold, design: .serif))
                    .tracking(2.4)
                    .foregroundStyle(accent)
                    .frame(maxWidth: .infinity)
                Rectangle()
                    .fill(inkSoft.opacity(0.35))
                    .frame(height: 0.6)
            }
            .padding(.bottom, 8)
        case .banner:
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold))
                .tracking(2)
                .foregroundStyle(accent)
                .padding(.bottom, 6)
        case .compact:
            Text(title.uppercased())
                .font(.system(size: 9, weight: .bold))
                .tracking(1.6)
                .foregroundStyle(accent)
                .padding(.bottom, 4)
        }
    }

    private func experienceBlock(_ item: ExperienceItem, compact: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline) {
                Text(item.role.isEmpty ? "Role" : item.role)
                    .font(.system(size: compact ? 10 : 11, weight: .semibold))
                    .foregroundStyle(ink)
                Spacer()
                Text(item.period)
                    .font(.system(size: compact ? 8 : 9))
                    .foregroundStyle(inkSoft)
            }
            Text(item.company)
                .font(.system(size: compact ? 9 : 10, weight: .medium))
                .foregroundStyle(accent)
            ForEach(Array(item.bullets.enumerated()), id: \.offset) { _, bullet in
                HStack(alignment: .top, spacing: 5) {
                    Text("•")
                        .font(.system(size: compact ? 8.5 : 9.5))
                        .foregroundStyle(inkSoft)
                    Text(bullet)
                        .font(.system(size: compact ? 8.5 : 9.5))
                        .foregroundStyle(ink)
                }
                .padding(.top, 1)
            }
        }
        .padding(.bottom, compact ? 7 : 10)
    }

    private func educationBlock(_ item: EducationItem, compact: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline) {
                Text(item.degree.isEmpty ? "Degree" : item.degree)
                    .font(.system(size: compact ? 10 : 11, weight: .semibold))
                    .foregroundStyle(ink)
                Spacer()
                Text(item.period)
                    .font(.system(size: compact ? 8 : 9))
                    .foregroundStyle(inkSoft)
            }
            Text(item.institution)
                .font(.system(size: compact ? 9 : 10, weight: .medium))
                .foregroundStyle(accent)
            if !item.note.trimmingCharacters(in: .whitespaces).isEmpty {
                Text(item.note)
                    .font(.system(size: compact ? 8.5 : 9.5))
                    .foregroundStyle(ink)
            }
        }
        .padding(.bottom, compact ? 7 : 10)
    }

    private var skillsBlock: some View {
        VStack(alignment: .leading, spacing: 3) {
            ForEach(resume.sortedSkillGroups) { group in
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(group.name.isEmpty ? "Skills" : group.name + ":")
                        .font(.system(size: 9.5, weight: .semibold))
                        .foregroundStyle(ink)
                    Text(group.skillList.joined(separator: " · "))
                        .font(.system(size: 9.5))
                        .foregroundStyle(inkSoft)
                }
            }
        }
        .padding(.bottom, 8)
    }
}

extension Color {
    init(hex: String) {
        var value: UInt64 = 0
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        Scanner(string: cleaned).scanHexInt64(&value)
        let r = Double((value >> 16) & 0xFF) / 255.0
        let g = Double((value >> 8) & 0xFF) / 255.0
        let b = Double(value & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

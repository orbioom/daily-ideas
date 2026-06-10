import SwiftUI
import SwiftData

struct CurriculumView: View {
    @Query(sort: \Dog.createdAt) private var dogs: [Dog]
    @AppStorage("selectedDogID") private var selectedDogID = ""

    private var dog: Dog? { CurrentDog.resolve(from: dogs, selectedID: selectedDogID) }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if let dog {
                    List {
                        ForEach(SkillLevel.allCases) { level in
                            Section {
                                ForEach(Curriculum.skills(in: level)) { skill in
                                    NavigationLink(value: skill) {
                                        SkillRow(dog: dog, skill: skill)
                                    }
                                    .listRowBackground(Color.clear)
                                }
                            } header: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(level.rawValue)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Brand.text)
                                    Text(level.blurb)
                                        .font(.caption)
                                        .foregroundStyle(Brand.text3)
                                        .textCase(nil)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                } else {
                    EmptyStateView(icon: "list.bullet.clipboard",
                                   title: "No dog selected",
                                   message: "Add a dog to see the curriculum.")
                }
            }
            .navigationTitle("Skills")
            .navigationDestination(for: Skill.self) { skill in
                if let dog { SkillDetailView(dog: dog, skill: skill) }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    DogPickerMenu(dogs: dogs, selectedID: $selectedDogID)
                }
            }
        }
    }
}

private struct SkillRow: View {
    let dog: Dog
    let skill: Skill

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: skill.symbol)
                .font(.body)
                .foregroundStyle(Brand.text2)
                .frame(width: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(skill.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Brand.text)
                let status = TrainingEngine.status(for: dog, skill: skill)
                if status == .learning || status == .practicing,
                   let p = TrainingEngine.progress(for: dog, skillID: skill.id) {
                    Text("Step \(min(p.completedSteps + (status == .practicing ? 0 : 1), skill.steps.count)) of \(skill.steps.count)")
                        .font(.caption)
                        .foregroundStyle(Brand.text3)
                }
            }
            Spacer()
            StatusBadge(status: TrainingEngine.status(for: dog, skill: skill))
        }
        .padding(.vertical, 3)
        .accessibilityElement(children: .combine)
    }
}

import SwiftUI
import SwiftData

struct IdeasView: View {
    @Query(sort: \TattooIdea.dateAdded, order: .reverse) private var ideas: [TattooIdea]
    @Environment(\.modelContext) private var modelContext
    @State private var showAdd = false
    @State private var searchText = ""
    @State private var filterStatus: IdeaStatus? = nil
    @State private var selectedIdea: TattooIdea? = nil

    var filtered: [TattooIdea] {
        ideas.filter { idea in
            let matchSearch = searchText.isEmpty || idea.title.localizedCaseInsensitiveContains(searchText) || idea.body.localizedCaseInsensitiveContains(searchText)
            let matchStatus = filterStatus == nil || idea.status == filterStatus!.rawValue
            return matchSearch && matchStatus
        }
    }

    var body: some View {
        ZStack {
            InkTheme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                statusFilter
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                if filtered.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filtered) { idea in
                                IdeaCard(idea: idea)
                                    .onTapGesture { selectedIdea = idea }
                            }
                        }
                        .padding(16)
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search ideas")
        .navigationTitle("Ideas")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(InkTheme.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAdd = true } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(InkTheme.accent)
                }
            }
        }
        .sheet(isPresented: $showAdd) { AddIdeaView() }
        .sheet(item: $selectedIdea) { idea in IdeaDetailView(idea: idea) }
    }

    var statusFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(label: "All", status: nil)
                ForEach(IdeaStatus.allCases, id: \.self) { s in
                    filterChip(label: s.rawValue, status: s)
                }
            }
        }
    }

    func filterChip(label: String, status: IdeaStatus?) -> some View {
        Button {
            withAnimation { filterStatus = status }
        } label: {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(filterStatus == status ? .black : InkTheme.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    filterStatus == status
                        ? (status?.color ?? InkTheme.accent)
                        : InkTheme.surface,
                    in: Capsule()
                )
        }
    }

    var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 52))
                .foregroundStyle(InkTheme.textSecondary)
            Text(searchText.isEmpty ? "No Ideas Yet" : "No Results")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(InkTheme.textPrimary)
            Text(searchText.isEmpty ? "Tap + to add your first tattoo idea." : "Try a different search term.")
                .font(.system(size: 15))
                .foregroundStyle(InkTheme.textSecondary)
            if searchText.isEmpty {
                Button { showAdd = true } label: {
                    Text("Add Idea")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 12)
                        .background(InkTheme.accent, in: Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct IdeaCard: View {
    let idea: TattooIdea

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(idea.title.isEmpty ? "Untitled Idea" : idea.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(InkTheme.textPrimary)
                Spacer()
                StatusBadge(status: IdeaStatus(rawValue: idea.status) ?? .wishlist)
            }
            HStack(spacing: 16) {
                Label(idea.style, systemImage: "paintbrush")
                Label(idea.placement, systemImage: "person.fill")
            }
            .font(.system(size: 12))
            .foregroundStyle(InkTheme.textSecondary)
            if !idea.body.isEmpty {
                Text(idea.body)
                    .font(.system(size: 13))
                    .foregroundStyle(InkTheme.textSecondary)
                    .lineLimit(2)
            }
            if !idea.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(idea.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(InkTheme.accent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(InkTheme.accent.opacity(0.15), in: Capsule())
                        }
                    }
                }
            }
            if idea.estimatedCost > 0 {
                HStack {
                    Spacer()
                    Text("~$\(Int(idea.estimatedCost))")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(InkTheme.accentOrange)
                }
            }
        }
        .padding(14)
        .background(InkTheme.surface, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }
}

struct StatusBadge: View {
    let status: IdeaStatus

    var body: some View {
        Text(status.rawValue)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.black)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(status.color, in: Capsule())
    }
}

struct IdeaDetailView: View {
    @Bindable var idea: TattooIdea
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false

    var body: some View {
        NavigationStack {
            ZStack {
                InkTheme.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        statusRow
                        detailsGrid
                        if !idea.body.isEmpty {
                            noteSection
                        }
                        tagsSection
                        costSection
                    }
                    .padding(20)
                }
            }
            .navigationTitle(idea.title.isEmpty ? "Idea" : idea.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(InkTheme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(InkTheme.textSecondary)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button { isEditing = true } label: {
                        Image(systemName: "pencil")
                            .foregroundStyle(InkTheme.accent)
                    }
                }
                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive) {
                        modelContext.delete(idea)
                        dismiss()
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(.red)
                    }
                }
            }
            .sheet(isPresented: $isEditing) { AddIdeaView(existing: idea) }
        }
    }

    var statusRow: some View {
        HStack {
            Text("Status")
                .foregroundStyle(InkTheme.textSecondary)
            Spacer()
            Picker("Status", selection: $idea.status) {
                ForEach(IdeaStatus.allCases, id: \.self) { s in
                    Text(s.rawValue).tag(s.rawValue)
                }
            }
            .pickerStyle(.menu)
            .tint(InkTheme.accent)
        }
        .padding(14)
        .background(InkTheme.surface, in: RoundedRectangle(cornerRadius: 12))
    }

    var detailsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            detailCell("Style", idea.style, icon: "paintbrush")
            detailCell("Placement", idea.placement, icon: "person.fill")
            detailCell("Size", idea.size, icon: "arrow.up.left.and.arrow.down.right")
            detailCell("Color", idea.colorScheme, icon: "paintpalette")
        }
    }

    func detailCell(_ label: String, _ value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(label, systemImage: icon)
                .font(.system(size: 11))
                .foregroundStyle(InkTheme.textSecondary)
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(InkTheme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(InkTheme.surface, in: RoundedRectangle(cornerRadius: 10))
    }

    var noteSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Notes")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(InkTheme.textSecondary)
            Text(idea.body)
                .font(.system(size: 15))
                .foregroundStyle(InkTheme.textPrimary)
        }
        .padding(14)
        .background(InkTheme.surface, in: RoundedRectangle(cornerRadius: 12))
    }

    var tagsSection: some View {
        Group {
            if !idea.tags.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tags")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(InkTheme.textSecondary)
                    FlowTagsView(tags: idea.tags)
                }
                .padding(14)
                .background(InkTheme.surface, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    var costSection: some View {
        Group {
            if idea.estimatedCost > 0 {
                HStack {
                    Text("Estimated Cost")
                        .foregroundStyle(InkTheme.textSecondary)
                    Spacer()
                    Text("$\(Int(idea.estimatedCost))")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(InkTheme.accentOrange)
                }
                .padding(14)
                .background(InkTheme.surface, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

struct FlowTagsView: View {
    let tags: [String]

    var body: some View {
        FlexRow(tags: tags)
    }
}

struct FlexRow: View {
    let tags: [String]

    var body: some View {
        var width: CGFloat = 0
        var rows: [[String]] = [[]]
        for tag in tags {
            let tagWidth = CGFloat(tag.count * 9 + 24)
            if width + tagWidth > 300 {
                rows.append([tag])
                width = tagWidth
            } else {
                rows[rows.count - 1].append(tag)
                width += tagWidth + 8
            }
        }
        return VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 6) {
                    ForEach(row, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(InkTheme.accent)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(InkTheme.accent.opacity(0.15), in: Capsule())
                    }
                }
            }
        }
    }
}

struct AddIdeaView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    var existing: TattooIdea? = nil

    @State private var title = ""
    @State private var body = ""
    @State private var style = TattooStyle.blackwork
    @State private var placement = BodyPlacement.forearm
    @State private var status = IdeaStatus.wishlist
    @State private var tagsText = ""
    @State private var estimatedCost = ""
    @State private var colorScheme = "Black & Grey"
    @State private var size = "Medium"

    let colorSchemes = ["Black & Grey", "Full Color", "Red & Black", "Minimalist Black", "Watercolor", "Other"]
    let sizes = ["Tiny (<2in)", "Small (2-4in)", "Medium (4-6in)", "Large (6-10in)", "Extra Large (10in+)", "Full Sleeve"]

    var body: some View {
        NavigationStack {
            ZStack {
                InkTheme.background.ignoresSafeArea()
                Form {
                    Section {
                        TextField("Title", text: $title)
                        TextField("Notes, inspiration, reference ideas...", text: $body, axis: .vertical)
                            .lineLimit(4...10)
                    } header: {
                        Text("Idea").foregroundStyle(InkTheme.textSecondary)
                    }
                    .listRowBackground(InkTheme.surface)
                    .foregroundStyle(InkTheme.textPrimary)

                    Section {
                        Picker("Style", selection: $style) {
                            ForEach(TattooStyle.allCases, id: \.self) { s in
                                Text(s.rawValue).tag(s)
                            }
                        }
                        Picker("Placement", selection: $placement) {
                            ForEach(BodyPlacement.allCases, id: \.self) { p in
                                Text(p.rawValue).tag(p)
                            }
                        }
                        Picker("Size", selection: $size) {
                            ForEach(sizes, id: \.self) { Text($0).tag($0) }
                        }
                        Picker("Color Scheme", selection: $colorScheme) {
                            ForEach(colorSchemes, id: \.self) { Text($0).tag($0) }
                        }
                    } header: {
                        Text("Details").foregroundStyle(InkTheme.textSecondary)
                    }
                    .listRowBackground(InkTheme.surface)
                    .foregroundStyle(InkTheme.textPrimary)

                    Section {
                        Picker("Status", selection: $status) {
                            ForEach(IdeaStatus.allCases, id: \.self) { s in
                                Text(s.rawValue).tag(s)
                            }
                        }
                        TextField("Estimated Cost ($)", text: $estimatedCost)
                            .keyboardType(.decimalPad)
                        TextField("Tags (comma separated)", text: $tagsText)
                    } header: {
                        Text("Planning").foregroundStyle(InkTheme.textSecondary)
                    }
                    .listRowBackground(InkTheme.surface)
                    .foregroundStyle(InkTheme.textPrimary)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(existing == nil ? "New Idea" : "Edit Idea")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(InkTheme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(InkTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .foregroundStyle(InkTheme.accent)
                        .disabled(title.isEmpty)
                }
            }
            .onAppear { loadExisting() }
        }
    }

    func loadExisting() {
        guard let e = existing else { return }
        title = e.title
        body = e.body
        style = TattooStyle(rawValue: e.style) ?? .blackwork
        placement = BodyPlacement(rawValue: e.placement) ?? .forearm
        status = IdeaStatus(rawValue: e.status) ?? .wishlist
        tagsText = e.tags.joined(separator: ", ")
        estimatedCost = e.estimatedCost > 0 ? "\(Int(e.estimatedCost))" : ""
        colorScheme = e.colorScheme
        size = e.size
    }

    func save() {
        let tags = tagsText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        if let e = existing {
            e.title = title
            e.body = body
            e.style = style.rawValue
            e.placement = placement.rawValue
            e.status = status.rawValue
            e.tags = tags
            e.estimatedCost = Double(estimatedCost) ?? 0
            e.colorScheme = colorScheme
            e.size = size
        } else {
            let idea = TattooIdea(
                title: title, body: body, style: style.rawValue,
                placement: placement.rawValue, status: status.rawValue,
                tags: tags, estimatedCost: Double(estimatedCost) ?? 0,
                colorScheme: colorScheme, size: size
            )
            modelContext.insert(idea)
        }
        dismiss()
    }
}

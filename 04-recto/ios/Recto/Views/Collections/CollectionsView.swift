import SwiftUI
import SwiftData

struct CollectionsView: View {
    @Query(sort: \Collection.sortOrder) private var collections: [Collection]
    @Query private var allEntries: [BulletEntry]
    @Query private var settingsArr: [RectoSettings]
    @Environment(\.modelContext) private var ctx
    @State private var vm = CollectionViewModel()
    @State private var showCreateSheet: Bool = false

    private var fontStyle: String { settingsArr.first?.fontStyle ?? "sans" }

    var body: some View {
        NavigationStack {
            ZStack {
                RectoTheme.paperBackground.ignoresSafeArea()

                if collections.isEmpty {
                    EmptyStateView(
                        icon: "folder",
                        title: "No Collections Yet",
                        subtitle: "Collections let you group related entries —\nprojects, ideas, reading lists, and more.",
                        actionTitle: "Create Collection",
                        action: { showCreateSheet = true }
                    )
                } else {
                    List {
                        ForEach(collections) { col in
                            NavigationLink(destination: CollectionDetailView(collection: col)) {
                                CollectionRowView(
                                    collection: col,
                                    entryCount: vm.entryCount(for: col, entries: allEntries),
                                    fontStyle: fontStyle
                                )
                            }
                            .listRowBackground(Color.white.opacity(0.5))
                        }
                        .onDelete { indexSet in
                            for i in indexSet {
                                vm.deleteCollection(collections[i], entries: allEntries, context: ctx)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Collections")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(RectoTheme.inkPrimary)
                }
            }
            .sheet(isPresented: $showCreateSheet) {
                CreateCollectionSheet(vm: vm, isPresented: $showCreateSheet)
            }
        }
    }
}

// MARK: - Collection Row
private struct CollectionRowView: View {
    let collection: Collection
    let entryCount: Int
    let fontStyle: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: collection.colorHex).opacity(0.15))
                    .frame(width: 42, height: 42)

                Image(systemName: collection.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color(hex: collection.colorHex))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(collection.name)
                    .font(.system(size: 16, weight: .semibold, design: fontStyle == "serif" ? .serif : .default))
                    .foregroundStyle(RectoTheme.inkPrimary)

                Text(entryCount == 1 ? "1 entry" : "\(entryCount) entries")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(RectoTheme.inkSecondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Create Collection Sheet
struct CreateCollectionSheet: View {
    @Bindable var vm: CollectionViewModel
    @Binding var isPresented: Bool
    @Query private var allCollections: [Collection]
    @Environment(\.modelContext) private var ctx
    @FocusState private var nameFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                RectoTheme.paperBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        // Name field
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Collection Name", systemImage: "pencil")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(RectoTheme.inkSecondary)
                                .textCase(.uppercase)

                            TextField("e.g. Reading List, Project Ideas…", text: $vm.newCollectionName)
                                .font(.system(size: 17))
                                .padding(14)
                                .background(Color.white.opacity(0.7))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .focused($nameFocused)
                        }

                        // Icon picker
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Icon", systemImage: "square.grid.2x2")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(RectoTheme.inkSecondary)
                                .textCase(.uppercase)

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 5), spacing: 12) {
                                ForEach(vm.availableIcons, id: \.self) { icon in
                                    Button {
                                        vm.newCollectionIcon = icon
                                    } label: {
                                        Image(systemName: icon)
                                            .font(.system(size: 22))
                                            .foregroundStyle(
                                                vm.newCollectionIcon == icon
                                                ? Color(hex: vm.newCollectionColor)
                                                : RectoTheme.inkSecondary
                                            )
                                            .frame(width: 48, height: 48)
                                            .background(
                                                vm.newCollectionIcon == icon
                                                ? Color(hex: vm.newCollectionColor).opacity(0.12)
                                                : Color.white.opacity(0.5)
                                            )
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(
                                                        vm.newCollectionIcon == icon
                                                        ? Color(hex: vm.newCollectionColor)
                                                        : Color.clear,
                                                        lineWidth: 1.5
                                                    )
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        // Color picker
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Color", systemImage: "paintpalette")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(RectoTheme.inkSecondary)
                                .textCase(.uppercase)

                            HStack(spacing: 12) {
                                ForEach(vm.availableColors, id: \.self) { hex in
                                    Button {
                                        vm.newCollectionColor = hex
                                    } label: {
                                        Circle()
                                            .fill(Color(hex: hex))
                                            .frame(width: 32, height: 32)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white, lineWidth: vm.newCollectionColor == hex ? 3 : 0)
                                            )
                                            .shadow(color: Color(hex: hex).opacity(0.5), radius: vm.newCollectionColor == hex ? 4 : 0)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        // Preview
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Preview", systemImage: "eye")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(RectoTheme.inkSecondary)
                                .textCase(.uppercase)

                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(hex: vm.newCollectionColor).opacity(0.15))
                                        .frame(width: 42, height: 42)
                                    Image(systemName: vm.newCollectionIcon)
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundStyle(Color(hex: vm.newCollectionColor))
                                }
                                Text(vm.newCollectionName.isEmpty ? "Collection Name" : vm.newCollectionName)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(vm.newCollectionName.isEmpty ? RectoTheme.inkSecondary : RectoTheme.inkPrimary)
                            }
                            .padding(14)
                            .background(Color.white.opacity(0.6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        vm.newCollectionName = ""
                        isPresented = false
                    }
                    .foregroundStyle(RectoTheme.inkSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        vm.createCollection(context: ctx, all: allCollections)
                        isPresented = false
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(
                        vm.newCollectionName.trimmingCharacters(in: .whitespaces).isEmpty
                        ? RectoTheme.inkSecondary
                        : RectoTheme.inkPrimary
                    )
                    .disabled(vm.newCollectionName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { nameFocused = true }
        }
    }
}

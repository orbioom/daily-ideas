import SwiftUI
import PhotosUI
import SwiftData

struct StickerEditorView: View {
    @State private var vm = StickerViewModel()
    @Environment(\.modelContext) private var context
    @State private var photoItem: PhotosPickerItem?
    @State private var showSaveAlert = false
    @State private var stickerName = ""
    @State private var showShareSheet = false
    @State private var exportedImage: UIImage?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    previewSection
                    toolsSection
                    borderSection
                }
                .padding()
            }
            .navigationTitle("Create Sticker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label("Import", systemImage: "photo.badge.plus")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if vm.sourceImage != nil {
                        Button {
                            stickerName = "Sticker \(Int.random(in: 100...999))"
                            showSaveAlert = true
                        } label: {
                            Label("Save", systemImage: "square.and.arrow.down")
                        }
                    }
                }
            }
            .onChange(of: photoItem) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self),
                       let img = UIImage(data: data) {
                        vm.loadImage(img)
                    }
                }
            }
            .alert("Save Sticker", isPresented: $showSaveAlert) {
                TextField("Sticker name", text: $stickerName)
                Button("Save") {
                    vm.exportSticker(name: stickerName, context: context)
                }
                Button("Cancel", role: .cancel) { }
            }
            .sheet(isPresented: $showShareSheet) {
                if let img = exportedImage {
                    ShareSheet(items: [img])
                }
            }
        }
    }

    @ViewBuilder
    private var previewSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
                .frame(height: 300)
            if vm.isProcessing {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Removing background…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else if let preview = vm.previewImage {
                Image(uiImage: preview)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 260)
                    .padding()
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "photo")
                        .font(.system(size: 48))
                        .foregroundStyle(.tertiary)
                    Text("Import a photo to start")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var toolsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle("Drop Shadow", isOn: $vm.hasShadow)
            HStack {
                Text("Border Width")
                Spacer()
                Text("\(Int(vm.borderWidth)) px")
                    .foregroundStyle(.secondary)
            }
            Slider(value: $vm.borderWidth, in: 0...40, step: 2)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var borderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Border Color")
                .font(.subheadline.weight(.semibold))
            let colors: [Color] = [.white, .black, .red, .orange, .yellow, .green, .blue, .purple, .pink]
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 10) {
                ForEach(colors.indices, id: \.self) { i in
                    let c = colors[i]
                    Circle()
                        .fill(c)
                        .overlay(Circle().stroke(vm.borderColor == c ? Color.accentColor : Color.clear, lineWidth: 3))
                        .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
                        .frame(width: 44, height: 44)
                        .onTapGesture { vm.borderColor = c }
                        .accessibilityLabel("Border color \(i + 1)")
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

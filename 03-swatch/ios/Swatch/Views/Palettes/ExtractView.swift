import SwiftUI
import SwiftData
import PhotosUI

struct ExtractView: View {
    @Environment(\.modelContext) private var ctx
    @AppStorage("preferredColorCount") private var preferredColorCount = 6

    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var extractedColors: [ExtractedColor] = []
    @State private var isExtracting = false
    @State private var paletteName = ""
    @State private var showCamera = false
    @State private var showSavedToast = false
    @State private var colorCount = 6
    @State private var copiedHex: String?

    var body: some View {
        NavigationStack {
            ZStack {
                SwatchTheme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Image picker area
                        ZStack {
                            if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 240)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            } else {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(SwatchTheme.cardBg)
                                    .frame(height: 240)
                                    .overlay {
                                        VStack(spacing: 12) {
                                            Image(systemName: "photo.badge.plus")
                                                .font(.system(size: 48))
                                                .foregroundStyle(SwatchTheme.subtleText)
                                            Text("Select a photo to extract colors")
                                                .font(.subheadline)
                                                .foregroundStyle(SwatchTheme.subtleText)
                                        }
                                    }
                            }
                        }
                        .shadow(color: SwatchTheme.shadow, radius: 8, y: 4)

                        // Picker buttons
                        HStack(spacing: 12) {
                            PhotosPicker(selection: $selectedItem, matching: .images) {
                                Label("Library", systemImage: "photo.on.rectangle")
                                    .font(.subheadline.weight(.medium))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(SwatchTheme.cardBg)
                                    .foregroundStyle(SwatchTheme.accent)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .shadow(color: SwatchTheme.shadow, radius: 4, y: 2)
                            }

                            Button {
                                showCamera = true
                            } label: {
                                Label("Camera", systemImage: "camera")
                                    .font(.subheadline.weight(.medium))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(SwatchTheme.cardBg)
                                    .foregroundStyle(SwatchTheme.accent)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .shadow(color: SwatchTheme.shadow, radius: 4, y: 2)
                            }
                        }

                        // Color count stepper
                        HStack {
                            Text("Colors")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(SwatchTheme.accent)
                            Spacer()
                            Stepper("\(colorCount)", value: $colorCount, in: 4...8)
                                .labelsHidden()
                            Text("\(colorCount)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(SwatchTheme.accent)
                                .frame(width: 24)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(SwatchTheme.cardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow(color: SwatchTheme.shadow, radius: 4, y: 2)

                        // Extract button
                        if selectedImage != nil {
                            Button {
                                Task { await extractColors() }
                            } label: {
                                HStack {
                                    if isExtracting {
                                        ProgressView()
                                            .tint(.white)
                                            .padding(.trailing, 4)
                                    }
                                    Text(isExtracting ? "Extracting..." : "Extract Palette")
                                        .font(.headline)
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(SwatchTheme.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .disabled(isExtracting)
                        }

                        // Extracted colors
                        if !extractedColors.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Extracted Palette")
                                    .font(.headline)
                                    .foregroundStyle(SwatchTheme.accent)

                                // Large color swatches horizontal scroll
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(extractedColors) { color in
                                            SwatchCard(color: color, copiedHex: $copiedHex)
                                        }
                                    }
                                    .padding(.horizontal, 2)
                                }

                                // Palette name field
                                TextField("Palette name", text: $paletteName)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                    .background(SwatchTheme.cardBg)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .shadow(color: SwatchTheme.shadow, radius: 4, y: 2)

                                // Save button
                                Button {
                                    savePalette()
                                } label: {
                                    Text("Save Palette")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(extractedColors.isEmpty ? Color.gray : SwatchTheme.accent)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .disabled(extractedColors.isEmpty || paletteName.trimmingCharacters(in: .whitespaces).isEmpty)
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Swatch")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showCamera) {
                CameraPickerView { image in
                    selectedImage = image
                    selectedItem = nil
                    extractedColors = []
                }
            }
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    guard let newItem else { return }
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let ui = UIImage(data: data) {
                        selectedImage = ui
                        extractedColors = []
                    }
                }
            }
            .overlay(alignment: .bottom) {
                if showSavedToast {
                    Text("Palette saved!")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.green)
                        .clipShape(Capsule())
                        .padding(.bottom, 32)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: showSavedToast)
        }
    }

    private func extractColors() async {
        guard let image = selectedImage else { return }
        isExtracting = true
        let extractor = KMeansExtractor()
        let colors = await extractor.extract(from: image, k: colorCount)
        extractedColors = colors
        isExtracting = false
    }

    private func savePalette() {
        let name = paletteName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty, !extractedColors.isEmpty else { return }

        let palette = Palette(name: name)

        // Save thumbnail
        if let image = selectedImage {
            let thumb = thumbnailData(from: image, size: CGSize(width: 300, height: 300))
            palette.sourceImageData = thumb
        }

        ctx.insert(palette)

        for (i, extracted) in extractedColors.enumerated() {
            let sc = SwatchColor(extracted: extracted, order: i)
            sc.palette = palette
            ctx.insert(sc)
        }

        try? ctx.save()

        paletteName = ""
        extractedColors = []
        selectedImage = nil
        selectedItem = nil

        withAnimation {
            showSavedToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showSavedToast = false
            }
        }
    }

    private func thumbnailData(from image: UIImage, size: CGSize) -> Data? {
        let renderer = UIGraphicsImageRenderer(size: size)
        let thumb = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        return thumb.jpegData(compressionQuality: 0.8)
    }
}

struct SwatchCard: View {
    let color: ExtractedColor
    @Binding var copiedHex: String?

    var body: some View {
        VStack(spacing: 6) {
            color.color
                .frame(width: 80, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                .overlay(alignment: .bottom) {
                    if copiedHex == color.hex {
                        Text("Copied!")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.vertical, 3)
                            .padding(.horizontal, 6)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Capsule())
                            .padding(.bottom, 6)
                    }
                }
                .onTapGesture {
                    UIPasteboard.general.string = color.hex
                    copiedHex = color.hex
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        if copiedHex == color.hex { copiedHex = nil }
                    }
                }

            Text(color.hex)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(SwatchTheme.subtleText)

            Text(color.name)
                .font(.caption2)
                .foregroundStyle(SwatchTheme.subtleText)
                .lineLimit(1)
        }
    }
}

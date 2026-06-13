import SwiftUI
import UIKit

struct EmptyState: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon).font(.system(size: 46, weight: .light))
                .foregroundStyle(Theme.accent).accessibilityHidden(true)
            Text(title).font(Theme.rounded(22)).foregroundStyle(Theme.ink)
            Text(message).font(.system(size: 15)).foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center).padding(.horizontal, 34)
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle).font(.system(size: 15, weight: .semibold))
                        .padding(.horizontal, 22).padding(.vertical, 11)
                        .background(Capsule().fill(Theme.accent)).foregroundStyle(.white)
                }.padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity).padding(.vertical, 50)
    }
}

struct MoodPicker: View {
    @Binding var selection: Int
    var body: some View {
        HStack(spacing: 10) {
            ForEach(Theme.moods) { mood in
                Button {
                    selection = mood.index; Haptics.tap()
                } label: {
                    VStack(spacing: 5) {
                        Circle().fill(mood.color)
                            .frame(width: 42, height: 42)
                            .overlay {
                                if selection == mood.index {
                                    Image(systemName: "checkmark").font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                            .overlay(Circle().strokeBorder(Theme.ink.opacity(selection == mood.index ? 0.25 : 0),
                                                           lineWidth: 2))
                            .scaleEffect(selection == mood.index ? 1.08 : 1)
                        Text(mood.name).font(.system(size: 11, weight: .medium))
                            .foregroundStyle(selection == mood.index ? Theme.ink : Theme.inkFaint)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(mood.name)
                .accessibilityAddTraits(selection == mood.index ? .isSelected : [])
            }
        }
        .animation(.spring(duration: 0.25), value: selection)
    }
}

/// Loads a day photo off the main thread with a placeholder.
struct PhotoThumb: View {
    let fileName: String?
    var cornerRadius: CGFloat = 14
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Rectangle().fill(Theme.surfaceAlt)
                    .overlay(Image(systemName: "photo").foregroundStyle(Theme.inkFaint))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .task(id: fileName) {
            image = await load()
        }
        .accessibilityHidden(true)
    }

    private func load() async -> UIImage? {
        let name = fileName
        return await Task.detached(priority: .userInitiated) {
            ImageStore.load(name)
        }.value
    }
}

struct StatTile: View {
    let value: String
    let label: String
    var color: Color = Theme.accent
    var body: some View {
        VStack(spacing: 3) {
            Text(value).font(Theme.rounded(24)).foregroundStyle(color)
            Text(label.uppercased()).font(.system(size: 11, weight: .semibold)).tracking(0.5)
                .foregroundStyle(Theme.inkFaint)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 16).fill(Theme.surface))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }
}

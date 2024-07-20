import NukeUI
import SwiftUI

public struct FeedImage: View {
    private static func rectangle(size: CGFloat) -> RoundedRectangle {
        RoundedRectangle(cornerRadius: size / 4, style: .continuous)
    }
    
    private let url: URL?
    private let size: CGFloat
    
    public init(url: URL?, size: CGFloat) {
        self.url = url
        self.size = size
    }
    
    public var body: some View {
        LazyImage(url: url) { state in
            let rectangle = Self.rectangle(size: size)
            
            if let image = state.image {
                image
                    .resizable()
                    .frame(width: size, height: size)
                    .clipShape(rectangle)
            } else {
                if state.error != nil {
                    Self.default(size: size)
                } else {
                    rectangle
                        .fill(state.error != nil ? .red.opacity(0.3) : .gray.opacity(0.3))
                        .frame(width: size, height: size)
                }
            }
        }
    }
}

public extension FeedImage {
    static func `default`(size: CGFloat) -> some View {
        rectangle(size: size)
            .fill(.secondary)
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: "newspaper.fill")
                    .resizable()
                    .foregroundStyle(.white)
                    .padding(size / 5)
            }
    }
}

#Preview {
    VStack {
        FeedImage(url: URL(string: "https://maiyama4.hatenablog.com/icon/favicon"), size: 44)
        FeedImage(url: URL(string: "https://invalid.image.url"), size: 44)
        FeedImage.default(size: 44)
    }
}

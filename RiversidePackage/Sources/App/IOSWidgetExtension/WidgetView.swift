import SwiftUI
import WidgetKit

struct WidgetView: View {
    let entry: Provider.Entry
    
    var body: some View {
        VStack {
            HStack {
                Image(.logo)
                    .resizable()
                    .frame(width: 20, height: 20)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                
                if case .success(let items) = entry.result, !items.isEmpty {
                    Group {
                        Text("\(items.count)").bold() + Text(" unreads")
                    }
                    .font(.system(size: 12))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Group {
                switch entry.result {
                case .success(let items):
                    if items.isEmpty {
                        labelView(
                            iconSystemName: "list.dash",
                            iconColor: .secondary,
                            message: "No unread entry"
                        )
                    } else {
                        ViewThatFits(in: .vertical) {
                            ForEach((1...10).reversed(), id: \.self) { n in
                                ItemsView(items: items, visibleCount: n)
                            }
                        }
                    }
                case .failure:
                    labelView(
                        iconSystemName: "xmark.circle",
                        iconColor: .red,
                        message: "Something went wrong"
                    )
                }
            }
            .frame(maxHeight: .infinity)
        }
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
    
    func labelView(iconSystemName: String, iconColor: Color, message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: iconSystemName)
                .font(.system(size: 24))
                .foregroundStyle(iconColor)
            
            Text(message)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

struct ItemsView: View {
    let items: [Item]
    let visibleCount: Int
    
    @Environment(\.widgetFamily) private var family
    
    private var titleLineLimit: Int {
        switch family {
        case .accessoryRectangular, .systemSmall:
            2
        default:
            1
        }
    }
    
    var body: some View {
        VStack(spacing: 4) {
            ForEach(items.prefix(visibleCount)) { item in
                VStack(spacing: 0) {
                    Text(item.feedTitle)
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                        .font(.system(size: 10))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(item.title)
                        .lineLimit(titleLineLimit)
                        .font(.system(size: 13, weight: .bold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}


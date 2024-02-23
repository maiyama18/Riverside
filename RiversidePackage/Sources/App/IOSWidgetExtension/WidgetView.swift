import SwiftUI
import WidgetKit

struct WidgetView: View {
    let entry: Provider.Entry
    
    var body: some View {
        VStack {
            HStack {
                Image(.logo)
                    .resizable()
                    .frame(width: 24, height: 24)
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
                                itemsView(items: items, visibleCount: n)
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
    
    func itemsView(items: [Item], visibleCount: Int) -> some View {
        VStack(spacing: 4) {
            ForEach(items.prefix(visibleCount)) { item in
                VStack(spacing: 2) {
                    Text(item.feedTitle)
                        .foregroundStyle(.secondary)
                        .font(.system(size: 9))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(item.title)
                        .lineLimit(2)
                        .font(.system(size: 12, weight: .bold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
    
    func labelView(iconSystemName: String, iconColor: Color, message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: iconSystemName)
                .font(.system(size: 24))
                .foregroundStyle(iconColor)
            
            Text(message)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

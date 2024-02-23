import SwiftUI
import WidgetKit

struct WidgetView: View {
    let entry: Provider.Entry
    
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall, .systemMedium, .systemLarge, .systemExtraLarge:
            SystemWidgetView(entry: entry)
        case .accessoryRectangular:
            AccessoryRectangularWidgetView(entry: entry)
        case .accessoryInline:
            AccessoryInlineWidgetView(entry: entry)
        case .accessoryCircular:
            Text("Not Supported")
        @unknown default:
            Text("Not Supported")
        }
    }
}

struct SystemWidgetView: View {
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
                    .font(.system(size: 13))
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
                    VStack(alignment: .leading, spacing: 0) {
                        Text(item.feedTitle)
                            .lineLimit(1)
                            .foregroundStyle(.secondary)
                            .font(.system(size: 10))
                        
                        Text(item.title)
                            .lineLimit(titleLineLimit)
                            .font(.system(size: 13, weight: .bold))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

struct AccessoryRectangularWidgetView: View {
    let entry: Provider.Entry
    
    var body: some View {
        Group {
            switch entry.result {
            case .success(let items):
                if let item = items.first {
                    VStack(spacing: 4) {
                        Group {
                            Text("\(items.count)").bold() + Text(" unreads")
                        }
                        .font(.system(size: 12))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text(item.feedTitle)
                                .lineLimit(1)
                                .foregroundStyle(.secondary)
                                .font(.system(size: 9))
                            
                            Text(item.title)
                                .lineLimit(2)
                                .font(.system(size: 12, weight: .bold))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    }
                } else {
                    VStack(alignment: .leading) {
                        Text("Riverside")
                            .font(.system(size: 13, weight: .bold))
                        
                        Text("No unread entry")
                            .font(.system(size: 13))
                            .frame(maxHeight: .infinity, alignment: .bottomLeading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            case .failure:
                VStack(alignment: .leading) {
                    Text("Riverside")
                        .font(.system(size: 13, weight: .bold))
                    
                    Text("Something went wrong")
                        .font(.system(size: 13))
                        .frame(maxHeight: .infinity, alignment: .bottomLeading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
}

struct AccessoryInlineWidgetView: View {
    let entry: Provider.Entry
    
    var body: some View {
        switch entry.result {
        case .success(let items):
            if items.isEmpty {
                Text("No unread entry")
            } else {
                Text("\(items.count)").bold() + Text(" unreads")
            }
        case .failure:
            Text("Error")
        }
    }
}

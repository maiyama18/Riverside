import SwiftUI
import WidgetKit

struct WidgetView: View {
    let entry: Provider.Entry
    
    @Environment(\.widgetFamily) private var family
    
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
    
    @Environment(\.widgetFamily) private var family
    
    private var logoSize: CGFloat {
        switch family {
        case .systemSmall, .systemMedium:
            16
        default:
            24
        }
    }
    
    private var primaryFontSize: CGFloat {
        switch family {
        case .systemSmall, .systemMedium:
            13
        default:
            15
        }
    }
    
    private var secondaryFontSize: CGFloat {
        switch family {
        case .systemSmall, .systemMedium:
            10
        default:
            12
        }
    }
    
    private var labelIconSize: CGFloat {
        switch family {
        case .systemSmall, .systemMedium:
            24
        default:
            32
        }
    }
    
    private var itemTitleLineLimit: Int {
        switch family {
        case .systemSmall:
            2
        default:
            1
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(.logo)
                    .resizable()
                    .frame(width: logoSize, height: logoSize)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                
                if case .success(let items) = entry.result, !items.isEmpty {
                    Group {
                        Text("\(items.count)").bold() + Text(" unreads")
                    }
                    .font(.system(size: primaryFontSize))
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
                            ForEach((1...10).reversed(), id: \.self) { itemCount in
                                itemsView(items: items, itemCount: itemCount, itemTitleLineLimit: itemTitleLineLimit)
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
                .font(.system(size: labelIconSize))
                .foregroundStyle(iconColor)
            
            Text(message)
                .font(.system(size: primaryFontSize))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    func itemsView(items: [Item], itemCount: Int, itemTitleLineLimit: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(items.prefix(itemCount)) { item in
                VStack(alignment: .leading, spacing: 0) {
                    Text(item.feedTitle)
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                        .font(.system(size: secondaryFontSize))
                    
                    Text(item.title)
                        .lineLimit(itemTitleLineLimit)
                        .font(.system(size: primaryFontSize, weight: .bold))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxHeight: .infinity)
    }
}

struct AccessoryRectangularWidgetView: View {
    let entry: Provider.Entry
    
    var body: some View {
        Group {
            switch entry.result {
            case .success(let items):
                if let item = items.first {
                    VStack(spacing: 2) {
                        Group {
                            Text("\(items.count)").bold() + Text(" unreads")
                        }
                        .font(.system(size: 12))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text(item.feedTitle)
                                .lineLimit(1)
                                .foregroundStyle(.secondary)
                                .font(.system(size: 10))
                            
                            Text(item.title)
                                .lineLimit(2)
                                .font(.system(size: 12, weight: .bold))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    }
                } else {
                    singleMessageView(message: "No unread entry")
                }
            case .failure:
                singleMessageView(message: "Something went wrong")
            }
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
    
    func singleMessageView(message: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Riverside")
                .font(.system(size: 13, weight: .bold))
            
            Text(message)
                .font(.system(size: 13))
                .frame(maxHeight: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

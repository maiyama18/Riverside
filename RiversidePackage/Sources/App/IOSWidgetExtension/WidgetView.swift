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
                        VStack(spacing: 8) {
                            Image(systemName: "list.dash")
                                .font(.system(size: 24))
                            
                            Text("No unread entry")
                                .font(.system(size: 12))
                                .multilineTextAlignment(.center)
                        }
                        .foregroundColor(.secondary)
                    } else {
                        VStack(spacing: 6) {
                            ForEach(items.prefix(2)) { item in
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
                case .failure:
                    VStack(spacing: 8) {
                        Image(systemName: "xmark.circle")
                            .font(.system(size: 24))
                            .foregroundColor(.red)
                        
                        Text("Something went wrong")
                            .font(.system(size: 12))
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .frame(maxHeight: .infinity)
        }
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
}

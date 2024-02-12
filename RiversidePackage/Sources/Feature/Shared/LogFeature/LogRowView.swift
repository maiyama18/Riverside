import SwiftUI
import Logging
import OSLog

let logDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "MM-dd HH:mm:ss.SSS"
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US")
    return formatter
}()

extension LogCategory {
    var color: Color {
        switch self {
        case .app:
            .indigo
        case .appExtension:
            .teal
        case .feature:
            .pink
        case .iCloud:
            .blue
        case .feedModel:
            .green
        }
    }
}

extension OSLogEntryLog.Level {
    var color: Color {
        switch self {
        case .undefined:
            .clear
        case .debug:
            .clear
        case .info:
            .clear
        case .notice:
            .gray
        case .error:
            .yellow
        case .fault:
            .red
        @unknown default:
            .clear
        }
    }
}

struct LogRowView: View {
    var entry: LogEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "circle.fill")
                    .foregroundColor(entry.level.color)
                    .font(.caption2)
                
                Text(logDateFormatter.string(from: entry.date))
                
                Text(entry.category.rawValue)
                    .foregroundStyle(.white)
                    .padding(.vertical, 2)
                    .padding(.horizontal, 4)
                    .background(entry.category.color)
                    .cornerRadius(4)
                    .bold()
            }
            
            Text(entry.message)
                .lineLimit(5)
        }
        .font(.caption.monospaced())
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

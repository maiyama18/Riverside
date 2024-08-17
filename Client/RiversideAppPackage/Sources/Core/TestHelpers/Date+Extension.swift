import Foundation

let iso8601DateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
    return dateFormatter
}()

extension Date {
    public static func fromISO8601String(_ string: String) -> Date {
        iso8601DateFormatter.date(from: string)!
    }
}

import Foundation

enum RetryAfterParser {
    static func deadline(header: String?, now: Date, attempt: Int) -> Date {
        if let header {
            let trimmed = header.trimmingCharacters(in: .whitespacesAndNewlines)
            if let seconds = TimeInterval(trimmed) {
                return now.addingTimeInterval(max(0, seconds))
            }
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
            if let date = formatter.date(from: trimmed) {
                return max(date, now)
            }
        }
        let delay = min(300, 30 * pow(2.0, Double(max(0, attempt - 1))))
        return now.addingTimeInterval(delay)
    }
}

enum TransientURLErrorPolicy {
    static let retryDelay: Duration = .seconds(2)

    static func isTransient(_ error: URLError) -> Bool {
        switch error.code {
        case .timedOut, .networkConnectionLost, .cannotConnectToHost, .dnsLookupFailed:
            true
        default:
            false
        }
    }
}

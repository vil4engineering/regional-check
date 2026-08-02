import Foundation
import os

enum UbillingError: Error, Equatable {
    case unexpectedResponse(statusCode: Int?, contentType: String?, bodyPrefix: String)
}

struct UbillingProvider: StatusProviding {
    private static let log = Logger(subsystem: "vil4max.RegionalCheck", category: "Data")

    private let httpClient: any HTTPClient
    private let now: @Sendable () -> Date

    init(httpClient: any HTTPClient = URLSession.shared, now: @escaping @Sendable () -> Date = { Date() }) {
        self.httpClient = httpClient
        self.now = now
    }

    func fetchAlerts() async throws -> AlertsSnapshot {
        let response = try await fetchResponse()
        let fetchedAt = now()
        var statuses: [AlertRegion: AlertStatus] = [:]
        statuses.reserveCapacity(AlertRegion.allCases.count)

        for (key, state) in response.states {
            guard let region = AlertRegion.from(apiKey: key) else {
                Self.log.error("Ignoring unknown Ubilling region key=\(key, privacy: .public)")
                continue
            }
            statuses[region] = state.alertnow ? .alarm : .quiet
        }

        return AlertsSnapshot(
            source: response.source,
            serverCachedAt: Self.parseCachedAt(response.cachedat),
            fetchedAt: fetchedAt,
            statuses: statuses
        )
    }

    private func fetchResponse() async throws -> Response {
        let url = URL(string: "https://ubilling.net.ua/aerialalerts/")!
        let (data, response) = try await httpClient.data(from: url)

        if let http = response as? HTTPURLResponse {
            let statusCode = http.statusCode
            let contentType = http.value(forHTTPHeaderField: "Content-Type")

            if !(200 ... 299).contains(statusCode) {
                let prefix = Self.bodyPrefix(data)
                Self.log.error("Ubilling HTTP \(statusCode) contentType=\(contentType ?? "nil", privacy: .public)")
                throw UbillingError.unexpectedResponse(
                    statusCode: statusCode,
                    contentType: contentType,
                    bodyPrefix: prefix
                )
            }

            if let contentType, !contentType.localizedCaseInsensitiveContains("application/json") {
                let prefix = Self.bodyPrefix(data)
                Self.log.error("Ubilling non-JSON contentType=\(contentType, privacy: .public)")
                throw UbillingError.unexpectedResponse(
                    statusCode: statusCode,
                    contentType: contentType,
                    bodyPrefix: prefix
                )
            }
        }

        do {
            return try JSONDecoder().decode(Response.self, from: data)
        } catch {
            let prefix = Self.bodyPrefix(data)
            Self.log.error("Ubilling decode failed: \(String(describing: error), privacy: .public)")
            throw UbillingError.unexpectedResponse(
                statusCode: (response as? HTTPURLResponse)?.statusCode,
                contentType: (response as? HTTPURLResponse)?.value(forHTTPHeaderField: "Content-Type"),
                bodyPrefix: prefix
            )
        }
    }

    private static func parseCachedAt(_ raw: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.date(from: raw)
    }

    private static func bodyPrefix(_ data: Data, maxBytes: Int = 240) -> String {
        guard !data.isEmpty else { return "<empty>" }
        let slice = data.prefix(maxBytes)
        return String(data: slice, encoding: .utf8) ?? "<non-utf8 \(slice.count) bytes>"
    }

    private struct Response: Decodable {
        struct Region: Decodable {
            let alertnow: Bool
        }

        let source: String
        let cachedat: String
        let states: [String: Region]
    }
}

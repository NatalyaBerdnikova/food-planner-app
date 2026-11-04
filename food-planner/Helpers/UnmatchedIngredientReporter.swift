import CryptoKit
import Foundation
import OSLog

struct UnmatchedIngredientReportItem: Codable, Equatable, Sendable {
    var name: String
    var amount: Double
    var unit: String
    var language: String
    var sourceRecipeUrl: String?
}

struct UnmatchedIngredientsReportPayload: Codable, Equatable, Sendable {
    var appVersion: String
    var sourceRecipeUrl: String?
    var ingredients: [UnmatchedIngredientReportItem]
}

enum UnmatchedIngredientHMACSigner {
    static let timestampHeader = "X-FoodPlanner-Timestamp"
    static let signatureHeader = "X-FoodPlanner-Signature"
    static let signaturePrefix = "sha256="

    static func canonicalSigningMessage(timestamp: String, rawBody: Data) -> Data {
        var message = Data("\(timestamp).".utf8)
        message.append(rawBody)
        return message
    }

    static func signatureHex(
        secret: String,
        timestamp: String,
        rawBody: Data
    ) -> String {
        let key = SymmetricKey(data: Data(secret.utf8))
        let message = canonicalSigningMessage(timestamp: timestamp, rawBody: rawBody)
        let mac = HMAC<SHA256>.authenticationCode(for: message, using: key)
        return mac.map { String(format: "%02x", $0) }.joined()
    }

    static func signatureHeaderValue(
        secret: String,
        timestamp: String,
        rawBody: Data
    ) -> String {
        "\(signaturePrefix)\(signatureHex(secret: secret, timestamp: timestamp, rawBody: rawBody))"
    }

    static func signedHeaders(
        secret: String,
        timestampSeconds: Int,
        rawBody: Data
    ) -> [String: String] {
        let timestamp = String(timestampSeconds)
        let signature = signatureHeaderValue(secret: secret, timestamp: timestamp, rawBody: rawBody)
        return [
            timestampHeader: timestamp,
            signatureHeader: signature,
        ]
    }
}

enum UnmatchedIngredientPayloadBuilder {
    static let maxNameLength = 160
    static let maxAmount: Double = 100_000

    static func normalizedLanguageCode(_ languageCode: String) -> String {
        languageCode.lowercased().hasPrefix("ru") ? "ru" : "en"
    }

    static func buildPayload(
        from unresolved: [UnresolvedIngredient],
        sourceRecipeUrl: String?,
        languageCode: String = L10n.currentLanguageCode,
        appVersion: String = AppVars.appVersion
    ) -> UnmatchedIngredientsReportPayload? {
        let lang = normalizedLanguageCode(languageCode)
        let trimmedURL = sourceRecipeUrl?.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedURL = (trimmedURL?.isEmpty == false) ? trimmedURL : nil

        let items: [UnmatchedIngredientReportItem] = unresolved.compactMap { item in
            let trimmedName = item.rawName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedName.isEmpty else { return nil }
            let boundedName = String(trimmedName.prefix(maxNameLength))
            let positiveAmount = item.suggestedQuantity > 0 ? item.suggestedQuantity : 1
            let boundedAmount = min(positiveAmount, maxAmount)
            return UnmatchedIngredientReportItem(
                name: boundedName,
                amount: boundedAmount,
                unit: item.suggestedUnit.rawValue,
                language: lang,
                sourceRecipeUrl: resolvedURL
            )
        }

        guard !items.isEmpty else { return nil }

        let resolvedVersion = appVersion.trimmingCharacters(in: .whitespacesAndNewlines)

        return UnmatchedIngredientsReportPayload(
            appVersion: resolvedVersion.isEmpty ? "Unknown" : resolvedVersion,
            sourceRecipeUrl: resolvedURL,
            ingredients: items
        )
    }

    static func encodePayload(_ payload: UnmatchedIngredientsReportPayload) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(payload)
    }
}

enum UnmatchedIngredientReporter {
    struct QueuedReport: Codable, Equatable, Identifiable, Sendable {
        var id: UUID
        var payload: UnmatchedIngredientsReportPayload
        var createdAt: Date
        var attemptCount: Int
        var nextRetryAt: Date?

        init(
            id: UUID = UUID(),
            payload: UnmatchedIngredientsReportPayload,
            createdAt: Date = .now,
            attemptCount: Int = 0,
            nextRetryAt: Date? = nil
        ) {
            self.id = id
            self.payload = payload
            self.createdAt = createdAt
            self.attemptCount = attemptCount
            self.nextRetryAt = nextRetryAt
        }
    }

    private static let logger = Logger(
        subsystem: "com.mikhail-chugaev.food-planner",
        category: "UnmatchedIngredientReporter"
    )
    private static let appSupportFolder = "food-planner"
    private static let queueFileName = "unmatched-ingredients-queue.json"
    static let maxQueueSize = 50
    static let maxAttemptsPerItem = 5

    private actor QueueWorker {
        private var isFlushing = false

        func beginFlushIfIdle() -> Bool {
            guard !isFlushing else { return false }
            isFlushing = true
            return true
        }

        func endFlush() {
            isFlushing = false
        }
    }

    private static let worker = QueueWorker()

    static func reportInBackground(
        unresolved: [UnresolvedIngredient],
        sourceRecipeUrl: String?,
        languageCode: String = L10n.currentLanguageCode,
        appVersion: String = AppVars.appVersion
    ) {
        guard let payload = UnmatchedIngredientPayloadBuilder.buildPayload(
            from: unresolved,
            sourceRecipeUrl: sourceRecipeUrl,
            languageCode: languageCode,
            appVersion: appVersion
        ) else {
            return
        }

        Task(priority: .utility) {
            await enqueueAndFlush(payload: payload)
        }
    }

    static func flushQueueInBackground() {
        Task(priority: .utility) {
            _ = await flushQueue()
        }
    }

    static func enqueueAndFlush(
        payload: UnmatchedIngredientsReportPayload,
        queueFileURL: URL = defaultQueueFileURL(),
        endpointURL: URL = BackendAPIConfig.unmatchedIngredientsURL,
        secret: String = BackendAPIConfig.ingestSecret,
        httpClient: RemoteCatalogHTTPClient = URLSessionCatalogHTTPClient(),
        now: Date = .now
    ) async {
        enqueue(payload: payload, queueFileURL: queueFileURL, now: now)
        _ = await flushQueue(
            queueFileURL: queueFileURL,
            endpointURL: endpointURL,
            secret: secret,
            httpClient: httpClient,
            now: now
        )
    }

    static func enqueue(
        payload: UnmatchedIngredientsReportPayload,
        queueFileURL: URL = defaultQueueFileURL(),
        now: Date = .now
    ) {
        var queue = loadQueue(from: queueFileURL)
        queue.append(QueuedReport(payload: payload, createdAt: now))
        if queue.count > maxQueueSize {
            queue = Array(queue.suffix(maxQueueSize))
        }
        saveQueue(queue, to: queueFileURL)
    }

    @discardableResult
    static func flushQueue(
        queueFileURL: URL = defaultQueueFileURL(),
        endpointURL: URL = BackendAPIConfig.unmatchedIngredientsURL,
        secret: String = BackendAPIConfig.ingestSecret,
        httpClient: RemoteCatalogHTTPClient = URLSessionCatalogHTTPClient(),
        now: Date = .now
    ) async -> Int {
        let trimmedSecret = secret.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSecret.isEmpty,
              trimmedSecret != BackendAPIConfig.placeholderIngestSecret else {
            return 0
        }

        guard await worker.beginFlushIfIdle() else {
            return 0
        }
        defer {
            Task { await worker.endFlush() }
        }

        let currentQueue = loadQueue(from: queueFileURL)
        guard !currentQueue.isEmpty else { return 0 }

        var remaining: [QueuedReport] = []
        var sentCount = 0
        var rateLimitedUntil: Date?

        for var item in currentQueue {
            if let rateLimitedUntil, now < rateLimitedUntil {
                if item.nextRetryAt == nil || item.nextRetryAt! < rateLimitedUntil {
                    item.nextRetryAt = rateLimitedUntil
                }
                remaining.append(item)
                continue
            }

            if let nextRetryAt = item.nextRetryAt, now < nextRetryAt {
                remaining.append(item)
                continue
            }

            do {
                let request = try buildSignedRequest(
                    payload: item.payload,
                    endpointURL: endpointURL,
                    secret: trimmedSecret,
                    timestampSeconds: Int(now.timeIntervalSince1970)
                )
                let (_, response) = try await httpClient.data(for: request)
                let status = response.statusCode

                if (200...299).contains(status) {
                    sentCount += 1
                } else if status == 401 {
                    logger.error("Unmatched ingredient report rejected with 401 Unauthorized; dropping item \(item.id.uuidString, privacy: .public)")
                    continue
                } else if status == 400 || status == 422 {
                    logger.warning("Unmatched ingredient report rejected with \(status, privacy: .public); dropping item \(item.id.uuidString, privacy: .public)")
                    continue
                } else if status == 429 {
                    let retryDelay = parseRetryAfterSeconds(from: response, now: now) ?? 60
                    let retryDate = now.addingTimeInterval(retryDelay)
                    rateLimitedUntil = retryDate
                    item.attemptCount += 1
                    item.nextRetryAt = retryDate
                    if item.attemptCount < maxAttemptsPerItem {
                        remaining.append(item)
                    }
                } else if (400...499).contains(status), status != 408 {
                    continue
                } else {
                    item.attemptCount += 1
                    item.nextRetryAt = nil
                    if item.attemptCount < maxAttemptsPerItem {
                        remaining.append(item)
                    }
                }
            } catch {
                item.attemptCount += 1
                item.nextRetryAt = nil
                if item.attemptCount < maxAttemptsPerItem {
                    remaining.append(item)
                }
            }
        }

        saveQueue(remaining, to: queueFileURL)
        return sentCount
    }

    static func buildSignedRequest(
        payload: UnmatchedIngredientsReportPayload,
        endpointURL: URL = BackendAPIConfig.unmatchedIngredientsURL,
        secret: String,
        timestampSeconds: Int
    ) throws -> URLRequest {
        let body = try UnmatchedIngredientPayloadBuilder.encodePayload(payload)
        let headers = UnmatchedIngredientHMACSigner.signedHeaders(
            secret: secret,
            timestampSeconds: timestampSeconds,
            rawBody: body
        )

        var request = URLRequest(url: endpointURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        for (header, value) in headers {
            request.setValue(value, forHTTPHeaderField: header)
        }
        request.httpBody = body
        return request
    }

    static func parseRetryAfterSeconds(from response: HTTPURLResponse, now: Date = .now) -> TimeInterval? {
        for (key, value) in response.allHeaderFields {
            guard let keyStr = key as? String,
                  keyStr.caseInsensitiveCompare("Retry-After") == .orderedSame,
                  let rawValue = value as? String else {
                continue
            }
            let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if let seconds = Double(trimmed), seconds >= 0 {
                return seconds
            }
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
            if let date = formatter.date(from: trimmed) {
                return max(0, date.timeIntervalSince(now))
            }
        }
        return nil
    }

    // MARK: - Disk Queue Persistence

    static func defaultQueueFileURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base
            .appendingPathComponent(appSupportFolder, isDirectory: true)
            .appendingPathComponent(queueFileName)
    }

    static func loadQueue(from url: URL = defaultQueueFileURL()) -> [QueuedReport] {
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([QueuedReport].self, from: data) else {
            return []
        }
        return decoded
    }

    static func saveQueue(_ queue: [QueuedReport], to url: URL = defaultQueueFileURL()) {
        if queue.isEmpty {
            try? FileManager.default.removeItem(at: url)
            return
        }
        guard let data = try? JSONEncoder().encode(queue) else { return }
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try? data.write(to: url, options: .atomic)
    }
}

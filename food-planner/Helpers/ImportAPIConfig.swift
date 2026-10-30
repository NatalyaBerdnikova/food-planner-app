import Foundation

enum ImportAPIConfig {
    static var scrapeCreatorsKey: String { string("SCRAPE_CREATORS_API_KEY") }
    static var aiProviderApiKey: String { string("AI_PROVIDER_API_KEY") }

    static var aiProviderBaseURL: String {
        string("AI_PROVIDER_BASE_URL", default: "https://polza.ai/api/v1")
    }

    static var aiProviderModel: String {
        string("AI_PROVIDER_MODEL", default: "deepseek/deepseek-v4-flash")
    }

    static var aiProviderTemperature: Double {
        double("AI_PROVIDER_TEMPERATURE", default: 0.2)
    }

    static var aiProviderTopP: Double {
        double("AI_PROVIDER_TOP_P", default: 0.95)
    }

    static var aiProviderMaxTokens: Int {
        int("AI_PROVIDER_MAX_TOKENS", default: 8192)
    }

    static var aiProviderTimeoutSeconds: TimeInterval {
        TimeInterval(int("AI_PROVIDER_TIMEOUT_SECONDS", default: 240))
    }

    static var aiProviderThinkingEnabled: Bool {
        bool("AI_PROVIDER_THINKING", default: false)
    }

    /// When false, Instagram import uses only the post caption (skips transcript API).
    static var fetchInstagramTranscript: Bool {
        bool("IMPORT_FETCH_TRANSCRIPT", default: false)
    }

    private static let secretsFileName = "ImportSecrets"
    private static var cachedPlist: [String: Any]?

    private static func plist() -> [String: Any] {
        if let cachedPlist { return cachedPlist }

        guard let url = Bundle.main.url(forResource: secretsFileName, withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let object = try? PropertyListSerialization.propertyList(from: data, format: nil),
              let dict = object as? [String: Any]
        else {
            cachedPlist = [:]
            return [:]
        }

        cachedPlist = dict
        return dict
    }

    private static func string(_ key: String, default defaultValue: String = "") -> String {
        if let value = ProcessInfo.processInfo.environment[key]?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !value.isEmpty {
            return value
        }

        if let value = plist()[key] as? String {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { return trimmed }
        }

        return defaultValue
    }

    private static func double(_ key: String, default defaultValue: Double) -> Double {
        if let raw = ProcessInfo.processInfo.environment[key],
           let value = Double(raw.trimmingCharacters(in: .whitespacesAndNewlines)) {
            return value
        }

        let value = plist()[key]
        if let number = value as? NSNumber {
            return number.doubleValue
        }
        if let raw = value as? String,
           let parsed = Double(raw.trimmingCharacters(in: .whitespacesAndNewlines)) {
            return parsed
        }

        return defaultValue
    }

    private static func int(_ key: String, default defaultValue: Int) -> Int {
        if let raw = ProcessInfo.processInfo.environment[key],
           let value = Int(raw.trimmingCharacters(in: .whitespacesAndNewlines)) {
            return value
        }

        let value = plist()[key]
        if let number = value as? NSNumber {
            return number.intValue
        }
        if let raw = value as? String,
           let parsed = Int(raw.trimmingCharacters(in: .whitespacesAndNewlines)) {
            return parsed
        }

        return defaultValue
    }

    private static func bool(_ key: String, default defaultValue: Bool) -> Bool {
        if let raw = ProcessInfo.processInfo.environment[key]?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased(),
           !raw.isEmpty {
            return ["1", "true", "yes", "y"].contains(raw)
        }

        let value = plist()[key]
        if let number = value as? NSNumber {
            return number.boolValue
        }
        if let raw = value as? String {
            return ["1", "true", "yes", "y"].contains(raw.lowercased())
        }

        return defaultValue
    }
}

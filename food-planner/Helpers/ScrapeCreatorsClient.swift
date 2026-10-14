import Foundation

struct InstagramPostInfo {
    var caption: String
    var thumbnailURL: URL?
}

enum ScrapeCreatorsClient {
    private static let baseURL = "https://api.scrapecreators.com"

    private struct TranscriptResponse: Decodable {
        struct TranscriptItem: Decodable {
            var text: String?
        }

        var success: Bool?
        var transcripts: [TranscriptItem]?
    }

    private struct PostMedia: Decodable {
        struct CaptionEdge: Decodable {
            struct Node: Decodable {
                var text: String?
            }
            var node: Node?
        }

        struct CaptionContainer: Decodable {
            var edges: [CaptionEdge]?
        }

        var thumbnail_src: String?
        var display_url: String?
        var caption: String?
        var edge_media_to_caption: CaptionContainer?
    }

    private struct PostResponse: Decodable {
        struct DataWrapper: Decodable {
            var xdt_shortcode_media: PostMedia?
        }

        var success: Bool?
        var status: String?
        var data: DataWrapper?
        var xdt_shortcode_media: PostMedia?
    }

    static func fetchPostInfo(url: String) async throws -> InstagramPostInfo {
        guard !ImportAPIConfig.scrapeCreatorsKey.isEmpty,
              ImportAPIConfig.scrapeCreatorsKey != "YOUR_SCRAPECREATORS_API_KEY" else {
            throw RecipeImportError.instagramUnavailable
        }

        let normalizedURL = normalizeInstagramURL(url)

        var components = URLComponents(string: "\(baseURL)/v1/instagram/post")!
        components.queryItems = [
            URLQueryItem(name: "url", value: normalizedURL),
            URLQueryItem(name: "trim", value: "true"),
        ]

        let data = try await performRequest(url: components.url!)
        let response = try JSONDecoder().decode(PostResponse.self, from: data)

        guard isSuccessfulPostResponse(response),
              let media = response.xdt_shortcode_media ?? response.data?.xdt_shortcode_media else {
            throw RecipeImportError.instagramUnavailable
        }

        let caption = extractCaption(from: media)
        let thumbnailString = media.thumbnail_src ?? media.display_url
        let thumbnailURL = thumbnailString.flatMap(URL.init(string:))

        return InstagramPostInfo(caption: caption, thumbnailURL: thumbnailURL)
    }

    private static func isSuccessfulPostResponse(_ response: PostResponse) -> Bool {
        response.success == true || response.status == "ok"
    }

    private static func extractCaption(from media: PostMedia) -> String {
        if let direct = media.caption?.trimmingCharacters(in: .whitespacesAndNewlines),
           !direct.isEmpty {
            return direct
        }

        return media.edge_media_to_caption?.edges?
            .compactMap { $0.node?.text }
            .joined(separator: "\n") ?? ""
    }

    static func normalizeInstagramURL(_ url: String) -> String {
        let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard var components = URLComponents(string: trimmed) else { return trimmed }

        components.query = nil
        components.fragment = nil

        var path = components.path
        if path.hasSuffix("/") {
            path.removeLast()
        }
        components.path = path

        return components.string ?? trimmed
    }

    static func fetchTranscriptIfAvailable(url: String) async -> String {
        do {
            return try await fetchTranscript(url: url)
        } catch {
            return ""
        }
    }

    static func fetchTranscript(url: String) async throws -> String {
        guard !ImportAPIConfig.scrapeCreatorsKey.isEmpty,
              ImportAPIConfig.scrapeCreatorsKey != "YOUR_SCRAPECREATORS_API_KEY" else {
            throw RecipeImportError.transcriptionFailed
        }

        let normalizedURL = normalizeInstagramURL(url)

        var components = URLComponents(string: "\(baseURL)/v2/instagram/media/transcript")!
        components.queryItems = [URLQueryItem(name: "url", value: normalizedURL)]

        let data = try await performRequest(url: components.url!, timeout: 60)
        let response = try JSONDecoder().decode(TranscriptResponse.self, from: data)

        let texts = response.transcripts?
            .compactMap { $0.text?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty } ?? []

        return texts.joined(separator: "\n")
    }

    private static func performRequest(url: URL, timeout: TimeInterval = 30) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = timeout
        request.setValue(ImportAPIConfig.scrapeCreatorsKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw RecipeImportError.networkFailure
        }

        guard let http = response as? HTTPURLResponse else {
            throw RecipeImportError.networkFailure
        }

        guard (200...299).contains(http.statusCode) else {
            if http.statusCode == 404 {
                throw RecipeImportError.instagramUnavailable
            }
            throw RecipeImportError.networkFailure
        }

        return data
    }
}

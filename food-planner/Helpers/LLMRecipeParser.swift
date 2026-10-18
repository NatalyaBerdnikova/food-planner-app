import Foundation

struct ParsedRecipe {
    var name: String
    var servings: Int?
    var cookTimeMinutes: Int?
    var steps: [String]
    var ingredients: [ParsedIngredient]
}

enum LLMRecipeParser {
    private static let importURLSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 180
        configuration.timeoutIntervalForResource = 180
        configuration.waitsForConnectivity = true
        return URLSession(configuration: configuration)
    }()

    private struct ChatResponse: Decodable {
        struct APIError: Decodable {
            struct Detail: Decodable {
                var message: String?
                var code: String?
            }
            var error: Detail?
        }

        struct Choice: Decodable {
            struct Message: Decodable {
                var content: String?
            }
            var message: Message
        }

        var choices: [Choice]
    }

    private struct RecipeJSON: Decodable {
        struct IngredientJSON: Decodable {
            var catalogKey: String?
            var rawName: String
            var quantity: Double
            var unit: String
        }

        var name: String
        var servings: Int?
        var cookTimeMinutes: Int?
        var steps: [String]
        var ingredients: [IngredientJSON]
    }

    static func parse(caption: String, transcript: String) async throws -> ParsedRecipe {
        guard !ImportAPIConfig.nvidiaApiKey.isEmpty,
              ImportAPIConfig.nvidiaApiKey != "YOUR_NVIDIA_API_KEY" else {
            throw RecipeImportError.apiUnauthorized
        }

        let catalogSnippet = IngredientCatalogPrompt.compactCatalogForPrompt()
        let systemPrompt = """
        You extract structured recipes from Instagram Reel captions and transcripts.
        Prefer ingredient quantities from CAPTION when both sources exist.
        Do not invent ingredients that are not mentioned in the text.
        When an ingredient matches the food catalog, set catalogKey to that key; otherwise set catalogKey to null and keep rawName.
        Ingredient units must be one of: gram, kilogram, milliliter, liter, piece, tablespoon, teaspoon.
        Reply with JSON only, no markdown and no extra text.
        JSON schema:
        {
          "name": "string",
          "servings": number or null,
          "cookTimeMinutes": number or null,
          "steps": ["string"],
          "ingredients": [{"catalogKey": "string or null", "rawName": "string", "quantity": number, "unit": "string"}]
        }

        Food catalog (catalogKey | ru | en), use only keys from this list:
        \(catalogSnippet)
        """

        let userPrompt = """
        CAPTION:
        \(caption)

        TRANSCRIPT:
        \(transcript)
        """

        let body = makeRequestBody(systemPrompt: systemPrompt, userPrompt: userPrompt)
        let endpoint = URL(string: "\(ImportAPIConfig.nvidiaBaseURL)/chat/completions")!

        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.timeoutInterval = 180
        urlRequest.setValue("Bearer \(ImportAPIConfig.nvidiaApiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)

        let data: Data
        let http: HTTPURLResponse
        do {
            let response = try await importURLSession.data(for: urlRequest)
            data = response.0
            guard let status = response.1 as? HTTPURLResponse else {
                throw RecipeImportError.networkFailure
            }
            http = status
        } catch let error as RecipeImportError {
            throw error
        } catch {
            throw RecipeImportError.networkFailure
        }

        if !(200...299).contains(http.statusCode) {
            throw mapAPIError(statusCode: http.statusCode, data: data)
        }

        let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard let content = chatResponse.choices.first?.message.content else {
            throw RecipeImportError.parsingFailed
        }

        let decoded = try decodeRecipeJSON(from: content)

        guard !decoded.name.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw RecipeImportError.parsingFailed
        }

        let ingredients = decoded.ingredients.map { item in
            ParsedIngredient(
                catalogKey: item.catalogKey?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
                rawName: item.rawName,
                quantity: item.quantity,
                unit: item.unit
            )
        }

        let cookTime = decoded.cookTimeMinutes.map { max($0, 0) }
        return ParsedRecipe(
            name: decoded.name.trimmingCharacters(in: .whitespaces),
            servings: decoded.servings,
            cookTimeMinutes: cookTime,
            steps: decoded.steps,
            ingredients: ingredients
        )
    }

    private static func decodeRecipeJSON(from content: String) throws -> RecipeJSON {
        let payload = extractJSONPayload(from: content)
        guard let data = payload.data(using: .utf8) else {
            throw RecipeImportError.parsingFailed
        }

        do {
            return try JSONDecoder().decode(RecipeJSON.self, from: data)
        } catch {
            throw RecipeImportError.parsingFailed
        }
    }

    private static func extractJSONPayload(from content: String) -> String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)

        if let jsonFence = trimmed.range(of: "```json"),
           let endFence = trimmed.range(of: "```", range: jsonFence.upperBound..<trimmed.endIndex) {
            return String(trimmed[jsonFence.upperBound..<endFence.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let fence = trimmed.range(of: "```"),
           let endFence = trimmed.range(of: "```", range: fence.upperBound..<trimmed.endIndex) {
            return String(trimmed[fence.upperBound..<endFence.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let start = trimmed.firstIndex(of: "{"),
           let end = trimmed.lastIndex(of: "}") {
            return String(trimmed[start...end])
        }

        return trimmed
    }

    private static func mapAPIError(statusCode: Int, data: Data) -> RecipeImportError {
        if let apiError = try? JSONDecoder().decode(ChatResponse.APIError.self, from: data),
           let code = apiError.error?.code {
            switch code {
            case "insufficient_quota", "rate_limit_exceeded":
                return .apiQuotaExceeded
            case "invalid_api_key", "authentication_error", "unauthorized":
                return .apiUnauthorized
            default:
                break
            }
        }

        switch statusCode {
        case 401, 403:
            return .apiUnauthorized
        case 429:
            return .apiQuotaExceeded
        default:
            return .parsingFailed
        }
    }

    private static func makeRequestBody(systemPrompt: String, userPrompt: String) -> [String: Any] {
        [
            "model": ImportAPIConfig.nvidiaModel,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt],
            ],
            "temperature": 0.3,
            "top_p": 0.95,
            "max_tokens": 4096,
            "chat_template_kwargs": ["thinking": false],
            "stream": false,
        ]
    }
}

private extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

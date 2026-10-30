import Foundation

struct ParsedRecipe {
    var name: String
    var servings: Int?
    var cookTimeMinutes: Int?
    var stepsIntro: String?
    var steps: [String]
    var ingredients: [ParsedIngredient]
}

enum LLMRecipeParser {
    private static let importURLSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        let timeout = ImportAPIConfig.aiProviderTimeoutSeconds
        configuration.timeoutIntervalForRequest = timeout
        configuration.timeoutIntervalForResource = timeout
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
            var rawName: String
            var quantity: Double?
            var unit: String?
        }

        var name: String
        var servings: Int?
        var cookTimeMinutes: Int?
        var stepsIntro: String?
        var steps: [String]?
        var ingredients: [IngredientJSON]?
    }

    static func parse(
        caption: String,
        transcript: String,
        postTitleHint: String? = nil
    ) async throws -> ParsedRecipe {
        guard !ImportAPIConfig.aiProviderApiKey.isEmpty,
              ImportAPIConfig.aiProviderApiKey != "YOUR_AI_PROVIDER_API_KEY" else {
            throw RecipeImportError.apiUnauthorized
        }

        let languageCode = L10n.currentLanguageCode.hasPrefix("ru") ? "ru" : "en"
        let body = makeRequestBody(
            systemPrompt: systemPrompt(languageCode: languageCode),
            messages: chatMessages(
                caption: caption,
                transcript: transcript,
                postTitleHint: postTitleHint,
                languageCode: languageCode
            )
        )
        let endpoint = URL(string: "\(ImportAPIConfig.aiProviderBaseURL)/chat/completions")!

        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.timeoutInterval = ImportAPIConfig.aiProviderTimeoutSeconds
        urlRequest.setValue("Bearer \(ImportAPIConfig.aiProviderApiKey)", forHTTPHeaderField: "Authorization")
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
        guard let content = chatResponse.choices.first?.message.content?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !content.isEmpty,
              content != #"{"    ,"}"#,
              content != "{}",
              content != "null" else {
            throw RecipeImportError.parsingFailed
        }

        let decoded = try decodeRecipeJSON(from: content)
        return try finalize(decoded)
    }

    // MARK: - Prompt

    private static func systemPrompt(languageCode: String) -> String {
        let languageName = languageCode == "ru" ? "Russian" : "English"
        return """
        You are a recipe extraction engine for a meal-planning iOS app.
        Convert messy Instagram cooking posts into ONE strict JSON object.
        TARGET_LANGUAGE = \(languageName). Every user-facing string MUST be written in \(languageName), even when CAPTION/TRANSCRIPT/POST_TITLE_HINT are in another language. Translate naturally; do not leave source-language wording.
        Put the final JSON in the assistant content. Keep reasoning short. No markdown fences.

        Schema:
        {"name":string,"servings":number|null,"cookTimeMinutes":number|null,"stepsIntro":string|null,"steps":[string],"ingredients":[{"rawName":string,"quantity":number,"unit":string}]}

        Rules:
        - name: dish title 2–8 words IN \(languageName). Not a marketing hook/CTA/first emoji line. Prefer POST_TITLE_HINT or explicit dish name, then translate. Never include #hashtags or @mentions.
        - servings/cookTimeMinutes: only if explicitly stated; else null. Never infer servings from dough balls/pieces.
        - stepsIntro: null by default. Only a short tip in \(languageName) when the source has an explicit tip that is NOT a cooking step (e.g. serving suggestion). Never put the dish name, first step, or a paraphrase of steps here. No hashtags.
        - steps: chronological plain sentences IN \(languageName), no numbering/emojis/hashtags. Keep only facts from the text; translate cooking instructions fully.
        - ingredients.rawName: common grocery name IN \(languageName) only (no amount/emoji/hashtag/"for the sauce"). Prefer everyday store names (e.g. chicken breast → куриная грудка when TARGET_LANGUAGE is Russian). Merge duplicates by summing quantity.
        - ingredients.quantity: positive number. ingredients.unit: exactly one of gram, kilogram, milliliter, liter, piece, tablespoon, teaspoon.
        - Map: g/гр→gram, kg/кг→kilogram, ml/мл→milliliter, l/л→liter, tbsp/ст.л→tablespoon, tsp/ч.л/чл→teaspoon, pc/шт/clove/зубчик/bunch→piece.
        - cups/lb: 1 cup liquids≈240 milliliter; 1 cup solids≈140 gram if density unknown; 1 lb≈454 gram. Whole produce counted as piece.
        - "to taste"/"по вкусу"/"pinch"/"щепотка" → quantity 1, unit piece (teaspoon for spices if clearly a pinch).
        - Drop hashtag-only lines (#recipe #salad). Ignore CTA/ads/KBJU. Do not invent ingredients, temps, or steps missing from CAPTION/TRANSCRIPT.
        - When TARGET_LANGUAGE is Russian, convert °F to °C in steps. When English, keep or convert to °F only if the source used °F.
        - Do not map to catalog ids. Unknown scalars must be null.
        """
    }

    private static func chatMessages(
        caption: String,
        transcript: String,
        postTitleHint: String?,
        languageCode: String
    ) -> [[String: String]] {
        [
            [
                "role": "user",
                "content": userContent(
                    caption: caption,
                    transcript: transcript,
                    postTitleHint: postTitleHint,
                    languageCode: languageCode
                ),
            ]
        ]
    }

    private static func userContent(
        caption: String,
        transcript: String,
        postTitleHint: String?,
        languageCode: String
    ) -> String {
        let languageName = languageCode == "ru" ? "Russian" : "English"
        var parts: [String] = []
        parts.append("OUTPUT_LANGUAGE: \(languageName)\nTranslate name, stepsIntro, steps, and every ingredients.rawName into \(languageName).")
        if let postTitleHint,
           !postTitleHint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            parts.append("POST_TITLE_HINT:\n\(postTitleHint)")
        }
        parts.append("CAPTION:\n\(caption)")
        let trimmedTranscript = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTranscript.isEmpty {
            parts.append("TRANSCRIPT:\n\(trimmedTranscript)")
        } else {
            parts.append("TRANSCRIPT:\n(empty)")
        }
        parts.append("Return the JSON object now.")
        return parts.joined(separator: "\n\n")
    }

    // MARK: - Finalize

    private static func finalize(_ decoded: RecipeJSON) throws -> ParsedRecipe {
        let name = cleanDisplayName(decoded.name)
        guard !name.isEmpty else {
            throw RecipeImportError.parsingFailed
        }

        let ingredients = (decoded.ingredients ?? []).compactMap { item -> ParsedIngredient? in
            let rawName = cleanIngredientName(item.rawName)
            guard !rawName.isEmpty else { return nil }
            let quantity = item.quantity ?? 1
            let unit = UnitNormalizer.normalize(item.unit ?? "piece")
            return ParsedIngredient(
                catalogKey: nil,
                rawName: rawName,
                quantity: quantity > 0 ? quantity : 1,
                unit: unit.rawValue
            )
        }

        let cleanedSteps = (decoded.steps ?? [])
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .map(stripLeadingStepMarker)
            .map(stripHashtagsAndMentions)
            .map(stripEmojis)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { !isHashtagOnlyLine($0) }

        let intro = decoded.stepsIntro
            .map(cleanDisplayName)
            .flatMap(\.nilIfEmpty)
            .flatMap { candidate -> String? in
                let normalized = candidate.lowercased()
                if normalized == name.lowercased() { return nil }
                if let first = cleanedSteps.first, normalized == first.lowercased() { return nil }
                return candidate
            }

        let cookTime = decoded.cookTimeMinutes.map { max($0, 0) }
        let servings = decoded.servings.map { max($0, 1) }

        return ParsedRecipe(
            name: name,
            servings: servings,
            cookTimeMinutes: cookTime,
            stepsIntro: intro,
            steps: cleanedSteps,
            ingredients: ingredients
        )
    }

    private static func cleanDisplayName(_ text: String) -> String {
        var result = text.trimmingCharacters(in: .whitespacesAndNewlines)
        result = stripHashtagsAndMentions(result)
        result = stripEmojis(result)
        result = result
            .replacingOccurrences(of: #"\s{2,}"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return result
    }

    private static func cleanIngredientName(_ text: String) -> String {
        var result = text.trimmingCharacters(in: .whitespacesAndNewlines)
        result = stripHashtagsAndMentions(result)
        result = stripEmojis(result)
        result = result.replacingOccurrences(
            of: #"(?i)^(для\s+соуса|соус|заправка)\s*[:\-]?\s*"#,
            with: "",
            options: .regularExpression
        )
        return result
            .replacingOccurrences(of: #"\s{2,}"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func stripHashtagsAndMentions(_ text: String) -> String {
        text
            .replacingOccurrences(
                of: #"#[\p{L}\p{N}_]+"#,
                with: "",
                options: .regularExpression
            )
            .replacingOccurrences(
                of: #"@[\p{L}\p{N._]+"#,
                with: "",
                options: .regularExpression
            )
    }

    private static func isHashtagOnlyLine(_ text: String) -> Bool {
        let stripped = stripHashtagsAndMentions(text)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return stripped.isEmpty
    }

    private static func stripLeadingStepMarker(_ text: String) -> String {
        var result = text
        let patterns = [
            #"^\d+[\.\)\:\-]\s*"#,
            #"^[•\-–—]\s*"#,
            #"^(шаг|step)\s*\d+[\.\)\:\-]?\s*"#,
        ]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(result.startIndex..<result.endIndex, in: result)
                result = regex.stringByReplacingMatches(in: result, range: range, withTemplate: "")
            }
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func stripEmojis(_ text: String) -> String {
        let filtered = String(text.unicodeScalars.filter { scalar in
            if scalar.properties.isEmojiPresentation { return false }
            if scalar.properties.isEmojiModifier || scalar.properties.isEmojiModifierBase { return false }
            if scalar.properties.isJoinControl { return false }
            if scalar.properties.isEmoji && scalar.value >= 0x1F300 { return false }
            return true
        })
        return filtered
            .replacingOccurrences(of: #"\s{2,}"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Networking helpers

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

    private static func makeRequestBody(
        systemPrompt: String,
        messages: [[String: String]]
    ) -> [String: Any] {
        var allMessages: [[String: String]] = [
            ["role": "system", "content": systemPrompt]
        ]
        allMessages.append(contentsOf: messages)

        let model = ImportAPIConfig.aiProviderModel
        var body: [String: Any] = [
            "model": model,
            "messages": allMessages,
            "temperature": ImportAPIConfig.aiProviderTemperature,
            "top_p": ImportAPIConfig.aiProviderTopP,
            "max_tokens": ImportAPIConfig.aiProviderMaxTokens,
            "stream": false,
        ]
        if ImportAPIConfig.aiProviderThinkingEnabled {
            body["chat_template_kwargs"] = ["thinking": true]
        } else {
            body["reasoning"] = ["enabled": false]
        }
        if !model.lowercased().contains("gpt-oss") {
            body["response_format"] = ["type": "json_object"]
        }
        return body
    }
}

private extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

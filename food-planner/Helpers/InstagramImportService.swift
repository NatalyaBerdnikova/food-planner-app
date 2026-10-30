import Foundation
import SwiftData

enum InstagramImportService {
    @MainActor
    static func importRecipe(
        from urlString: String,
        in context: ModelContext,
        onStage: ((ImportStage) -> Void)? = nil
    ) async throws -> ImportedRecipeDraft {
        let normalizedURL = normalizeInstagramURL(urlString)
        guard isInstagramURL(normalizedURL) else {
            throw RecipeImportError.instagramUnavailable
        }

        onStage?(.fetchingPost)
        let postInfo: InstagramPostInfo
        do {
            postInfo = try await ScrapeCreatorsClient.fetchPostInfo(url: normalizedURL)
        } catch let error as RecipeImportError {
            throw error
        } catch {
            throw RecipeImportError.networkFailure
        }

        let transcript: String
        if ImportAPIConfig.fetchInstagramTranscript {
            onStage?(.readingContent)
            transcript = await ScrapeCreatorsClient.fetchTranscriptIfAvailable(url: normalizedURL)
        } else {
            transcript = ""
        }

        guard !postInfo.caption.isEmpty || !transcript.isEmpty else {
            throw RecipeImportError.invalidFormat
        }

        onStage?(.parsingRecipe)
        let parsed = try await resolveParsedRecipe(
            caption: postInfo.caption,
            transcript: transcript,
            postTitleHint: postInfo.titleHint
        )

        onStage?(.matchingIngredients)
        await FoodCatalogSeeder.seedIfNeeded(in: context)
        let matchResult = IngredientCatalogMatcher.match(parsed.ingredients, in: context)

        var imageData: Data?
        if let thumbnailURL = postInfo.thumbnailURL {
            imageData = await downloadImage(from: thumbnailURL)
        }
        if imageData == nil, let pageURL = URL(string: normalizedURL) {
            imageData = await LinkMetadataFetcher.thumbnailData(for: pageURL)
        }

        let attributedSteps = RecipeStepsStorage.attributedRecipeDocument(
            intro: parsed.stepsIntro,
            steps: parsed.steps
        )

        let sourceDescription = postInfo.caption
            .trimmingCharacters(in: .whitespacesAndNewlines)

        onStage?(.ready)
        return ImportedRecipeDraft(
            name: parsed.name,
            sourceURL: normalizedURL,
            sourceDescription: sourceDescription.isEmpty ? nil : sourceDescription,
            servings: parsed.servings,
            cookTimeMinutes: parsed.cookTimeMinutes,
            steps: parsed.steps,
            stepsIntro: parsed.stepsIntro,
            stepsRichTextData: RecipeStepsStorage.rtfData(from: attributedSteps),
            imageData: imageData,
            ingredients: matchResult.resolved,
            unresolvedIngredients: matchResult.unresolved
        )
    }

    private static func resolveParsedRecipe(
        caption: String,
        transcript: String,
        postTitleHint: String?
    ) async throws -> ParsedRecipe {
        do {
            return try await LLMRecipeParser.parse(
                caption: caption,
                transcript: transcript,
                postTitleHint: postTitleHint
            )
        } catch let error as RecipeImportError {
            if let fallback = CaptionFallbackParser.parse(caption: caption, transcript: transcript) {
                return fallback
            }
            throw error
        } catch {
            if let fallback = CaptionFallbackParser.parse(caption: caption, transcript: transcript) {
                return fallback
            }
            throw RecipeImportError.parsingFailed
        }
    }

    private static func normalizeInstagramURL(_ urlString: String) -> String {
        ScrapeCreatorsClient.normalizeInstagramURL(urlString)
    }

    private static func isInstagramURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString),
              let host = url.host?.lowercased() else {
            return false
        }
        return host.contains("instagram.com")
    }

    private static func downloadImage(from url: URL) async -> Data? {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode) else {
                return nil
            }
            return data
        } catch {
            return nil
        }
    }
}

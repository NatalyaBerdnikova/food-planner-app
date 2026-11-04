//
//  food_plannerTests.swift
//  food-plannerTests
//
//  Created by Наталья Бердникова on 15.05.2026.
//

import Foundation
import Testing
@testable import food_planner

private final class MockCatalogHTTPClient: RemoteCatalogHTTPClient, @unchecked Sendable {
    typealias Handler = (URLRequest) throws -> (Data, HTTPURLResponse)

    private let handler: Handler
    private(set) var recordedRequests: [URLRequest] = []

    init(handler: @escaping Handler) {
        self.handler = handler
    }

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        recordedRequests.append(request)
        return try handler(request)
    }

    static func response(
        url: URL,
        statusCode: Int,
        headers: [String: String] = [:]
    ) -> HTTPURLResponse {
        HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: headers
        )!
    }
}

struct food_plannerTests {

    private func makeTempDirectory() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("FoodPlannerTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func makeIsolatedUserDefaults() -> UserDefaults {
        let suiteName = "com.mikhail-chugaev.food-planner.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    // MARK: - 1. BackendAPIConfig

    @Test func backendConfigEndpoints() {
        let base = "https://food-planner.web-dev.su/"
        #expect(
            BackendAPIConfig.endpointURL(
                path: BackendAPIConfig.Path.catalogManifest,
                baseURLString: base
            ).absoluteString == "https://food-planner.web-dev.su/catalog/manifest.json"
        )
        #expect(
            BackendAPIConfig.endpointURL(
                path: BackendAPIConfig.Path.catalogRecipes,
                baseURLString: base
            ).absoluteString == "https://food-planner.web-dev.su/catalog/recipes.json"
        )
        #expect(
            BackendAPIConfig.endpointURL(
                path: BackendAPIConfig.Path.catalogFoods,
                baseURLString: base
            ).absoluteString == "https://food-planner.web-dev.su/catalog/foods.json"
        )
        #expect(
            BackendAPIConfig.endpointURL(
                path: BackendAPIConfig.Path.unmatchedIngredients,
                baseURLString: base
            ).absoluteString == "https://food-planner.web-dev.su/api/ingredients/unmatched"
        )
    }

    // MARK: - 2. Manifest / Catalog Decoding & SHA256 Check

    @Test func manifestDecodingAndHashVerification() throws {
        let foodsJSON = """
        {
          "version": 1,
          "products": [
            {
              "catalogKey": "apple",
              "displayName": "Яблоко",
              "category": "fruits",
              "defaultPieceWeightGrams": 180,
              "caloriesPer100g": 52,
              "proteinPer100g": 0.3,
              "fatPer100g": 0.2,
              "carbsPer100g": 14,
              "translations": { "ru": "Яблоко", "en": "Apple" }
            }
          ]
        }
        """.data(using: .utf8)!

        let recipesJSON = """
        {
          "version": 2,
          "recipes": [
            {
              "id": "recipe_01",
              "servings": 1,
              "cookTimeMinutes": 10,
              "mealTypes": ["breakfast"],
              "translations": {
                "ru": { "name": "Яблочный перекус", "steps": "Нарезать яблоко." },
                "en": { "name": "Apple snack", "steps": "Slice the apple." }
              },
              "ingredients": [
                { "catalogKey": "apple", "quantity": 180, "unit": "gram" }
              ]
            }
          ]
        }
        """.data(using: .utf8)!

        let foodsHash = RemoteCatalogSyncService.sha256Hex(of: foodsJSON)
        let recipesHash = RemoteCatalogSyncService.sha256Hex(of: recipesJSON)

        let manifestData = """
        {
          "version": "2.1.ab12cd34ef56gh78",
          "generatedAt": "2026-11-04T12:00:00Z",
          "sourceRepository": "m-chugaev/food-planner-site",
          "sourceBranch": "main",
          "catalogs": {
            "recipes": {
              "url": "/catalog/recipes.json",
              "schemaVersion": 2,
              "itemCount": 176,
              "sha256": "\(recipesHash)",
              "sizeBytes": \(recipesJSON.count)
            },
            "foods": {
              "url": "/catalog/foods.json",
              "schemaVersion": 1,
              "itemCount": 564,
              "sha256": "\(foodsHash)",
              "sizeBytes": \(foodsJSON.count)
            }
          }
        }
        """.data(using: .utf8)!

        let manifest = try JSONDecoder().decode(RemoteCatalogManifest.self, from: manifestData)
        #expect(manifest.version == "2.1.ab12cd34ef56gh78")
        #expect(manifest.generatedAt == "2026-11-04T12:00:00Z")
        #expect(manifest.sourceRepository == "m-chugaev/food-planner-site")
        #expect(manifest.sourceBranch == "main")
        #expect(manifest.recipes.url == "/catalog/recipes.json")
        #expect(manifest.recipes.schemaVersion == 2)
        #expect(manifest.recipes.itemCount == 176)
        #expect(manifest.recipes.sha256 == recipesHash)
        #expect(manifest.recipes.sizeBytes == recipesJSON.count)
        #expect(manifest.foods.url == "/catalog/foods.json")
        #expect(manifest.foods.schemaVersion == 1)
        #expect(manifest.foods.itemCount == 564)
        #expect(manifest.foods.sha256 == foodsHash)
        #expect(manifest.foods.sizeBytes == foodsJSON.count)

        try RemoteCatalogSyncService.verifySHA256(
            data: foodsJSON,
            expectedHex: manifest.foods.sha256,
            resource: "foods"
        )
        try RemoteCatalogSyncService.verifySHA256(
            data: recipesJSON,
            expectedHex: manifest.recipes.sha256,
            resource: "recipes"
        )
        #expect(FoodCatalogSeeder.isValidCatalogData(foodsJSON))
        #expect(RecipeCatalogStore.isValidCatalogData(recipesJSON))

        #expect(throws: RemoteCatalogError.self) {
            try RemoteCatalogSyncService.verifySHA256(
                data: foodsJSON,
                expectedHex: "0000000000000000000000000000000000000000000000000000000000000000",
                resource: "foods"
            )
        }
    }

    // MARK: - 3. Remote Catalog Caching, ETag & Fallback Behaviour

    @Test func remoteCatalogCachingAndETagFlow() async throws {
        let cacheDir = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: cacheDir) }
        let defaults = makeIsolatedUserDefaults()

        let foodsData = """
        {"version":1,"products":[{"catalogKey":"banana","caloriesPer100g":89,"proteinPer100g":1.1,"fatPer100g":0.3,"carbsPer100g":23}]}
        """.data(using: .utf8)!
        let recipesData = """
        {"version":2,"recipes":[{"id":"recipe_01","translations":{"ru":{"name":"Банан","steps":"Съесть"},"en":{"name":"Banana","steps":"Eat"}}}]}
        """.data(using: .utf8)!

        let foodsHash = RemoteCatalogSyncService.sha256Hex(of: foodsData)
        let recipesHash = RemoteCatalogSyncService.sha256Hex(of: recipesData)
        let manifestData = """
        {"version":"2.1.ab12cd34ef56gh78","generatedAt":"2026-11-04T12:00:00Z","catalogs":{"recipes":{"url":"/catalog/recipes.json","schemaVersion":2,"itemCount":1,"sha256":"\(recipesHash)","sizeBytes":\(recipesData.count)},"foods":{"url":"/catalog/foods.json","schemaVersion":1,"itemCount":1,"sha256":"\(foodsHash)","sizeBytes":\(foodsData.count)}}}
        """.data(using: .utf8)!
        let manifestETag = "\"\(RemoteCatalogSyncService.sha256Hex(of: manifestData))\""

        let client1 = MockCatalogHTTPClient { request in
            let url = request.url!
            switch url.path {
            case BackendAPIConfig.Path.catalogManifest:
                return (
                    manifestData,
                    MockCatalogHTTPClient.response(
                        url: url,
                        statusCode: 200,
                        headers: ["ETag": manifestETag]
                    )
                )
            case BackendAPIConfig.Path.catalogFoods:
                return (foodsData, MockCatalogHTTPClient.response(url: url, statusCode: 200))
            case BackendAPIConfig.Path.catalogRecipes:
                return (recipesData, MockCatalogHTTPClient.response(url: url, statusCode: 200))
            default:
                return (Data(), MockCatalogHTTPClient.response(url: url, statusCode: 404))
            }
        }

        let outcome1 = try await RemoteCatalogSyncService.fetchAndCacheCatalogIfNeeded(
            baseURLString: "https://food-planner.web-dev.su",
            httpClient: client1,
            cacheDirectory: cacheDir,
            userDefaults: defaults,
            now: Date(timeIntervalSince1970: 1_000_000)
        )
        #expect(outcome1 == .updated(recipesUpdated: true, foodsUpdated: true))
        #expect(RemoteCatalogSyncService.cachedFoodsData(in: cacheDir) == foodsData)
        #expect(RemoteCatalogSyncService.cachedRecipesData(in: cacheDir) == recipesData)

        let client2 = MockCatalogHTTPClient { request in
            #expect(request.value(forHTTPHeaderField: "If-None-Match") == manifestETag)
            return (Data(), MockCatalogHTTPClient.response(url: request.url!, statusCode: 304))
        }

        let outcome2 = try await RemoteCatalogSyncService.fetchAndCacheCatalogIfNeeded(
            baseURLString: "https://food-planner.web-dev.su",
            httpClient: client2,
            cacheDirectory: cacheDir,
            userDefaults: defaults,
            now: Date(timeIntervalSince1970: 1_030_000)
        )
        #expect(outcome2 == .notModified)
        #expect(client2.recordedRequests.count == 1)
    }

    @Test func fallbackToBundledCatalogWhenCacheEmptyOrCorrupted() throws {
        let cacheDir = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: cacheDir) }

        #expect(RemoteCatalogSyncService.cachedFoodsData(in: cacheDir) == nil)
        #expect(RemoteCatalogSyncService.cachedRecipesData(in: cacheDir) == nil)

        let activeFoods = RemoteCatalogSyncService.activeFoodsCatalogData(in: cacheDir)
        let activeRecipes = RemoteCatalogSyncService.activeRecipesCatalogData(in: cacheDir)
        #expect(activeFoods != nil)
        #expect(activeRecipes != nil)

        let corruptedFoodsURL = cacheDir.appendingPathComponent("foods.json")
        try Data("not-valid-json".utf8).write(to: corruptedFoodsURL)
        #expect(RemoteCatalogSyncService.cachedFoodsData(in: cacheDir) == nil)
        #expect(RemoteCatalogSyncService.activeFoodsCatalogData(in: cacheDir) != nil)
    }

    @Test func rejectRemoteCatalogOnHashMismatchWithoutWipingExistingCache() async throws {
        let cacheDir = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: cacheDir) }
        let defaults = makeIsolatedUserDefaults()

        let tamperedFoods = """
        {"version":1,"products":[{"catalogKey":"apple","caloriesPer100g":52,"proteinPer100g":0.3,"fatPer100g":0.2,"carbsPer100g":14}]}
        """.data(using: .utf8)!
        let manifestData = """
        {"version":"2.1.ab12cd34ef56gh78","catalogs":{"recipes":{"url":"/catalog/recipes.json","sha256":"aaaa"},"foods":{"url":"/catalog/foods.json","sha256":"bbbb"}}}
        """.data(using: .utf8)!

        let client = MockCatalogHTTPClient { request in
            let url = request.url!
            if url.path == BackendAPIConfig.Path.catalogManifest {
                return (manifestData, MockCatalogHTTPClient.response(url: url, statusCode: 200))
            }
            return (tamperedFoods, MockCatalogHTTPClient.response(url: url, statusCode: 200))
        }

        await #expect(throws: RemoteCatalogError.self) {
            _ = try await RemoteCatalogSyncService.fetchAndCacheCatalogIfNeeded(
                baseURLString: "https://food-planner.web-dev.su",
                httpClient: client,
                cacheDirectory: cacheDir,
                userDefaults: defaults
            )
        }

        #expect(RemoteCatalogSyncService.cachedFoodsData(in: cacheDir) == nil)
        #expect(RemoteCatalogSyncService.activeFoodsCatalogData(in: cacheDir) != nil)
    }

    // MARK: - 4. HMAC-SHA256 Signing & Unmatched Ingredient Payload Builder

    @Test func hmacSigningMatchesServerAlgorithm() throws {
        let secret = "test_ingest_secret_123"
        let timestampSeconds = 1_762_272_000
        let rawBody = Data(
            #"{"appVersion":"1.0","ingredients":[{"amount":150,"language":"ru","name":"Паста мисо","sourceRecipeUrl":"https://www.instagram.com/reel/ABC123/","unit":"gram"}],"sourceRecipeUrl":"https://www.instagram.com/reel/ABC123/"}"#
                .utf8
        )

        let headers = UnmatchedIngredientHMACSigner.signedHeaders(
            secret: secret,
            timestampSeconds: timestampSeconds,
            rawBody: rawBody
        )

        #expect(headers["X-FoodPlanner-Timestamp"] == "1762272000")
        #expect(
            headers["X-FoodPlanner-Signature"]
                == "sha256=7d6873fd48af784be618721f769956018b11c7f5b7f281063ce51702eac2d0a6"
        )
    }

    @Test func unmatchedPayloadBuilderAndRetryQueue() async throws {
        let unresolved = [
            UnresolvedIngredient(
                rawName: "  Паста мисо  ",
                suggestedQuantity: 150,
                suggestedUnit: .gram
            ),
            UnresolvedIngredient(
                rawName: "   ",
                suggestedQuantity: 10,
                suggestedUnit: .gram
            ),
            UnresolvedIngredient(
                rawName: "Соус терияки",
                suggestedQuantity: 200_000,
                suggestedUnit: .tablespoon
            ),
        ]

        let payload = UnmatchedIngredientPayloadBuilder.buildPayload(
            from: unresolved,
            sourceRecipeUrl: " https://www.instagram.com/reel/ABC123/ ",
            languageCode: "ru-RU",
            appVersion: "1.0"
        )

        let unwrapped = try #require(payload)
        #expect(unwrapped.appVersion == "1.0")
        #expect(unwrapped.sourceRecipeUrl == "https://www.instagram.com/reel/ABC123/")
        #expect(unwrapped.ingredients.count == 2)
        #expect(
            unwrapped.ingredients[0]
                == UnmatchedIngredientReportItem(
                    name: "Паста мисо",
                    amount: 150,
                    unit: "gram",
                    language: "ru",
                    sourceRecipeUrl: "https://www.instagram.com/reel/ABC123/"
                )
        )
        #expect(
            unwrapped.ingredients[1]
                == UnmatchedIngredientReportItem(
                    name: "Соус терияки",
                    amount: 100_000,
                    unit: "tablespoon",
                    language: "ru",
                    sourceRecipeUrl: "https://www.instagram.com/reel/ABC123/"
                )
        )

        let emptyPayload = UnmatchedIngredientPayloadBuilder.buildPayload(
            from: [],
            sourceRecipeUrl: "https://www.instagram.com/reel/ABC123/",
            languageCode: "en",
            appVersion: "1.0"
        )
        #expect(emptyPayload == nil)

        let tempDir = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        let queueURL = tempDir.appendingPathComponent("queue.json")
        let endpoint = URL(string: "https://food-planner.web-dev.su/api/ingredients/unmatched")!

        let failingClient = MockCatalogHTTPClient { request in
            (Data(), MockCatalogHTTPClient.response(url: request.url!, statusCode: 503))
        }

        await UnmatchedIngredientReporter.enqueueAndFlush(
            payload: unwrapped,
            queueFileURL: queueURL,
            endpointURL: endpoint,
            secret: "test_ingest_secret_123",
            httpClient: failingClient,
            now: Date(timeIntervalSince1970: 1_762_272_000)
        )

        let queuedAfterFailure = UnmatchedIngredientReporter.loadQueue(from: queueURL)
        #expect(queuedAfterFailure.count == 1)
        #expect(queuedAfterFailure.first?.attemptCount == 1)

        let rateLimitedClient = MockCatalogHTTPClient { request in
            (
                Data(),
                MockCatalogHTTPClient.response(
                    url: request.url!,
                    statusCode: 429,
                    headers: ["Retry-After": "120"]
                )
            )
        }

        let flushedDuringRateLimit = await UnmatchedIngredientReporter.flushQueue(
            queueFileURL: queueURL,
            endpointURL: endpoint,
            secret: "test_ingest_secret_123",
            httpClient: rateLimitedClient,
            now: Date(timeIntervalSince1970: 1_762_272_010)
        )
        #expect(flushedDuringRateLimit == 0)
        let queuedAfter429 = UnmatchedIngredientReporter.loadQueue(from: queueURL)
        #expect(queuedAfter429.first?.nextRetryAt == Date(timeIntervalSince1970: 1_762_272_130))

        let earlyClient = MockCatalogHTTPClient { request in
            (Data(), MockCatalogHTTPClient.response(url: request.url!, statusCode: 200))
        }
        let flushedTooEarly = await UnmatchedIngredientReporter.flushQueue(
            queueFileURL: queueURL,
            endpointURL: endpoint,
            secret: "test_ingest_secret_123",
            httpClient: earlyClient,
            now: Date(timeIntervalSince1970: 1_762_272_050)
        )
        #expect(flushedTooEarly == 0)
        #expect(earlyClient.recordedRequests.isEmpty)

        let succeedingClient = MockCatalogHTTPClient { request in
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "X-FoodPlanner-Timestamp") == "1762272140")
            let sig = request.value(forHTTPHeaderField: "X-FoodPlanner-Signature") ?? ""
            #expect(sig.hasPrefix("sha256="))
            #expect(sig.count == "sha256=".count + 64)
            return (Data(#"{"ok":true}"#.utf8), MockCatalogHTTPClient.response(url: request.url!, statusCode: 200))
        }

        let flushedCount = await UnmatchedIngredientReporter.flushQueue(
            queueFileURL: queueURL,
            endpointURL: endpoint,
            secret: "test_ingest_secret_123",
            httpClient: succeedingClient,
            now: Date(timeIntervalSince1970: 1_762_272_140)
        )
        #expect(flushedCount == 1)
        #expect(UnmatchedIngredientReporter.loadQueue(from: queueURL).isEmpty)

        for nonRetryStatus in [400, 422, 401] {
            let client = MockCatalogHTTPClient { request in
                (Data(), MockCatalogHTTPClient.response(url: request.url!, statusCode: nonRetryStatus))
            }
            await UnmatchedIngredientReporter.enqueueAndFlush(
                payload: unwrapped,
                queueFileURL: queueURL,
                endpointURL: endpoint,
                secret: "test_ingest_secret_123",
                httpClient: client,
                now: Date(timeIntervalSince1970: 1_762_272_200)
            )
            #expect(UnmatchedIngredientReporter.loadQueue(from: queueURL).isEmpty)
        }
    }
}

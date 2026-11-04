import CryptoKit
import Foundation
import SwiftData

protocol RemoteCatalogHTTPClient: Sendable {
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

struct URLSessionCatalogHTTPClient: RemoteCatalogHTTPClient {
    let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw RemoteCatalogError.invalidResponse
        }
        return (data, http)
    }
}

enum RemoteCatalogError: Error, Equatable {
    case invalidResponse
    case unexpectedStatusCode(Int)
    case invalidManifest
    case hashMismatch(resource: String, expected: String, actual: String)
    case invalidCatalogPayload(resource: String)
}

struct RemoteCatalogManifest: Codable, Equatable, Sendable {
    struct ResourceDescriptor: Codable, Equatable, Sendable {
        var url: String?
        var schemaVersion: Int?
        var itemCount: Int?
        var sha256: String
        var sizeBytes: Int?

        var path: String? { url }
        var count: Int? { itemCount }

        private enum CodingKeys: String, CodingKey {
            case url
            case path
            case schemaVersion
            case version
            case itemCount
            case count
            case sha256
            case hash
            case sizeBytes
        }

        init(
            url: String? = nil,
            schemaVersion: Int? = nil,
            itemCount: Int? = nil,
            sha256: String,
            sizeBytes: Int? = nil
        ) {
            self.url = url
            self.schemaVersion = schemaVersion
            self.itemCount = itemCount
            self.sha256 = Self.normalizeHash(sha256)
            self.sizeBytes = sizeBytes
        }

        init(from decoder: Decoder) throws {
            if let singleValue = try? decoder.singleValueContainer(),
               let rawHash = try? singleValue.decode(String.self) {
                let cleaned = Self.normalizeHash(rawHash)
                guard !cleaned.isEmpty else {
                    throw DecodingError.dataCorruptedError(
                        in: singleValue,
                        debugDescription: "Empty SHA256 hash"
                    )
                }
                self.url = nil
                self.schemaVersion = nil
                self.itemCount = nil
                self.sha256 = cleaned
                self.sizeBytes = nil
                return
            }

            let container = try decoder.container(keyedBy: CodingKeys.self)
            let rawHash = (try? container.decode(String.self, forKey: .sha256))
                ?? (try? container.decode(String.self, forKey: .hash))
                ?? ""
            let cleaned = Self.normalizeHash(rawHash)
            guard !cleaned.isEmpty else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "Missing sha256 in resource descriptor"
                    )
                )
            }
            self.sha256 = cleaned
            self.url = (try? container.decode(String.self, forKey: .url))
                ?? (try? container.decode(String.self, forKey: .path))
            self.schemaVersion = Self.decodeIntOrString(from: container, key: .schemaVersion)
                ?? Self.decodeIntOrString(from: container, key: .version)
            self.itemCount = (try? container.decode(Int.self, forKey: .itemCount))
                ?? (try? container.decode(Int.self, forKey: .count))
            self.sizeBytes = try? container.decode(Int.self, forKey: .sizeBytes)
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encodeIfPresent(url, forKey: .url)
            try container.encodeIfPresent(schemaVersion, forKey: .schemaVersion)
            try container.encodeIfPresent(itemCount, forKey: .itemCount)
            try container.encode(sha256, forKey: .sha256)
            try container.encodeIfPresent(sizeBytes, forKey: .sizeBytes)
        }

        static func normalizeHash(_ value: String) -> String {
            var trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if trimmed.hasPrefix("sha256:") {
                trimmed = String(trimmed.dropFirst("sha256:".count))
            } else if trimmed.hasPrefix("sha256-") {
                trimmed = String(trimmed.dropFirst("sha256-".count))
            }
            return trimmed.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        private static func decodeIntOrString<K: CodingKey>(
            from container: KeyedDecodingContainer<K>,
            key: K
        ) -> Int? {
            if let intVal = try? container.decode(Int.self, forKey: key) {
                return intVal
            }
            if let strVal = try? container.decode(String.self, forKey: key),
               let parsed = Int(strVal.trimmingCharacters(in: .whitespacesAndNewlines)) {
                return parsed
            }
            return nil
        }
    }

    struct CatalogsContainer: Codable, Equatable, Sendable {
        var recipes: ResourceDescriptor
        var foods: ResourceDescriptor
    }

    var version: String
    var generatedAt: String?
    var sourceRepository: String?
    var sourceBranch: String?
    var recipes: ResourceDescriptor
    var foods: ResourceDescriptor

    var catalogs: CatalogsContainer {
        CatalogsContainer(recipes: recipes, foods: foods)
    }

    private enum CodingKeys: String, CodingKey {
        case version
        case catalogVersion
        case generatedAt
        case updatedAt
        case sourceRepository
        case sourceBranch
        case catalogs
        case files
        case recipes
        case foods
        case recipesSha256
        case foodsSha256
        case recipesHash
        case foodsHash
    }

    private enum NestedCatalogsCodingKeys: String, CodingKey {
        case recipes
        case foods
        case recipesCatalog = "recipes.json"
        case foodsCatalog = "foods.json"
    }

    init(
        version: String,
        generatedAt: String? = nil,
        sourceRepository: String? = nil,
        sourceBranch: String? = nil,
        recipes: ResourceDescriptor,
        foods: ResourceDescriptor
    ) {
        self.version = version
        self.generatedAt = generatedAt
        self.sourceRepository = sourceRepository
        self.sourceBranch = sourceBranch
        self.recipes = recipes
        self.foods = foods
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let resolvedVersion: String
        if let strVersion = try? container.decode(String.self, forKey: .version),
           !strVersion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            resolvedVersion = strVersion.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if let intVersion = try? container.decode(Int.self, forKey: .version) {
            resolvedVersion = String(intVersion)
        } else if let strCatalogVersion = try? container.decode(String.self, forKey: .catalogVersion),
                  !strCatalogVersion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            resolvedVersion = strCatalogVersion.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if let intCatalogVersion = try? container.decode(Int.self, forKey: .catalogVersion) {
            resolvedVersion = String(intCatalogVersion)
        } else {
            resolvedVersion = "1"
        }

        self.version = resolvedVersion
        self.generatedAt = (try? container.decode(String.self, forKey: .generatedAt))
            ?? (try? container.decode(String.self, forKey: .updatedAt))
        self.sourceRepository = try? container.decode(String.self, forKey: .sourceRepository)
        self.sourceBranch = try? container.decode(String.self, forKey: .sourceBranch)

        var decodedRecipes: ResourceDescriptor?
        var decodedFoods: ResourceDescriptor?

        if let catalogsContainer = try? container.nestedContainer(
            keyedBy: NestedCatalogsCodingKeys.self,
            forKey: .catalogs
        ) {
            decodedRecipes = (try? catalogsContainer.decode(ResourceDescriptor.self, forKey: .recipes))
                ?? (try? catalogsContainer.decode(ResourceDescriptor.self, forKey: .recipesCatalog))
            decodedFoods = (try? catalogsContainer.decode(ResourceDescriptor.self, forKey: .foods))
                ?? (try? catalogsContainer.decode(ResourceDescriptor.self, forKey: .foodsCatalog))
        }

        if decodedRecipes == nil {
            decodedRecipes = try? container.decode(ResourceDescriptor.self, forKey: .recipes)
        }
        if decodedFoods == nil {
            decodedFoods = try? container.decode(ResourceDescriptor.self, forKey: .foods)
        }

        if (decodedRecipes == nil || decodedFoods == nil),
           let filesContainer = try? container.nestedContainer(
               keyedBy: NestedCatalogsCodingKeys.self,
               forKey: .files
           ) {
            if decodedRecipes == nil {
                decodedRecipes = (try? filesContainer.decode(ResourceDescriptor.self, forKey: .recipes))
                    ?? (try? filesContainer.decode(ResourceDescriptor.self, forKey: .recipesCatalog))
            }
            if decodedFoods == nil {
                decodedFoods = (try? filesContainer.decode(ResourceDescriptor.self, forKey: .foods))
                    ?? (try? filesContainer.decode(ResourceDescriptor.self, forKey: .foodsCatalog))
            }
        }

        if decodedRecipes == nil {
            if let hash = (try? container.decode(String.self, forKey: .recipesSha256))
                ?? (try? container.decode(String.self, forKey: .recipesHash)) {
                let normalized = ResourceDescriptor.normalizeHash(hash)
                if !normalized.isEmpty {
                    decodedRecipes = ResourceDescriptor(sha256: normalized)
                }
            }
        }

        if decodedFoods == nil {
            if let hash = (try? container.decode(String.self, forKey: .foodsSha256))
                ?? (try? container.decode(String.self, forKey: .foodsHash)) {
                let normalized = ResourceDescriptor.normalizeHash(hash)
                if !normalized.isEmpty {
                    decodedFoods = ResourceDescriptor(sha256: normalized)
                }
            }
        }

        guard let finalRecipes = decodedRecipes, let finalFoods = decodedFoods else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Manifest must contain catalogs.recipes and catalogs.foods SHA256 descriptors"
                )
            )
        }

        self.recipes = finalRecipes
        self.foods = finalFoods
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(version, forKey: .version)
        try container.encodeIfPresent(generatedAt, forKey: .generatedAt)
        try container.encodeIfPresent(sourceRepository, forKey: .sourceRepository)
        try container.encodeIfPresent(sourceBranch, forKey: .sourceBranch)
        try container.encode(CatalogsContainer(recipes: recipes, foods: foods), forKey: .catalogs)
    }
}

enum RemoteCatalogSyncService {
    private static let appSupportFolder = "food-planner"
    private static let cacheSubfolder = "RemoteCatalog"
    private static let manifestFileName = "manifest.json"
    private static let recipesFileName = "recipes.json"
    private static let foodsFileName = "foods.json"

    private static let etagDefaultsKey = "remoteCatalog.manifestETag"
    private static let lastCheckDefaultsKey = "remoteCatalog.lastCheckTimestamp"

    private actor SyncCoordinator {
        private var isRunning = false

        func beginIfIdle() -> Bool {
            guard !isRunning else { return false }
            isRunning = true
            return true
        }

        func end() {
            isRunning = false
        }
    }

    private static let coordinator = SyncCoordinator()

    enum SyncOutcome: Equatable, Sendable {
        case skippedThrottle
        case skippedAlreadyRunning
        case notModified
        case upToDate
        case updated(recipesUpdated: Bool, foodsUpdated: Bool)
        case failed
    }

    // MARK: - Background Sync Entry Point

    static func refreshInBackgroundIfNeeded(
        in context: ModelContext,
        force: Bool = false
    ) {
        Task(priority: .utility) {
            _ = await syncIfNeeded(in: context, force: force)
        }
    }

    @discardableResult
    static func syncIfNeeded(
        in context: ModelContext,
        force: Bool = false,
        httpClient: RemoteCatalogHTTPClient = URLSessionCatalogHTTPClient(),
        cacheDirectory: URL? = nil,
        userDefaults: UserDefaults = .standard,
        minimumInterval: TimeInterval = BackendAPIConfig.catalogRefreshMinimumInterval,
        now: Date = .now
    ) async -> SyncOutcome {
        guard await coordinator.beginIfIdle() else {
            return .skippedAlreadyRunning
        }
        defer {
            Task { await coordinator.end() }
        }

        let dir = cacheDirectory ?? defaultCacheDirectory()

        if !force, !shouldPerformCheck(
            userDefaults: userDefaults,
            minimumInterval: minimumInterval,
            now: now
        ) {
            return .skippedThrottle
        }

        do {
            let outcome = try await fetchAndCacheCatalogIfNeeded(
                httpClient: httpClient,
                cacheDirectory: dir,
                userDefaults: userDefaults,
                now: now
            )

            if case .updated(let recipesUpdated, let foodsUpdated) = outcome {
                await MainActor.run {
                    if foodsUpdated {
                        FoodCatalogLocalization.invalidateCache()
                        IngredientCatalogPrompt.invalidateCache()
                        FoodCatalogSeeder.syncFromActiveCatalog(in: context)
                    }
                    if recipesUpdated || foodsUpdated {
                        RecipeCatalogLocalization.invalidateCache()
                        RecipeCatalogStore.syncFromActiveCatalog(in: context)
                    }
                    LocalPersistence.save(context)
                }
            }

            return outcome
        } catch {
            return .failed
        }
    }

    // MARK: - Core Fetch & Cache Logic (Testable without SwiftData)

    static func fetchAndCacheCatalogIfNeeded(
        baseURLString: String = BackendAPIConfig.baseURLString,
        httpClient: RemoteCatalogHTTPClient,
        cacheDirectory: URL,
        userDefaults: UserDefaults = .standard,
        now: Date = .now
    ) async throws -> SyncOutcome {
        let manifestURL = BackendAPIConfig.endpointURL(
            path: BackendAPIConfig.Path.catalogManifest,
            baseURLString: baseURLString
        )

        var manifestRequest = URLRequest(url: manifestURL)
        manifestRequest.httpMethod = "GET"
        manifestRequest.cachePolicy = .reloadIgnoringLocalCacheData
        manifestRequest.timeoutInterval = 20

        let cachedManifest = loadCachedManifest(in: cacheDirectory)
        let hasValidCachedFiles = hasVerifiedCachedCatalogFiles(
            for: cachedManifest,
            in: cacheDirectory
        )

        if hasValidCachedFiles,
           let storedETag = userDefaults.string(forKey: etagDefaultsKey),
           !storedETag.isEmpty {
            manifestRequest.setValue(storedETag, forHTTPHeaderField: "If-None-Match")
        }

        let (manifestData, manifestResponse) = try await httpClient.data(for: manifestRequest)

        if manifestResponse.statusCode == 304 {
            userDefaults.set(now.timeIntervalSince1970, forKey: lastCheckDefaultsKey)
            return .notModified
        }

        guard (200...299).contains(manifestResponse.statusCode) else {
            throw RemoteCatalogError.unexpectedStatusCode(manifestResponse.statusCode)
        }

        let remoteManifest: RemoteCatalogManifest
        do {
            remoteManifest = try JSONDecoder().decode(RemoteCatalogManifest.self, from: manifestData)
        } catch {
            throw RemoteCatalogError.invalidManifest
        }

        let resolvedETag = headerValue(for: "ETag", in: manifestResponse)
            ?? "\"\(sha256Hex(of: manifestData))\""

        let foodsFileURL = cacheDirectory.appendingPathComponent(foodsFileName)
        let recipesFileURL = cacheDirectory.appendingPathComponent(recipesFileName)
        let manifestFileURL = cacheDirectory.appendingPathComponent(manifestFileName)

        let foodsNeedsDownload = !isCachedFileMatching(
            url: foodsFileURL,
            expectedSHA256: remoteManifest.foods.sha256
        )
        let recipesNeedsDownload = !isCachedFileMatching(
            url: recipesFileURL,
            expectedSHA256: remoteManifest.recipes.sha256
        )

        if !foodsNeedsDownload && !recipesNeedsDownload && cachedManifest == remoteManifest {
            userDefaults.set(resolvedETag, forKey: etagDefaultsKey)
            userDefaults.set(now.timeIntervalSince1970, forKey: lastCheckDefaultsKey)
            return .upToDate
        }

        var downloadedFoodsData: Data?
        if foodsNeedsDownload {
            let foodsURL = resolveResourceURL(
                urlOrPath: remoteManifest.foods.url,
                defaultPath: BackendAPIConfig.Path.catalogFoods,
                baseURLString: baseURLString
            )
            var request = URLRequest(url: foodsURL)
            request.httpMethod = "GET"
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.timeoutInterval = 30

            let (data, response) = try await httpClient.data(for: request)
            guard (200...299).contains(response.statusCode) else {
                throw RemoteCatalogError.unexpectedStatusCode(response.statusCode)
            }
            try verifySHA256(
                data: data,
                expectedHex: remoteManifest.foods.sha256,
                resource: "foods"
            )
            guard FoodCatalogSeeder.isValidCatalogData(data) else {
                throw RemoteCatalogError.invalidCatalogPayload(resource: "foods")
            }
            downloadedFoodsData = data
        }

        var downloadedRecipesData: Data?
        if recipesNeedsDownload {
            let recipesURL = resolveResourceURL(
                urlOrPath: remoteManifest.recipes.url,
                defaultPath: BackendAPIConfig.Path.catalogRecipes,
                baseURLString: baseURLString
            )
            var request = URLRequest(url: recipesURL)
            request.httpMethod = "GET"
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.timeoutInterval = 30

            let (data, response) = try await httpClient.data(for: request)
            guard (200...299).contains(response.statusCode) else {
                throw RemoteCatalogError.unexpectedStatusCode(response.statusCode)
            }
            try verifySHA256(
                data: data,
                expectedHex: remoteManifest.recipes.sha256,
                resource: "recipes"
            )
            guard RecipeCatalogStore.isValidCatalogData(data) else {
                throw RemoteCatalogError.invalidCatalogPayload(resource: "recipes")
            }
            downloadedRecipesData = data
        }

        try FileManager.default.createDirectory(
            at: cacheDirectory,
            withIntermediateDirectories: true
        )

        if let downloadedFoodsData {
            try downloadedFoodsData.write(to: foodsFileURL, options: .atomic)
        }
        if let downloadedRecipesData {
            try downloadedRecipesData.write(to: recipesFileURL, options: .atomic)
        }

        try manifestData.write(to: manifestFileURL, options: .atomic)

        userDefaults.set(resolvedETag, forKey: etagDefaultsKey)
        userDefaults.set(now.timeIntervalSince1970, forKey: lastCheckDefaultsKey)

        return .updated(
            recipesUpdated: downloadedRecipesData != nil || cachedManifest?.recipes != remoteManifest.recipes,
            foodsUpdated: downloadedFoodsData != nil || cachedManifest?.foods != remoteManifest.foods
        )
    }

    private static func resolveResourceURL(
        urlOrPath: String?,
        defaultPath: String,
        baseURLString: String
    ) -> URL {
        if let raw = urlOrPath?.trimmingCharacters(in: .whitespacesAndNewlines),
           !raw.isEmpty {
            if let absolute = URL(string: raw),
               let scheme = absolute.scheme?.lowercased(),
               scheme == "http" || scheme == "https" {
                return absolute
            }
            return BackendAPIConfig.endpointURL(path: raw, baseURLString: baseURLString)
        }
        return BackendAPIConfig.endpointURL(path: defaultPath, baseURLString: baseURLString)
    }

    // MARK: - SHA256 Verification

    static func sha256Hex(of data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    static func verifySHA256(
        data: Data,
        expectedHex: String,
        resource: String
    ) throws {
        let normalizedExpected = RemoteCatalogManifest.ResourceDescriptor.normalizeHash(expectedHex)
        let actual = sha256Hex(of: data)
        guard !normalizedExpected.isEmpty, actual == normalizedExpected else {
            throw RemoteCatalogError.hashMismatch(
                resource: resource,
                expected: normalizedExpected,
                actual: actual
            )
        }
    }

    // MARK: - Cached Data Resolution & Fallback

    static func defaultCacheDirectory() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base
            .appendingPathComponent(appSupportFolder, isDirectory: true)
            .appendingPathComponent(cacheSubfolder, isDirectory: true)
    }

    static func cachedFoodsData(in cacheDirectory: URL = defaultCacheDirectory()) -> Data? {
        let url = cacheDirectory.appendingPathComponent(foodsFileName)
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              FoodCatalogSeeder.isValidCatalogData(data) else {
            return nil
        }
        if let manifest = loadCachedManifest(in: cacheDirectory),
           (try? verifySHA256(data: data, expectedHex: manifest.foods.sha256, resource: "foods")) == nil {
            return nil
        }
        return data
    }

    static func cachedRecipesData(in cacheDirectory: URL = defaultCacheDirectory()) -> Data? {
        let url = cacheDirectory.appendingPathComponent(recipesFileName)
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              RecipeCatalogStore.isValidCatalogData(data) else {
            return nil
        }
        if let manifest = loadCachedManifest(in: cacheDirectory),
           (try? verifySHA256(data: data, expectedHex: manifest.recipes.sha256, resource: "recipes")) == nil {
            return nil
        }
        return data
    }

    static func activeFoodsCatalogData(
        in cacheDirectory: URL = defaultCacheDirectory(),
        bundle: Bundle = .main
    ) -> Data? {
        if let cached = cachedFoodsData(in: cacheDirectory) {
            return cached
        }
        guard let url = bundle.url(forResource: "food-catalog", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              FoodCatalogSeeder.isValidCatalogData(data) else {
            return nil
        }
        return data
    }

    static func activeRecipesCatalogData(
        in cacheDirectory: URL = defaultCacheDirectory(),
        bundle: Bundle = .main
    ) -> Data? {
        if let cached = cachedRecipesData(in: cacheDirectory) {
            return cached
        }
        guard let url = bundle.url(forResource: "recipes-catalog", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              RecipeCatalogStore.isValidCatalogData(data) else {
            return nil
        }
        return data
    }

    // MARK: - Throttle & Helpers

    static func shouldPerformCheck(
        userDefaults: UserDefaults = .standard,
        minimumInterval: TimeInterval = BackendAPIConfig.catalogRefreshMinimumInterval,
        now: Date = .now
    ) -> Bool {
        let lastCheck = userDefaults.double(forKey: lastCheckDefaultsKey)
        guard lastCheck > 0 else { return true }
        let elapsed = now.timeIntervalSince1970 - lastCheck
        return elapsed >= minimumInterval
    }

    static func loadCachedManifest(in cacheDirectory: URL = defaultCacheDirectory()) -> RemoteCatalogManifest? {
        let url = cacheDirectory.appendingPathComponent(manifestFileName)
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        return try? JSONDecoder().decode(RemoteCatalogManifest.self, from: data)
    }

    private static func hasVerifiedCachedCatalogFiles(
        for manifest: RemoteCatalogManifest?,
        in cacheDirectory: URL
    ) -> Bool {
        guard let manifest else { return false }
        let foodsURL = cacheDirectory.appendingPathComponent(foodsFileName)
        let recipesURL = cacheDirectory.appendingPathComponent(recipesFileName)
        return isCachedFileMatching(url: foodsURL, expectedSHA256: manifest.foods.sha256)
            && isCachedFileMatching(url: recipesURL, expectedSHA256: manifest.recipes.sha256)
    }

    private static func isCachedFileMatching(url: URL, expectedSHA256: String) -> Bool {
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url) else {
            return false
        }
        return (try? verifySHA256(data: data, expectedHex: expectedSHA256, resource: url.lastPathComponent)) != nil
    }

    private static func headerValue(for name: String, in response: HTTPURLResponse) -> String? {
        for (key, value) in response.allHeaderFields {
            if let keyStr = key as? String,
               keyStr.caseInsensitiveCompare(name) == .orderedSame,
               let valStr = value as? String {
                let trimmed = valStr.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    return trimmed
                }
            }
        }
        return nil
    }
}

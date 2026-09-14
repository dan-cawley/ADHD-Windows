import SwiftUI

enum ItemArtworkCatalog {
    @MainActor static var preferredSpriteSheetGender: SpriteSheetGender = .male
    @MainActor static var preferredArtworkStyle: ArtworkStyle = .adult
    @MainActor private static var resolvedSpriteSheetNameCache: [String: String?] = [:]
    @MainActor private static var resolvedWeeklyMonsterSheetCache: [String: String?] = [:]
    @MainActor private static var resolvedAvatarCandidatesCache: [String: [String]] = [:]
    @MainActor private static var resolvedItemAssetNameCache: [String: String?] = [:]
    @MainActor private static var bundlePathCandidatesCache: [String: [URL]] = [:]

    @MainActor
    static func spriteSheetName(for item: LootItem, allowFallback: Bool = true) -> String? {
        spriteSheetName(
            for: item,
            artStyle: preferredArtworkStyle,
            gender: preferredSpriteSheetGender,
            allowFallback: allowFallback
        )
    }

    @MainActor
    static func spriteSheetName(
        for item: LootItem,
        artStyle: ArtworkStyle,
        gender: SpriteSheetGender,
        allowFallback: Bool = true
    ) -> String? {
        let cacheKey = "\(item.id)|\(artStyle.rawValue)|\(gender.rawValue)|\(allowFallback)"
        if let cached = resolvedSpriteSheetNameCache[cacheKey] {
            return cached
        }

        let resolved: String?
        if let setName = item.spriteSheetSet {
            let preferred = spriteSheetCandidates(for: setName, gender: gender, artStyle: artStyle)
            if let match = preferred.first(where: assetExists(named:)) {
                resolved = match
            } else if allowFallback, artStyle != .adult {
                let fallbackAdult = spriteSheetCandidates(for: setName, gender: gender, artStyle: .adult)
                if let match = fallbackAdult.first(where: assetExists(named:)) {
                    resolved = match
                } else if allowFallback {
                    resolved = spriteSheetName()
                } else {
                    resolved = nil
                }
            } else if allowFallback {
                resolved = spriteSheetName()
            } else {
                resolved = nil
            }
        } else if allowFallback {
            resolved = spriteSheetName()
        } else {
            resolved = nil
        }
        resolvedSpriteSheetNameCache[cacheKey] = resolved
        return resolved
    }

    @MainActor
    static func spriteSheetName() -> String? {
        let fallbackLibrary = spriteSheetCandidates(for: "library", gender: preferredSpriteSheetGender, artStyle: preferredArtworkStyle)
        if let found = fallbackLibrary.first(where: assetExists(named:)) {
            return found
        }
        if preferredArtworkStyle != .adult {
            let adultFallback = spriteSheetCandidates(for: "library", gender: preferredSpriteSheetGender, artStyle: .adult)
            return adultFallback.first(where: assetExists(named:))
        }
        return nil
    }

    @MainActor
    static func weeklyMonsterSheetName(forWeek weekNumber: Int, artStyle: ArtworkStyle) -> String? {
        let cacheKey = "\(weekNumber)|\(artStyle.rawValue)"
        if let cached = resolvedWeeklyMonsterSheetCache[cacheKey] {
            return cached
        }
        let start = ((weekNumber - 1) / 9) * 9 + 1
        let end = start + 8
        let baseNames = [
            "Weekly_Monsters \(start)-\(end)",
            "Weekly_monsters \(start)-\(end)"
        ]
        for style in mixedWeeklyMonsterStyleOrder(forWeek: weekNumber, preferredStyle: artStyle) {
            let candidates = styledAssetCandidates(base: baseNames, style: style, includeBase: style == .adult)
            if let found = candidates.first(where: assetExists(named:)) {
                resolvedWeeklyMonsterSheetCache[cacheKey] = found
                return found
            }
        }
        resolvedWeeklyMonsterSheetCache[cacheKey] = nil
        return nil
    }

    private static func mixedWeeklyMonsterStyleOrder(forWeek weekNumber: Int, preferredStyle: ArtworkStyle) -> [ArtworkStyle] {
        switch preferredStyle {
        case .adult:
            return weekNumber.isMultiple(of: 2) ? [.storybook, .adult] : [.adult, .storybook]
        case .storybook:
            return weekNumber.isMultiple(of: 2) ? [.adult, .storybook] : [.storybook, .adult]
        case .cute:
            return weekNumber.isMultiple(of: 2) ? [.adult, .storybook] : [.storybook, .adult]
        }
    }

    @MainActor
    static func avatarCandidates(for gender: SpriteSheetGender, artStyle: ArtworkStyle) -> [String] {
        let cacheKey = "\(gender.rawValue)|\(artStyle.rawValue)"
        if let cached = resolvedAvatarCandidatesCache[cacheKey] {
            return cached
        }
        let baseCandidates: [String]
        switch gender {
        case .male:
            baseCandidates = [
                "Main_Char_M",
                "Main_Char_M.png",
                "ArtSource/Characters/Main_Char_M",
                "ArtSource/Characters/Main_Char_M.png",
                "Characters/Main_Char_M",
                "Characters/Main_Char_M.png"
            ]
        case .female:
            baseCandidates = [
                "Main_Char_F",
                "Main_Char_F.png",
                "ArtSource/Characters/Main_Char_F",
                "ArtSource/Characters/Main_Char_F.png",
                "Characters/Main_Char_F",
                "Characters/Main_Char_F.png"
            ]
        }

        var styled = styledAssetCandidates(base: baseCandidates, style: artStyle)
        styled.insert(contentsOf: styleSpecificAvatarCandidates(for: gender, style: artStyle), at: 0)
        let filtered = deduplicated(styled.filter { assetExists(named: $0) })
        if !filtered.isEmpty {
            resolvedAvatarCandidatesCache[cacheKey] = filtered
            return filtered
        }
        if artStyle != .adult {
            let fallback = deduplicated(styledAssetCandidates(base: baseCandidates, style: .adult).filter { assetExists(named: $0) })
            resolvedAvatarCandidatesCache[cacheKey] = fallback
            return fallback
        }
        resolvedAvatarCandidatesCache[cacheKey] = []
        return []
    }

    @MainActor
    static func isAvatarAssetName(_ assetName: String, compatibleWith gender: SpriteSheetGender, artStyle: ArtworkStyle) -> Bool {
        avatarCandidates(for: gender, artStyle: artStyle).contains(assetName)
    }

    private static func deduplicated(_ source: [String]) -> [String] {
        var seen: Set<String> = []
        var result: [String] = []
        for item in source where !seen.contains(item) {
            seen.insert(item)
            result.append(item)
        }
        return result
    }

    private static func spriteSheetCandidates(for setName: String, gender: SpriteSheetGender, artStyle: ArtworkStyle) -> [String] {
        let baseCandidates = baseSpriteSheetCandidates(for: setName, gender: gender)
        return styledAssetCandidates(base: baseCandidates, style: artStyle, includeBase: artStyle == .adult)
    }

    private static func baseSpriteSheetCandidates(for setName: String, gender: SpriteSheetGender) -> [String] {
        let normalized = setName.lowercased()
        switch normalized {
        case "library":
            switch gender {
            case .male:
                return [
                    "Library_SheekM",
                    "Library_SheekM.png",
                    "ArtSource/SpriteSheets/Library_SheekM.png",
                    "ArtSource/SpriteSheets/Library_SheekM",
                    "spritesheets/Library_SheekM.png",
                    "spritesheets/Library_SheekM",
                    "Library_SheekM.png"
                ]
            case .female:
                return [
                    "Library_SheekF",
                    "Library_SheekF.png",
                    "ArtSource/SpriteSheets/Library_SheekF.png",
                    "ArtSource/SpriteSheets/Library_SheekF",
                    "spritesheets/Library_SheekF.png",
                    "spritesheets/Library_SheekF",
                    "Library_SheekF.png"
                ]
            }
        case "standard":
            return [
                "Arcanist_set",
                "Arcanist_set.png",
                "ArtSource/SpriteSheets/Storybook/Storybook_Arcanist_set.png",
                "ArtSource/SpriteSheets/Storybook/Storybook_Arcanist_set",
                "Storybook_Arcanist_set",
                "Storybook_Arcanist_set.png",
                "arcanist_set",
                "arcanist_set.png"
            ]
        case "standard_clothes":
            switch gender {
            case .male:
                return [
                    "Storybook_StandardClothes_M",
                    "Storybook_StandardClothes_M.png",
                    "ArtSource/SpriteSheets/Storybook/Storybook_StandardClothes_M.png",
                    "ArtSource/SpriteSheets/Storybook/Storybook_StandardClothes_M"
                ]
            case .female:
                return [
                    "Storybook_StandardClothes_F",
                    "Storybook_StandardClothes_F.png",
                    "ArtSource/SpriteSheets/Storybook/Storybook_StandardClothes_F.png",
                    "ArtSource/SpriteSheets/Storybook/Storybook_StandardClothes_F"
                ]
            }
        case "garden_gnome":
            return [
                "Storybook_GardenGnome_set",
                "Storybook_GardenGnome_set.png",
                "ArtSource/SpriteSheets/Storybook/Storybook_GardenGnome_set.png",
                "ArtSource/SpriteSheets/Storybook/Storybook_GardenGnome_set",
                "garden_gnome_spritesheet",
                "garden_gnome_spritesheet.png"
            ]
        case "wood_elf":
            return [
                "Storybook_WoodElf_set",
                "Storybook_WoodElf_set.png",
                "ArtSource/SpriteSheets/Storybook/Storybook_WoodElf_set.png",
                "ArtSource/SpriteSheets/Storybook/Storybook_WoodElf_set",
                "wood_elf_spritesheet",
                "wood_elf_spritesheet.png"
            ]
        case "micah":
            return [
                "Storybook_Micah_set",
                "Storybook_Micah_set.png",
                "ArtSource/SpriteSheets/Storybook/Storybook_Micah_set.png",
                "ArtSource/SpriteSheets/Storybook/Storybook_Micah_set",
                "Micah_spritesheet",
                "Micah_spritesheet.png"
            ]
        case "stacy":
            return [
                "Storybook_Stacy_set",
                "Storybook_Stacy_set.png",
                "ArtSource/SpriteSheets/Storybook/Storybook_Stacy_set.png",
                "ArtSource/SpriteSheets/Storybook/Storybook_Stacy_set",
                "stacy_princess_spritesheet",
                "stacy_princess_spritesheet.png"
            ]
        case "emberforge":
            switch gender {
            case .male:
                return [
                    "Emberforg_M",
                    "Emberforg_M.png",
                    "ArtSource/SpriteSheets/Emberforg_M.png",
                    "ArtSource/SpriteSheets/Emberforg_M",
                    "spritesheets/Emberforg_M.png",
                    "spritesheets/Emberforg_M",
                    "Emberforg_M.png",
                    "Emberforg_M",
                    "ArtSource/SpriteSheets/Emberforge_M.png",
                    "ArtSource/SpriteSheets/Emberforge_M",
                    "spritesheets/Emberforge_M.png",
                    "spritesheets/Emberforge_M",
                    "Emberforge_M.png",
                    "Emberforge_M"
                ]
            case .female:
                return [
                    "Emberforge_F",
                    "Emberforge_F.png",
                    "ArtSource/SpriteSheets/Emberforge_F.png",
                    "ArtSource/SpriteSheets/Emberforge_F",
                    "spritesheets/Emberforge_F.png",
                    "spritesheets/Emberforge_F",
                    "Emberforge_F.png"
                ]
            }
        case "nightveil":
            switch gender {
            case .male:
                return [
                    "Nightveil_M",
                    "Nightveil_M.png",
                    "ArtSource/SpriteSheets/Nightveil_M.png",
                    "ArtSource/SpriteSheets/Nightveil_M",
                    "spritesheets/Nightveil_M.png",
                    "spritesheets/Nightveil_M"
                ]
            case .female:
                return [
                    "Nightveil_F",
                    "Nightveil_F.png",
                    "ArtSource/SpriteSheets/Nightveil_F.png",
                    "ArtSource/SpriteSheets/Nightveil_F",
                    "spritesheets/Nightveil_F.png",
                    "spritesheets/Nightveil_F"
                ]
            }
        default:
            return []
        }
    }

    private static func styleSpecificAvatarCandidates(for gender: SpriteSheetGender, style: ArtworkStyle) -> [String] {
        switch style {
        case .adult:
            return []
        case .cute:
            switch gender {
            case .male:
                return ["Cute_Main_Char_M", "Cute_Main_Char_M_Alt"]
            case .female:
                return ["Cute_Main_Char_F", "Cute_Main_Char_F_Alt"]
            }
        case .storybook:
            switch gender {
            case .male:
                return [
                    "Storybook_adah_arcanist",
                    "Storybook_adah_standard",
                    "Storybook_adah_garden_gnome",
                    "Storybook_adah_wood_elf",
                    "Storybook_adah_micah",
                    "Storybook_adah_library",
                    "Storybook_adah_emberforge",
                    "Storybook_Main_Char_M",
                    "Storybook_Main_Char_M_Alt"
                ]
            case .female:
                return [
                    "Storybook_adah_arcanist",
                    "Storybook_adah_standard",
                    "Storybook_adah_garden_gnome",
                    "Storybook_adah_wood_elf",
                    "Storybook_adah_stacy",
                    "Storybook_adah_library",
                    "Storybook_adah_emberforge",
                    "Storybook_Main_Char_F",
                    "Storybook_Main_Char_F_Alt"
                ]
            }
        }
    }

    private static func styledAssetCandidates(base: [String], style: ArtworkStyle, includeBase: Bool = true) -> [String] {
        guard style != .adult else { return base }
        var variants: [String] = []
        for candidate in base {
            let normalized = stripKnownImageExtension(from: candidate)
            let directory = normalized.split(separator: "/").dropLast().joined(separator: "/")
            let fileName = normalized.split(separator: "/").last.map(String.init) ?? normalized
            let scoped: (String) -> String = { transformedFile in
                directory.isEmpty ? transformedFile : "\(directory)/\(transformedFile)"
            }
            for suffix in style.filenameSuffixes {
                variants.append(scoped("\(fileName)\(suffix)"))
            }
            for prefix in style.filenamePrefixes {
                variants.append(scoped("\(prefix)\(fileName)"))
            }
            variants.append(scoped("\(fileName)_\(style.rawValue)"))
            variants.append(scoped("\(fileName)_\(style.rawValue.lowercased())"))
        }
        return includeBase ? (variants + base) : variants
    }

    @MainActor
    static func assetName(for item: LootItem, allowFallback: Bool = true) -> String? {
        assetName(for: item, artStyle: preferredArtworkStyle, allowFallback: allowFallback)
    }

    @MainActor
    static func assetName(for item: LootItem, artStyle: ArtworkStyle, allowFallback: Bool = true) -> String? {
        let cacheKey = "\(item.id)|\(artStyle.rawValue)|\(allowFallback)"
        if let cached = resolvedItemAssetNameCache[cacheKey] {
            return cached
        }
        let numberToken = itemNumberToken(from: item.name)
        let base = normalizedBase(from: item.name)
        var candidates: [String] = []

        candidates.append(item.name)
        candidates.append(base)
        candidates.append("Item_\(base)")

        if let numberToken {
            candidates.append("\(base)_\(numberToken)")
            candidates.append("Item_\(base)_\(numberToken)")
            candidates.append(numberToken)
            candidates.append("Item_\(numberToken)")
        }

        let styledMatches = deduplicated(
            styledAssetCandidates(base: candidates, style: artStyle, includeBase: artStyle == .adult)
        )
        if let styledMatch = styledMatches.first(where: assetExists(named:)) {
            resolvedItemAssetNameCache[cacheKey] = styledMatch
            return styledMatch
        }
        if allowFallback, artStyle != .adult {
            let adultFallback = deduplicated(styledAssetCandidates(base: candidates, style: .adult))
            let found = adultFallback.first(where: assetExists(named:))
            resolvedItemAssetNameCache[cacheKey] = found
            return found
        }
        resolvedItemAssetNameCache[cacheKey] = nil
        return nil
    }

    @MainActor
    static func assetExists(named name: String) -> Bool {
        let normalized = stripKnownImageExtension(from: name)
        return platformImage(named: normalized) != nil
    }

    @MainActor
    static func clearVolatileCaches() {
        resolvedSpriteSheetNameCache.removeAll()
        resolvedWeeklyMonsterSheetCache.removeAll()
        resolvedAvatarCandidatesCache.removeAll()
        resolvedItemAssetNameCache.removeAll()
        bundlePathCandidatesCache.removeAll()

        #if canImport(UIKit)
        uiImageCache.removeAllObjects()
        uiTileImageCache.removeAllObjects()
        uiNormalizedCGImageCache.removeAllObjects()
        missingUIImageNames.removeAll()
        #elseif canImport(AppKit)
        nsImageCache.removeAllObjects()
        nsTileImageCache.removeAllObjects()
        missingNSImageNames.removeAll()
        #endif
    }

    @MainActor
    static func bundleImage(named name: String) -> Image? {
        bundleImage(named: name, targetPixelSize: nil)
    }

    @MainActor
    static func bundleImage(named name: String, targetPixelSize: CGFloat?) -> Image? {
        let normalized = stripKnownImageExtension(from: name)
        let resolvedTargetPixelSize = targetPixelSize.map { max(1, Int($0.rounded())) } ?? 0
        #if canImport(UIKit)
        if resolvedTargetPixelSize > 0 {
            let cacheKey = "bundle|\(normalized)|\(resolvedTargetPixelSize)" as NSString
            if let cached = uiTileImageCache.object(forKey: cacheKey) {
                return Image(uiImage: cached)
            }
            if let image = platformImage(named: normalized),
               let cgImage = normalizedCGImage(from: image) {
                let thumbnail = thumbnailUIImage(
                    from: cgImage,
                    sourceScale: image.scale,
                    orientation: image.imageOrientation,
                    maxPixelSize: resolvedTargetPixelSize
                )
                uiTileImageCache.setObject(thumbnail, forKey: cacheKey, cost: imageMemoryCost(thumbnail))
                return Image(uiImage: thumbnail)
            }
        } else if let image = platformImage(named: normalized) {
            return Image(uiImage: image)
        }
        #elseif canImport(AppKit)
        if resolvedTargetPixelSize > 0 {
            let cacheKey = "bundle|\(normalized)|\(resolvedTargetPixelSize)" as NSString
            if let cached = nsTileImageCache.object(forKey: cacheKey) {
                return Image(nsImage: cached)
            }
            if let image = platformImage(named: normalized),
               let cgImage = image.cgImage(
                forProposedRect: nil,
                context: nil,
                hints: nil
               ) {
                let thumbnail = thumbnailNSImage(from: cgImage, maxPixelSize: resolvedTargetPixelSize)
                nsTileImageCache.setObject(thumbnail, forKey: cacheKey, cost: imageMemoryCost(thumbnail))
                return Image(nsImage: thumbnail)
            }
        } else if let image = platformImage(named: normalized) {
            return Image(nsImage: image)
        }
        #endif
        return nil
    }

    @MainActor
    static func croppedTileImage(
        named name: String,
        tileIndex: Int,
        columns: Int,
        rows: Int,
        targetPixelSize: CGFloat? = nil
    ) -> Image? {
        let normalized = stripKnownImageExtension(from: name)
        let safeIndex = max(1, min(tileIndex, columns * rows))
        let cropVersion = "inset-v1"
        let resolvedTargetPixelSize = targetPixelSize.map { max(1, Int($0.rounded())) } ?? 0
        #if canImport(UIKit)
        let cacheKey = "\(normalized)|\(safeIndex)|\(columns)|\(rows)|\(cropVersion)|\(resolvedTargetPixelSize)" as NSString
        if let cached = uiTileImageCache.object(forKey: cacheKey) {
            return Image(uiImage: cached)
        }
        guard let image = platformImage(named: normalized),
              let cgImage = normalizedCGImage(from: image) else {
            return nil
        }
        guard let cropped = croppedCGImage(
            from: cgImage,
            tileIndex: safeIndex,
            columns: columns,
            rows: rows
        ) else {
            return nil
        }
        let tileImage = thumbnailUIImage(
            from: cropped,
            sourceScale: image.scale,
            orientation: image.imageOrientation,
            maxPixelSize: resolvedTargetPixelSize
        )
        uiTileImageCache.setObject(tileImage, forKey: cacheKey, cost: imageMemoryCost(tileImage))
        return Image(uiImage: tileImage)
        #elseif canImport(AppKit)
        let cacheKey = "\(normalized)|\(safeIndex)|\(columns)|\(rows)|\(cropVersion)|\(resolvedTargetPixelSize)" as NSString
        if let cached = nsTileImageCache.object(forKey: cacheKey) {
            return Image(nsImage: cached)
        }
        guard let image = platformImage(named: normalized),
              let cgImage = image.cgImage(
                forProposedRect: nil,
                context: nil,
                hints: nil
              ) else {
            return nil
        }
        guard let cropped = croppedCGImage(
            from: cgImage,
            tileIndex: safeIndex,
            columns: columns,
            rows: rows
        ) else {
            return nil
        }
        let tileImage = thumbnailNSImage(
            from: cropped,
            maxPixelSize: resolvedTargetPixelSize
        )
        nsTileImageCache.setObject(tileImage, forKey: cacheKey, cost: imageMemoryCost(tileImage))
        return Image(nsImage: tileImage)
        #else
        return nil
        #endif
    }

    #if canImport(UIKit)
    @MainActor private static let uiImageCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 96
        cache.totalCostLimit = 64 * 1024 * 1024
        return cache
    }()
    @MainActor private static let uiTileImageCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 192
        cache.totalCostLimit = 32 * 1024 * 1024
        return cache
    }()
    @MainActor private static let uiNormalizedCGImageCache: NSCache<NSString, CGImage> = {
        let cache = NSCache<NSString, CGImage>()
        cache.countLimit = 48
        cache.totalCostLimit = 48 * 1024 * 1024
        return cache
    }()
    @MainActor private static var missingUIImageNames: Set<String> = []

    @MainActor
    private static func platformImage(named normalized: String) -> UIImage? {
        let cacheKey = normalized as NSString
        if let cached = uiImageCache.object(forKey: cacheKey) {
            return cached
        }
        if missingUIImageNames.contains(normalized) {
            return nil
        }

        if let image = UIImage(named: normalized) {
            let cost = imageMemoryCost(image)
            uiImageCache.setObject(image, forKey: cacheKey, cost: cost)
            return image
        }

        let nameOnly = normalized.split(separator: "/").last.map(String.init) ?? normalized
        if let image = UIImage(named: nameOnly) {
            let cost = imageMemoryCost(image)
            uiImageCache.setObject(image, forKey: cacheKey, cost: cost)
            return image
        }

        for candidate in bundlePathCandidates(for: normalized) {
            if let image = UIImage(contentsOfFile: candidate.path) {
                uiImageCache.setObject(image, forKey: cacheKey, cost: imageMemoryCost(image))
                return image
            }
        }
        missingUIImageNames.insert(normalized)
        return nil
    }

    @MainActor
    private static func normalizedCGImage(from image: UIImage) -> CGImage? {
        let cacheKey = "\(image.hashValue)|\(Int(image.size.width))x\(Int(image.size.height))|\(image.imageOrientation.rawValue)|\(image.scale)" as NSString
        if let cached = uiNormalizedCGImageCache.object(forKey: cacheKey) {
            return cached
        }
        if image.imageOrientation == .up, let cgImage = image.cgImage {
            uiNormalizedCGImageCache.setObject(cgImage, forKey: cacheKey, cost: cgImageMemoryCost(cgImage))
            return cgImage
        }
        guard image.size.width > 0, image.size.height > 0 else {
            return image.cgImage
        }
        let pixelSize = CGSize(
            width: image.size.width * image.scale,
            height: image.size.height * image.scale
        )
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: pixelSize, format: format)
        let normalizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: pixelSize))
        }
        if let normalizedCGImage = normalizedImage.cgImage {
            uiNormalizedCGImageCache.setObject(normalizedCGImage, forKey: cacheKey, cost: cgImageMemoryCost(normalizedCGImage))
            return normalizedCGImage
        }
        return image.cgImage
    }

    private static func thumbnailUIImage(
        from image: CGImage,
        sourceScale: CGFloat,
        orientation: UIImage.Orientation,
        maxPixelSize: Int
    ) -> UIImage {
        guard maxPixelSize > 0 else {
            return UIImage(cgImage: image, scale: sourceScale, orientation: orientation)
        }

        let longestEdge = max(image.width, image.height)
        guard longestEdge > maxPixelSize else {
            return UIImage(cgImage: image, scale: sourceScale, orientation: orientation)
        }

        let scaleRatio = CGFloat(maxPixelSize) / CGFloat(longestEdge)
        let outputSize = CGSize(
            width: max(1, CGFloat(image.width) * scaleRatio),
            height: max(1, CGFloat(image.height) * scaleRatio)
        )

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: outputSize, format: format)
        let rendered = renderer.image { context in
            context.cgContext.interpolationQuality = .high
            UIImage(cgImage: image, scale: 1, orientation: orientation).draw(
                in: CGRect(origin: .zero, size: outputSize)
            )
        }
        return rendered
    }
    #elseif canImport(AppKit)
    @MainActor private static let nsImageCache: NSCache<NSString, NSImage> = {
        let cache = NSCache<NSString, NSImage>()
        cache.countLimit = 96
        cache.totalCostLimit = 64 * 1024 * 1024
        return cache
    }()
    @MainActor private static let nsTileImageCache: NSCache<NSString, NSImage> = {
        let cache = NSCache<NSString, NSImage>()
        cache.countLimit = 192
        cache.totalCostLimit = 32 * 1024 * 1024
        return cache
    }()
    @MainActor private static var missingNSImageNames: Set<String> = []

    @MainActor
    private static func platformImage(named normalized: String) -> NSImage? {
        let cacheKey = normalized as NSString
        if let cached = nsImageCache.object(forKey: cacheKey) {
            return cached
        }
        if missingNSImageNames.contains(normalized) {
            return nil
        }

        if let image = NSImage(named: NSImage.Name(normalized)) {
            nsImageCache.setObject(image, forKey: cacheKey, cost: imageMemoryCost(image))
            return image
        }

        let nameOnly = normalized.split(separator: "/").last.map(String.init) ?? normalized
        if let image = NSImage(named: NSImage.Name(nameOnly)) {
            nsImageCache.setObject(image, forKey: cacheKey, cost: imageMemoryCost(image))
            return image
        }

        for candidate in bundlePathCandidates(for: normalized) {
            if let image = NSImage(contentsOf: candidate) {
                nsImageCache.setObject(image, forKey: cacheKey, cost: imageMemoryCost(image))
                return image
            }
        }
        missingNSImageNames.insert(normalized)
        return nil
    }

    private static func thumbnailNSImage(from image: CGImage, maxPixelSize: Int) -> NSImage {
        guard maxPixelSize > 0 else {
            return NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))
        }

        let longestEdge = max(image.width, image.height)
        guard longestEdge > maxPixelSize else {
            return NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))
        }

        let scaleRatio = CGFloat(maxPixelSize) / CGFloat(longestEdge)
        let outputSize = NSSize(
            width: max(1, CGFloat(image.width) * scaleRatio),
            height: max(1, CGFloat(image.height) * scaleRatio)
        )

        let rendered = NSImage(size: outputSize)
        rendered.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        NSImage(cgImage: image, size: outputSize).draw(
            in: NSRect(origin: .zero, size: outputSize)
        )
        rendered.unlockFocus()
        return rendered
    }
    #endif

    @MainActor
    private static func bundlePathCandidates(for normalized: String) -> [URL] {
        if let cached = bundlePathCandidatesCache[normalized] {
            return cached
        }
        let direct = Bundle.main.url(forResource: normalized, withExtension: nil)
        let png = Bundle.main.url(forResource: normalized, withExtension: "png")
        let jpg = Bundle.main.url(forResource: normalized, withExtension: "jpg")
        let jpeg = Bundle.main.url(forResource: normalized, withExtension: "jpeg")
        let webp = Bundle.main.url(forResource: normalized, withExtension: "webp")

        let cleaned = stripKnownImageExtension(from: normalized)
        let subDir = cleaned.split(separator: "/")
        let fileName = subDir.last.map(String.init) ?? cleaned
        let directory = subDir.dropLast().joined(separator: "/")
        let subPng = Bundle.main.url(forResource: fileName, withExtension: "png", subdirectory: directory.isEmpty ? nil : directory)
        let subJpg = Bundle.main.url(forResource: fileName, withExtension: "jpg", subdirectory: directory.isEmpty ? nil : directory)
        let subJpeg = Bundle.main.url(forResource: fileName, withExtension: "jpeg", subdirectory: directory.isEmpty ? nil : directory)
        let subWebp = Bundle.main.url(forResource: fileName, withExtension: "webp", subdirectory: directory.isEmpty ? nil : directory)
        let candidates = [direct, png, jpg, jpeg, webp, subPng, subJpg, subJpeg, subWebp].compactMap { $0 }
        bundlePathCandidatesCache[normalized] = candidates
        return candidates
    }

    private static func stripKnownImageExtension(from value: String) -> String {
        let lower = value.lowercased()
        let exts = [".png", ".jpg", ".jpeg", ".webp"]
        guard let ext = exts.first(where: { lower.hasSuffix($0) }) else {
            return value
        }
        return String(value.dropLast(ext.count))
    }

    private static func itemNumberToken(from name: String) -> String? {
        guard let hashIndex = name.lastIndex(of: "#") else {
            return nil
        }
        let digits = name[name.index(after: hashIndex)...]
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !digits.isEmpty, digits.allSatisfy(\.isNumber) else {
            return nil
        }
        return "#\(digits)"
    }

    private static func normalizedBase(from value: String) -> String {
        let withoutHash = value.split(separator: "#").first.map(String.init) ?? value
        let collapsed = withoutHash
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "_")
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_-"))
        let scalars = collapsed.unicodeScalars.map { scalar in
            allowed.contains(scalar) ? Character(scalar) : "_"
        }
        return String(scalars)
            .replacingOccurrences(of: "__", with: "_")
            .trimmingCharacters(in: CharacterSet(charactersIn: "_"))
    }

    private static func croppedCGImage(
        from image: CGImage,
        tileIndex: Int,
        columns: Int,
        rows: Int
    ) -> CGImage? {
        guard columns > 0, rows > 0 else { return nil }
        let zeroIndex = tileIndex - 1
        let column = zeroIndex % columns
        let row = zeroIndex / columns
        let tileWidth = image.width / columns
        let tileHeight = image.height / rows
        guard tileWidth > 0, tileHeight > 0 else { return nil }
        let insetX = max(1, tileWidth / 40)
        let insetY = max(1, tileHeight / 40)
        let cropRect = CGRect(
            x: (column * tileWidth) + insetX,
            y: (row * tileHeight) + insetY,
            width: max(1, tileWidth - (insetX * 2)),
            height: max(1, tileHeight - (insetY * 2))
        ).integral
        return image.cropping(to: cropRect)
    }

    #if canImport(UIKit)
    private static func imageMemoryCost(_ image: UIImage) -> Int {
        if let cgImage = image.cgImage {
            return cgImageMemoryCost(cgImage)
        }
        let width = Int(image.size.width * image.scale)
        let height = Int(image.size.height * image.scale)
        return max(1, width * height * 4)
    }
    #elseif canImport(AppKit)
    private static func imageMemoryCost(_ image: NSImage) -> Int {
        let width = Int(image.size.width)
        let height = Int(image.size.height)
        return max(1, width * height * 4)
    }
    #endif

    private static func cgImageMemoryCost(_ image: CGImage) -> Int {
        max(1, image.bytesPerRow * image.height)
    }
}

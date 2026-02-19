import AppKit

final class CustomCharacterManager: Sendable {
    static let shared = CustomCharacterManager()

    private nonisolated(unsafe) let defaults: UserDefaults
    private static let listKey = "iruka_custom_characters"

    private var charactersDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("iruka-kun/Characters", isDirectory: true)
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        try? FileManager.default.createDirectory(at: charactersDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Add / Remove

    func addCharacter(name: String, imageURL: URL) -> CharacterType? {
        let sanitized = sanitizeFileName(name)
        guard !sanitized.isEmpty else { return nil }

        let uniqueName = uniqueCharacterName(sanitized)
        let destURL = charactersDirectory.appendingPathComponent("\(uniqueName).png")

        guard let image = NSImage(contentsOf: imageURL),
              let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:])
        else { return nil }

        do {
            try pngData.write(to: destURL)
        } catch {
            NSLog("[iruka-kun] Failed to save custom character: \(error)")
            return nil
        }

        var list = customCharacterNames()
        list.append(uniqueName)
        defaults.set(list, forKey: Self.listKey)

        return .custom(uniqueName)
    }

    func removeCharacter(_ id: String) {
        let fileURL = charactersDirectory.appendingPathComponent("\(id).png")
        try? FileManager.default.removeItem(at: fileURL)

        var list = customCharacterNames()
        list.removeAll { $0 == id }
        defaults.set(list, forKey: Self.listKey)
    }

    // MARK: - Query

    func customCharacterNames() -> [String] {
        defaults.stringArray(forKey: Self.listKey) ?? []
    }

    func allCustomTypes() -> [CharacterType] {
        customCharacterNames().map { .custom($0) }
    }

    func loadImage(for id: String) -> NSImage? {
        let fileURL = charactersDirectory.appendingPathComponent("\(id).png")
        return NSImage(contentsOf: fileURL)
    }

    // MARK: - Private

    private func sanitizeFileName(_ name: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(.init(charactersIn: "-_"))
        return name.unicodeScalars.filter { allowed.contains($0) }.map { String($0) }.joined()
    }

    private func uniqueCharacterName(_ base: String) -> String {
        let existing = Set(customCharacterNames())
        if !existing.contains(base) { return base }
        for i in 2...999 {
            let candidate = "\(base)-\(i)"
            if !existing.contains(candidate) { return candidate }
        }
        return "\(base)-\(UUID().uuidString.prefix(6))"
    }
}

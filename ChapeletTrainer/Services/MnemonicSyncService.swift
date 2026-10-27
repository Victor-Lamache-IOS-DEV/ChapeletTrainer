import Foundation
import SwiftData

public struct MnemonicExportItem: Codable {
    public let position: Int
    public let card: String
    public let mnemonic: String

    public init(position: Int, card: String, mnemonic: String) {
        self.position = position
        self.card = card
        self.mnemonic = mnemonic
    }
}

public struct MnemonicExportContainer: Codable {
    public let version: String
    public let exportedAt: Date
    public let mnemonics: [MnemonicExportItem]

    public init(version: String = "1.0", exportedAt: Date = Date(), mnemonics: [MnemonicExportItem]) {
        self.version = version
        self.exportedAt = exportedAt
        self.mnemonics = mnemonics
    }
}

public final class MnemonicSyncService {
    public static func createExportJSON(from items: [CardProgress]) -> Data? {
        let exportItems = items.sorted { $0.position < $1.position }.map { item in
            let cardName = item.card?.assetName ?? ""
            return MnemonicExportItem(position: item.position, card: cardName, mnemonic: item.mnemonic)
        }
        let container = MnemonicExportContainer(mnemonics: exportItems)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try? encoder.encode(container)
    }

    public static func exportFileURL(from items: [CardProgress]) -> URL? {
        guard let data = createExportJSON(from: items) else { return nil }
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("Mnemonica_Indices.json")
        do {
            try data.write(to: fileURL, options: .atomic)
            return fileURL
        } catch {
            return nil
        }
    }

    public static func importMnemonics(from url: URL, into items: [CardProgress]) -> Int {
        guard let data = try? Data(contentsOf: url) else { return 0 }
        return importMnemonics(from: data, into: items)
    }

    public static func importMnemonics(from data: Data, into items: [CardProgress]) -> Int {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        var count = 0
        // Attempt container format
        if let container = try? decoder.decode(MnemonicExportContainer.self, from: data) {
            let map = Dictionary(uniqueKeysWithValues: items.map { ($0.position, $0) })
            for entry in container.mnemonics {
                if let progress = map[entry.position] {
                    progress.mnemonic = entry.mnemonic
                    count += 1
                }
            }
            return count
        }

        // Attempt direct array format
        if let array = try? decoder.decode([MnemonicExportItem].self, from: data) {
            let map = Dictionary(uniqueKeysWithValues: items.map { ($0.position, $0) })
            for entry in array {
                if let progress = map[entry.position] {
                    progress.mnemonic = entry.mnemonic
                    count += 1
                }
            }
            return count
        }

        return 0
    }
}

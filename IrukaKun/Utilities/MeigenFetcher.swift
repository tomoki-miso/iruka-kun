import Foundation

struct MeigenResponse: Codable {
    let meigen: String
    let auther: String
}

final class MeigenFetcher: Sendable {
    private static let endpoint = URL(string: "https://meigen.doodlenote.net/api/json.php")!

    func fetch() async -> MeigenResponse? {
        do {
            let (data, _) = try await URLSession.shared.data(from: Self.endpoint)
            let items = try JSONDecoder().decode([MeigenResponse].self, from: data)
            return items.first
        } catch {
            return nil
        }
    }
}

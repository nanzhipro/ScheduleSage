import Foundation

extension JSONDecoder {
    /// Standard decoder configuration for API responses
    /// - Note: Uses snake_case conversion and ISO8601 date parsing
    public static let iso8601SnakeCase: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
} 
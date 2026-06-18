import Foundation

enum APIConfiguration {
    static let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    static let model = "claude-sonnet-4-6"
    static let anthropicVersion = "2023-06-01"
    static let maxTokens = 1024
    // Low temperature produces consistent structured output for symptom extraction
    static let temperature: Double = 0.1
    static let timeoutInterval: TimeInterval = 15
}

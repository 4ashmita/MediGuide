import Foundation

enum ClaudeRequest {
    case text(system: String?, user: String)
    case image(system: String?, imageData: Data, mediaType: String, userText: String)
}

enum RequestBuilder {

    private struct APIPayload: Encodable {
        let model: String
        let maxTokens: Int
        let temperature: Double
        let system: String?
        let messages: [Message]

        enum CodingKeys: String, CodingKey {
            case model, temperature, system, messages
            case maxTokens = "max_tokens"
        }
    }

    private struct Message: Encodable {
        let role: String
        let content: Content

        enum Content: Encodable {
            case text(String)
            case blocks([Block])

            func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                switch self {
                case .text(let s):   try container.encode(s)
                case .blocks(let b): try container.encode(b)
                }
            }
        }
    }

    private struct Block: Encodable {
        let type: String
        let text: String?
        let source: ImageSource?

        init(text: String) {
            self.type = "text"; self.text = text; self.source = nil
        }

        init(imageData: Data, mediaType: String) {
            self.type = "image"; self.text = nil
            self.source = ImageSource(type: "base64", mediaType: mediaType,
                                      data: imageData.base64EncodedString())
        }

        struct ImageSource: Encodable {
            let type: String
            let mediaType: String
            let data: String
            enum CodingKeys: String, CodingKey {
                case type, data
                case mediaType = "media_type"
            }
        }
    }

    static func build(from request: ClaudeRequest, apiKey: String) throws -> URLRequest {
        let payload: APIPayload
        switch request {
        case .text(let system, let user):
            payload = APIPayload(model: APIConfiguration.model,
                                 maxTokens: APIConfiguration.maxTokens,
                                 temperature: APIConfiguration.temperature,
                                 system: system,
                                 messages: [Message(role: "user", content: .text(user))])
        case .image(let system, let imageData, let mediaType, let userText):
            let blocks: [Block] = [Block(imageData: imageData, mediaType: mediaType), Block(text: userText)]
            payload = APIPayload(model: APIConfiguration.model,
                                 maxTokens: APIConfiguration.maxTokens,
                                 temperature: APIConfiguration.temperature,
                                 system: system,
                                 messages: [Message(role: "user", content: .blocks(blocks))])
        }

        var urlRequest = URLRequest(url: APIConfiguration.endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "content-type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        urlRequest.setValue(APIConfiguration.anthropicVersion, forHTTPHeaderField: "anthropic-version")
        urlRequest.timeoutInterval = APIConfiguration.timeoutInterval
        urlRequest.httpBody = try JSONEncoder().encode(payload)
        return urlRequest
    }
}

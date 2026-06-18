import Foundation

final class ClaudeAPIClient {
    static let shared = ClaudeAPIClient()

    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest  = APIConfiguration.timeoutInterval
        config.timeoutIntervalForResource = APIConfiguration.timeoutInterval * 3
        session = URLSession(configuration: config)
    }

    /// Sends a Claude request and returns the validated response text.
    /// All failures produce a typed APIError so callers can immediately route to their fallback path.
    func send(_ claudeRequest: ClaudeRequest) async -> Result<String, APIError> {
        guard NetworkReachabilityMonitor.shared.isReachable else {
            APIUsageLogger.log(.failure(.noConnection))
            return .failure(.noConnection)
        }

        guard let apiKey = APICredentialManager.apiKey() else {
            APIUsageLogger.log(.failure(.missingCredential))
            return .failure(.missingCredential)
        }

        guard let urlRequest = try? RequestBuilder.build(from: claudeRequest, apiKey: apiKey) else {
            return .failure(.invalidResponse)
        }

        var result = await attempt(urlRequest)

        // Single retry for transient failures (timeout, 5xx)
        if case .failure(let error) = result, APIErrorHandler.isTransient(error) {
            APIUsageLogger.log(.retrying)
            result = await attempt(urlRequest)
        }

        if case .failure = result {
            APIUsageLogger.log(.fallbackTriggered)
        }

        return result
    }

    private func attempt(_ request: URLRequest) async -> Result<String, APIError> {
        let start = Date()
        do {
            let (data, response) = try await session.data(for: request)
            let elapsed = Date().timeIntervalSince(start)

            switch APIErrorHandler.handle(response: response, data: data, error: nil) {
            case .success(let body):
                let textResult = ResponseValidator.extractText(from: body)
                switch textResult {
                case .success:        APIUsageLogger.log(.success(duration: elapsed))
                case .failure(let e): APIUsageLogger.log(.failure(e))
                }
                return textResult
            case .failure(let error):
                APIUsageLogger.log(.failure(error))
                return .failure(error)
            }
        } catch {
            switch APIErrorHandler.handle(response: nil, data: nil, error: error) {
            case .failure(let apiError):
                APIUsageLogger.log(.failure(apiError))
                return .failure(apiError)
            case .success:
                return .failure(.serverError(statusCode: -1))
            }
        }
    }
}

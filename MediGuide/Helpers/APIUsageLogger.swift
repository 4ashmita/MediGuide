import OSLog

// Logs API call outcomes for reliability monitoring.
// Never logs prompt content, symptom data, or anything health-related.
enum APIUsageLogger {

    private static let logger = Logger(subsystem: "com.mediguide", category: "APIUsage")

    enum Event {
        case success(duration: TimeInterval)
        case failure(APIError)
        case retrying
        case fallbackTriggered
    }

    static func log(_ event: Event) {
        switch event {
        case .success(let duration):
            let t = String(format: "%.2f", duration)
            logger.info("API succeeded [\(t, privacy: .public)s]")
        case .failure(let error):
            let code = errorCode(for: error)
            logger.warning("API failed [\(code, privacy: .public)]")
        case .retrying:
            logger.info("API retrying")
        case .fallbackTriggered:
            logger.info("API fallback triggered")
        }
    }

    private static func errorCode(for error: APIError) -> String {
        switch error {
        case .noConnection:          return "no_connection"
        case .timeout:               return "timeout"
        case .missingCredential:     return "missing_credential"
        case .authenticationFailed:  return "auth_failed"
        case .rateLimited:           return "rate_limited"
        case .invalidResponse:       return "invalid_response"
        case .validationFailed:      return "validation_failed"
        case .serverError(let code): return "server_\(code)"
        }
    }
}

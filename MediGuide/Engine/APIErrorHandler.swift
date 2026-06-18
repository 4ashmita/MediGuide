import Foundation

enum APIError: Error {
    case noConnection
    case timeout
    case missingCredential
    case authenticationFailed
    case rateLimited(retryAfter: TimeInterval?)
    case invalidResponse
    case validationFailed(reason: String)
    case serverError(statusCode: Int)
}

enum APIErrorHandler {

    static func handle(response: URLResponse?, data: Data?, error: Error?) -> Result<Data, APIError> {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost,
                 .dataNotAllowed, .internationalRoamingOff:
                return .failure(.noConnection)
            case .timedOut, .cancelled:
                return .failure(.timeout)
            default:
                return .failure(.serverError(statusCode: -1))
            }
        }

        guard let http = response as? HTTPURLResponse else {
            return error != nil ? .failure(.serverError(statusCode: -1)) : .failure(.invalidResponse)
        }

        switch http.statusCode {
        case 200...299:
            return data.map { .success($0) } ?? .failure(.invalidResponse)
        case 401:
            return .failure(.authenticationFailed)
        case 429:
            let delay = http.value(forHTTPHeaderField: "retry-after").flatMap(TimeInterval.init)
            return .failure(.rateLimited(retryAfter: delay))
        case 500...599:
            return .failure(.serverError(statusCode: http.statusCode))
        default:
            return .failure(.serverError(statusCode: http.statusCode))
        }
    }

    // True for errors worth retrying once (brief transient failures)
    static func isTransient(_ error: APIError) -> Bool {
        switch error {
        case .timeout, .serverError: return true
        default: return false
        }
    }
}

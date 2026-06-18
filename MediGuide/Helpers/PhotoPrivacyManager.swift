import UIKit

enum PhotoPrivacyManager {
    /// Drops the caller's reference to the image. Call immediately after visual parsing
    /// completes or on any failure path — the service never stores the image itself.
    static func dispose(_ image: inout UIImage?) {
        image = nil
    }
}

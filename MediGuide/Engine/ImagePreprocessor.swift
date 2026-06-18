import UIKit

enum ImagePreprocessor {
    // Claude's optimal maximum dimension — larger images are downscaled to this
    private static let maxDimension: CGFloat = 1568
    private static let compressionQuality: CGFloat = 0.82
    // Claude API enforces a 5 MB limit per image
    private static let maxBytes = 5 * 1024 * 1024

    struct ProcessedImage {
        let data: Data
        let mediaType: String  // always "image/jpeg"
    }

    enum ProcessingError: Error {
        case encodingFailed
        case imageTooLarge(bytes: Int)
    }

    /// Resizes the image to fit within maxDimension, re-encodes to JPEG (stripping all EXIF
    /// metadata in the process), and validates the result is within the API size limit.
    static func process(_ image: UIImage) -> Result<ProcessedImage, ProcessingError> {
        let resized = resize(image)
        guard let data = resized.jpegData(compressionQuality: compressionQuality) else {
            return .failure(.encodingFailed)
        }
        guard data.count <= maxBytes else {
            return .failure(.imageTooLarge(bytes: data.count))
        }
        return .success(ProcessedImage(data: data, mediaType: "image/jpeg"))
    }

    private static func resize(_ image: UIImage) -> UIImage {
        let size = image.size
        guard size.width > maxDimension || size.height > maxDimension else { return image }
        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = CGSize(
            width:  (size.width  * ratio).rounded(),
            height: (size.height * ratio).rounded()
        )
        return UIGraphicsImageRenderer(size: newSize).image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

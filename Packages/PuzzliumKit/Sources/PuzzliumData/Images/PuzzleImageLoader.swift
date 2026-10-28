import CryptoKit
import Foundation
import PuzzliumDomain

public enum ImageLoadingError: Error {
    case insecureURL
    case badResponse
    case decodingFailed
    case renderingFailed
}

/// Loads puzzle art: draws built-in styles, downloads remote images once and keeps them on disk.
/// Concurrent requests for the same image share one task.
public actor PuzzleImageLoader: PuzzleImageProviding {
    private final class Entry {
        let image: PuzzleImage
        init(_ image: PuzzleImage) { self.image = image }
    }

    private let session: URLSession
    private let disk: DiskImageCache
    private let photosDirectory: URL
    private let memory = NSCache<NSString, Entry>()
    private var inFlight: [String: Task<PuzzleImage, any Error>] = [:]

    public init(
        session: URLSession = .shared,
        cacheDirectory: URL = URL.cachesDirectory.appending(path: "puzzle-images"),
        photosDirectory: URL = UserPhotos.directory
    ) {
        self.session = session
        self.disk = DiskImageCache(directory: cacheDirectory)
        self.photosDirectory = photosDirectory
        memory.totalCostLimit = 96 * 1024 * 1024
    }

    public func image(for source: PuzzleImageSource, pixelSize: Int) async throws -> PuzzleImage {
        let key = "\(source.cacheKey)@\(pixelSize)"
        if let cached = memory.object(forKey: key as NSString) {
            return cached.image
        }
        if let running = inFlight[key] {
            return try await running.value
        }

        let session = session
        let disk = disk
        let photosDirectory = photosDirectory
        let task = Task.detached(priority: .userInitiated) {
            try await Self.produce(source: source, pixelSize: pixelSize, session: session, disk: disk, photosDirectory: photosDirectory)
        }
        inFlight[key] = task
        defer { inFlight[key] = nil }

        let image = try await task.value
        memory.setObject(Entry(image), forKey: key as NSString, cost: pixelSize * pixelSize * 4)
        return image
    }

    private static func produce(
        source: PuzzleImageSource,
        pixelSize: Int,
        session: URLSession,
        disk: DiskImageCache,
        photosDirectory: URL
    ) async throws -> PuzzleImage {
        switch source {
        case let .procedural(style, variant):
            guard let image = ProceduralArtRenderer.render(style: style, variant: variant, pixelSize: pixelSize) else {
                throw ImageLoadingError.renderingFailed
            }
            return PuzzleImage(cgImage: image)

        case let .bundled(name):
            guard let url = (Bundle.module.url(forResource: name, withExtension: "jpg") ?? Bundle.module.url(forResource: name, withExtension: "png")),
                  let data = try? Data(contentsOf: url),
                  let image = ImageDownsampler.squareImage(from: data, pixelSize: pixelSize)
            else { throw ImageLoadingError.decodingFailed }
            return PuzzleImage(cgImage: image)

        case let .photo(name):
            guard let data = try? Data(contentsOf: photosDirectory.appending(path: name)),
                  let image = ImageDownsampler.squareImage(from: data, pixelSize: pixelSize)
            else { throw ImageLoadingError.decodingFailed }
            return PuzzleImage(cgImage: image)

        case let .remote(url):
            guard url.scheme == "https" else { throw ImageLoadingError.insecureURL }
            let data: Data
            if let cached = disk.data(for: url) {
                data = cached
            } else {
                let (downloaded, response) = try await session.data(from: url)
                guard let http = response as? HTTPURLResponse,
                      (200..<300).contains(http.statusCode),
                      http.mimeType?.hasPrefix("image/") == true
                else { throw ImageLoadingError.badResponse }
                disk.store(downloaded, for: url)
                data = downloaded
            }
            guard let image = ImageDownsampler.squareImage(from: data, pixelSize: pixelSize) else {
                throw ImageLoadingError.decodingFailed
            }
            return PuzzleImage(cgImage: image)
        }
    }
}

struct DiskImageCache: Sendable {
    let directory: URL

    func data(for url: URL) -> Data? {
        try? Data(contentsOf: fileURL(for: url))
    }

    func store(_ data: Data, for url: URL) {
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try data.write(to: fileURL(for: url), options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        } catch {
            // Cache is best-effort; the image is re-downloaded next time.
        }
    }

    private func fileURL(for url: URL) -> URL {
        let digest = SHA256.hash(data: Data(url.absoluteString.utf8))
        let name = digest.map { String(format: "%02x", $0) }.joined()
        return directory.appending(path: name)
    }
}

//
//  ImageProvider.swift
//  SearchRepository
//
//  Created by Lee Myeonghwan on 2/7/25.
//

import UIKit

final class ImageProvider {

    static let shared = ImageProvider()

    private let imageCache = NSCache<NSString, UIImage>()

    func fetchImage(from urlString: String) async throws -> UIImage? {
        let urlNSString = NSString(string: urlString)
        if let cachedImage = imageCache.object(forKey: urlNSString) {
            return cachedImage
        }
        guard let url = URL(string: urlString) else { return nil }

        let (data, _) = try await URLSession.shared.data(from: url)

        guard let image = UIImage(data: data) else { return nil }
        imageCache.setObject(image, forKey: urlNSString)
        return UIImage(data: data)
    }
}

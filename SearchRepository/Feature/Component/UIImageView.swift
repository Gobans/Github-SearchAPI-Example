//
//  UIImageView.swift
//  SearchRepository
//
//  Created by Lee Myeonghwan on 2/7/25.
//

import UIKit

extension UIImageView {
    func setImage(from urlString: String, placeholder: UIImage? = nil) {
        self.image = placeholder

        Task {
            do {
                if let image = try await ImageProvider.shared.fetchImage(from: urlString) {
                    DispatchQueue.main.async {
                        self.image = image
                    }
                }
            } catch {
                print("❌ Image load failed: \(error)")
            }
        }
    }
}

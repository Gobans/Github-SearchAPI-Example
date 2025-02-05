//
//  FavoriteRepository.swift
//  SearchRepository
//
//  Created by Lee Myeonghwan on 2/5/25.
//

import Foundation
import Combine

protocol FavoriteRepositoryDataMananger {
    var favoriteRepositoryData: AnyPublisher<FavoriteRepositoryData, Never> { get }
    func change(_ data: FavoriteRepositoryData)
}

final class FavoriteRepositoryDataManangerImpl: FavoriteRepositoryDataMananger {

    private let favoriteSubject = PassthroughSubject<FavoriteRepositoryData, Never>()

    var favoriteRepositoryData: AnyPublisher<FavoriteRepositoryData, Never> {
        favoriteSubject.eraseToAnyPublisher()
    }

    func change(_ data: FavoriteRepositoryData) {
        favoriteSubject.send(data)
    }

    func isFavorite(repositoryId: Int) -> Bool {
        return false
    }

    func favoriteRepositoryDataList() -> [RepositoryData] {
        return []
    }
}

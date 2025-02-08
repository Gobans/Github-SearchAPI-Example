//
//  FavoriteRepositoryDataMananger.swift
//  SearchRepository
//
//  Created by Lee Myeonghwan on 2/8/25.
//

import Foundation
import Combine

protocol FavoriteRepoDataMananger {
    var changedRepositoryData: AnyPublisher<FavoriteRepositoryData, Never> { get }
    func change(data: RepositoryData, isFavorite: Bool)
    func repositoryDataDict() -> [RepositoryData.ID : RepositoryData]
}

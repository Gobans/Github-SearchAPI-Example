//
//  FavoriteRepository.swift
//  SearchRepository
//
//  Created by Lee Myeonghwan on 2/8/25.
//

import Foundation

protocol FavoriteRepository {
    func isFavorite(repositoryId: RepositoryData.ID) -> Bool
}

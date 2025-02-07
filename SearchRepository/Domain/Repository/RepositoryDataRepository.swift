//
//  RepositoryDataRepository.swift
//  RepositoryDataRepository
//
//  Created by Lee Myeonghwan on 2/4/25.
//

import Foundation
import Combine

protocol RepositoryDataRemoteRepository {
    func fetchRepositoryDataList(query: String, page: Int) -> AnyPublisher<[RepositoryData], SearchError>
}

protocol RepositoryDataLocalRepository {
    func fetchRepositoryDataList() -> [RepositoryData]
}

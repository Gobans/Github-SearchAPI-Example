//
//  RepositoryDataRepository.swift
//  RepositoryDataRepository
//
//  Created by Lee Myeonghwan on 2/4/25.
//

import Foundation
import Combine

protocol RepoDataRepository {
    func fetchRepositoryDataList(query: String, page: Int) -> AnyPublisher<[RepositoryData], SearchError>
}

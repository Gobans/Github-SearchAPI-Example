//
//  MockRepoDataRepository.swift
//  SearchRepositoryTests
//
//  Created by Lee Myeonghwan on 2/8/25.
//

import Foundation
import Combine
@testable import SearchRepository

final class MockRepoDataRepository: RepoDataRepository {

    var stubbedRepoDataListResult: AnyPublisher<[RepositoryData], SearchError> = Just([])
        .setFailureType(to: SearchError.self)
        .eraseToAnyPublisher()

    func fetchRepositoryDataList(query: String, page: Int) -> AnyPublisher<[SearchRepository.RepositoryData], SearchRepository.SearchError> {
        stubbedRepoDataListResult
    }
}

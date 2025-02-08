//
//  SearchRepoUseCaseMock.swift
//  SearchRepositoryTests
//
//  Created by Lee Myeonghwan on 2/8/25.
//

import Foundation
import Combine
@testable import SearchRepository

final class MockSearchRepoUseCase: SearchRepoUseCase {

    var stubbedRepoDataListResult: AnyPublisher<[RepositoryData], SearchError> = Just([])
        .setFailureType(to: SearchError.self)
        .eraseToAnyPublisher()

    var repoDataListCallCount = 0
    var pageCount = 0

    func repoDataList(query: String, page: Int) -> AnyPublisher<[RepositoryData], SearchError> {
        repoDataListCallCount += 1
        pageCount = page
        return stubbedRepoDataListResult
    }

}

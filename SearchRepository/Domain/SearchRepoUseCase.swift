//
//  SearchRepositoryDataUseCase.swift
//  SearchRepository
//
//  Created by Lee Myeonghwan on 2/4/25.
//

import Foundation
import Combine

protocol SearchRepoUseCase {
    func repoDataList(query: String, page: Int) -> AnyPublisher<[RepositoryData], SearchError>
}

final class SearchRepoUseCaseImpl: SearchRepoUseCase {

    let repository: RepoDataRepository

    init(repository: RepoDataRepository) {
        self.repository = repository
    }

    func repoDataList(query: String, page: Int) -> AnyPublisher<[RepositoryData], SearchError> {
        guard !query.isEmpty else { return Just([]).setFailureType(to: SearchError.self).eraseToAnyPublisher() }
        let isPaging = page > 1
        return repository.fetchRepositoryDataList(query: query, page: page)
            .flatMap { data -> AnyPublisher<[RepositoryData], SearchError> in
                if isPaging && data.isEmpty {
                    return Fail(error: SearchError.noMorePageAvailable).eraseToAnyPublisher()
                }
                return Just(data).setFailureType(to: SearchError.self).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}


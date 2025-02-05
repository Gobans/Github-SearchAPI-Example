//
//  SearchRepositoryDataUseCase.swift
//  SearchRepository
//
//  Created by Lee Myeonghwan on 2/4/25.
//

import Foundation
import Combine

protocol SearchRepositoryDataUseCase {
    func repositoryDataList(query: String, page: Int) -> AnyPublisher<[RepositoryData], Error>
}

final class SearchRepositoryDataUseCaseImpl: SearchRepositoryDataUseCase {

    let repository: RepositoryDataRemoteRepository

    init(repository: RepositoryDataRemoteRepository) {
        self.repository = repository
    }

    func repositoryDataList(query: String, page: Int) -> AnyPublisher<[RepositoryData], Error> {
        guard !query.isEmpty else { return Empty().eraseToAnyPublisher() }
        return repository.fetchRepositoryDataList(query: query, page: page)
    }
}


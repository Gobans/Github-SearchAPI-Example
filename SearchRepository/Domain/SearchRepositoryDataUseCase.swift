//
//  SearchRepositoryDataUseCase.swift
//  SearchRepository
//
//  Created by Lee Myeonghwan on 2/4/25.
//

import Foundation
import Combine

protocol SearchRepositoryDataUseCase {
    func repositoryDataList(query: String, page: Int) -> AnyPublisher<[RepositoryData], Never>
}

final class SearchRepositoryDataUseCaseImpl: SearchRepositoryDataUseCase {

    // perPage, totalCount 계산에 따라 요청 안보내기

    let repository: RepositoryDataRemoteRepository

    init(repository: RepositoryDataRemoteRepository) {
        self.repository = repository
    }

    func repositoryDataList(query: String, page: Int) -> AnyPublisher<[RepositoryData], Never> {
        guard !query.isEmpty else { return Just([]).eraseToAnyPublisher() }
        return repository.fetchRepositoryDataList(query: query, page: page)
            .catch { error in
                print(error)
                return Just([RepositoryData]())
            }
            .eraseToAnyPublisher()
    }
}


//
//  RepositoryImple.swift
//  RepositorySearch
//
//  Created by Lee Myeonghwan on 2/4/25.
//

import Foundation
import Combine

final class RepoDataRepositoryImpl: RepoDataRepository {

    private let apiProvider = APIProvider<RepositoryAPI>()

    private let favoriteRepository: FavoriteRepository

    init(favoriteRepository: FavoriteRepository) {
        self.favoriteRepository = favoriteRepository
    }

    private let searchLimitErrorCode = 422
    private let rateLimitExceededErrorCode = [403, 429]

    func fetchRepositoryDataList(query: String, page: Int) -> AnyPublisher<[RepositoryData], SearchError> {
        apiProvider.request(target: .search(query: query, page: page))
            .map { (response: SearchRepositoryResponse) -> [RepositoryData] in
                return response.items.map { item in
                    let isFavorite = self.favoriteRepository.isFavorite(repositoryId: item.id)
                    return RepositoryData(id: item.id, name: item.name, owner: Owner(login: item.owner.login, avatarURL: item.owner.avatarURL), description: item.description, stargazersCount: item.stargazersCount, forksCount: item.forksCount, openIssuesCount: item.openIssuesCount, isFavorite: isFavorite)
                }
            }
            .mapError({ error in
                if let httpError = error as? HTTPError {
                    if httpError.statusCode == self.searchLimitErrorCode {
                        return SearchError.noMorePageAvailable
                    } else if self.rateLimitExceededErrorCode.contains(httpError.statusCode) {
                        return SearchError.tooManyRequest
                    }
                }
                return SearchError.badServerResponse
            })
            .eraseToAnyPublisher()
    }
}

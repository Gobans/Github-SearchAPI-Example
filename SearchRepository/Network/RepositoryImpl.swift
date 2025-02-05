//
//  RepositoryImple.swift
//  RepositorySearch
//
//  Created by Lee Myeonghwan on 2/4/25.
//

import Foundation
import Combine

final class RepositoryDataRemoteRepositoryImpl: RepositoryDataRemoteRepository {

    private let apiProvider = APIProvider<RepositoryAPI>()

    func fetchRepositoryDataList(query: String, page: Int) -> AnyPublisher<[RepositoryData], any Error> {
        apiProvider.request(target: .search(query: query, page: page))
            .map { (response: SearchRepositoryResponse) -> [RepositoryData] in
                // feat: 이곳에서 if Favorite 판단 필요
                return response.items.map { item in
                    RepositoryData(id: item.id, name: item.name, owner: Owner(login: item.owner.login, avatarURL: item.owner.avatarURL), description: item.description, stargazersCount: item.stargazersCount, forksCount: item.forksCount, openIssuesCount: item.openIssuesCount, isFavorite: false)
                }
            }
            .eraseToAnyPublisher()
    }
}

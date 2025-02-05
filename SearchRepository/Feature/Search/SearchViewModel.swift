//
//  SearchViewModel.swift
//  SearchRepository
//
//  Created by Lee Myeonghwan on 2/5/25.
//

import Foundation
import Combine

final class SearchViewModel {

    private(set) var searchResultSubject = PassthroughSubject<SearchResult, Never>()
    @Published var isLoading = SearchLoading(value: false, mode: .search)
    private(set) var changedRepositoryDataSubject = PassthroughSubject<RepositoryData.ID, Never>()
    private(set) var repositoryDataListDict: [RepositoryData.ID: RepositoryData] = [:]
    private var prevQuery: String = ""
    private var currentPage: Int = 1
    private var hasMorePages: Bool = true

    private let repositoryDataUseCase: SearchRepositoryDataUseCase
    private let favoriteRepositoryDataMananger: FavoriteRepositoryDataMananger

    private var cancelBag = Set<AnyCancellable>()

    init(repositoryDataUseCase: SearchRepositoryDataUseCase, favoriteRepositoryDataMananger: FavoriteRepositoryDataMananger) {
        self.repositoryDataUseCase = repositoryDataUseCase
        self.favoriteRepositoryDataMananger = favoriteRepositoryDataMananger
        
        favoriteRepositoryDataMananger.favoriteRepositoryData
            .sink { [weak self] favoriteRepositoryData in
                if let id = self?.repositoryDataListDict.first(where: { $0.value.id == favoriteRepositoryData.id })?.value.id {
                    self?.repositoryDataListDict[id]?.isFavorite = favoriteRepositoryData.favorite
                    self?.changedRepositoryDataSubject.send(id)
                }
            }
            .store(in: &cancelBag)
    }


    func search(for query: String, completion: (() -> Void)? = nil, mode: SearchMode) {
        guard !isLoading.value else { return }
        isLoading = SearchLoading(value: true, mode: mode)

        self.currentPage = 1
        self.prevQuery = query

        repositoryDataUseCase.repositoryDataList(query: query, page: currentPage)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] repositoryData in
                self?.repositoryDataListDict = repositoryData.reduce(into: [:]) { dict, repo in
                    dict[repo.id] = repo
                }
                self?.searchResultSubject.send(SearchResult(repositoryData: repositoryData.map{ $0.id }, type: .all))
                self?.isLoading = SearchLoading(value: false, mode: mode)
                self?.hasMorePages = !repositoryData.isEmpty
                completion?()
            }
            .store(in: &cancelBag)
    }

    func loadMoreIfNeeded() {
        guard !isLoading.value, hasMorePages else { return }

        isLoading = SearchLoading(value: true, mode: .search)
        currentPage += 1

        // refactor: 네트워크 오류인 경우, hasMorePage 상태를 갱신 x
        repositoryDataUseCase.repositoryDataList(query: prevQuery, page: currentPage)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] _ in
                self?.isLoading = SearchLoading(value: false, mode: .search)
            }, receiveValue: { [weak self] repositoryData in
                self?.repositoryDataListDict.merge(repositoryData.reduce(into: [:]) { dict, repo in
                    dict[repo.id] = repo
                }, uniquingKeysWith: { _, new in new })

                self?.searchResultSubject.send(SearchResult(repositoryData: repositoryData.map{ $0.id }, type: .continuous))
                self?.isLoading = SearchLoading(value: false, mode: .search)
                self?.hasMorePages = !repositoryData.isEmpty
            })
            .store(in: &cancelBag)
    }

    func refreshData(completion: @escaping () -> Void) {
        search(for: prevQuery, completion: completion, mode: .refresh)
    }

    func changeFavorite(repositoryId: Int, isFavorite: Bool) {
        if let repositoryData = repositoryDataListDict[repositoryId] {
            favoriteRepositoryDataMananger.change(data: repositoryData, isFavorite: isFavorite)
        }
    }
}

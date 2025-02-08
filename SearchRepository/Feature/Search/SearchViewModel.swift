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
    @Published private(set) var searchResultViewState: SearchResultViewState = .initial

    @Published private(set) var isLoading = SearchLoading(value: false, mode: .search)
    private(set) var showErrorToastSubject = PassthroughSubject<String, Never>()

    private(set) var changedRepoDataSubject = PassthroughSubject<RepositoryData.ID, Never>()
    private(set) var repoDataDict: [RepositoryData.ID: RepositoryData] = [:]

    private var prevQuery: String = ""
    private var currentPage: Int = 1
    private var hasMorePages: Bool = true
    private var isTemporaryPreventPaging = false

    private var isPagingPossible: Bool {
        !isLoading.value && hasMorePages && !isTemporaryPreventPaging
    }

    private var cancelBag = Set<AnyCancellable>()

    private let repoUseCase: SearchRepoUseCase
    private let favoriteRepoDataMananger: FavoriteRepoDataMananger
    private let router: DetailPageRouter

    init(repoUseCase: SearchRepoUseCase, favoriteRepoDataMananger: FavoriteRepoDataMananger, router: DetailPageRouter) {
        self.repoUseCase = repoUseCase
        self.favoriteRepoDataMananger = favoriteRepoDataMananger
        self.router = router

        favoriteRepoDataMananger.changedRepositoryData
            .sink { [weak self] changedRepositoryData in
                if let id = self?.repoDataDict.first(where: { $0.value.id == changedRepositoryData.id })?.value.id {
                    self?.repoDataDict[id]?.isFavorite = changedRepositoryData.favorite
                    self?.changedRepoDataSubject.send(id)
                }
            }
            .store(in: &cancelBag)
    }


    func search(for query: String, searchCompletion: (() -> Void)? = nil, mode: SearchMode) {
        guard !query.isEmpty else {
            searchResultSubject.send(SearchResult(repositoryData: [], type: .all))
            searchResultViewState = .initial
            return
        }
        guard !isLoading.value else { return }
        isLoading = SearchLoading(value: true, mode: mode)

        self.currentPage = 1
        self.prevQuery = query

        repoUseCase.repoDataList(query: query, page: currentPage)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    switch mode {
                    case .search:
                        self?.searchResultSubject.send(SearchResult(repositoryData: [], type: .all))
                        self?.searchResultViewState = .networkError(error.errorMessage)
                    case .refresh:
                        self?.showErrorToastSubject.send(error.errorMessage)
                    }
                }
                self?.isLoading = SearchLoading(value: false, mode: mode)
                searchCompletion?()
            }, receiveValue: { [weak self] repositoryData in
                self?.repoDataDict = repositoryData.reduce(into: [:]) { dict, repo in
                    dict[repo.id] = repo
                }
                if repositoryData.isEmpty {
                    self?.searchResultSubject.send(SearchResult(repositoryData: [], type: .all))
                    self?.searchResultViewState = .noResult
                } else {
                    self?.searchResultSubject.send(SearchResult(repositoryData: repositoryData.map{ $0.id }, type: .all))
                    self?.searchResultViewState = .showResult
                }
                self?.isLoading = SearchLoading(value: false, mode: mode)
                self?.hasMorePages = !repositoryData.isEmpty
                searchCompletion?()
            })
            .store(in: &cancelBag)
    }

    func loadMoreRepositoryData() {
        guard isPagingPossible else { return }

        isLoading = SearchLoading(value: true, mode: .search)
        currentPage += 1

        repoUseCase.repoDataList(query: prevQuery, page: currentPage)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    switch error {
                    case .badServerResponse, .tooManyRequest, .unknown:
                        self?.isTemporaryPreventPaging = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self?.isTemporaryPreventPaging = false
                        }
                        self?.showErrorToastSubject.send(error.errorMessage)
                    case .noMorePageAvailable:
                        self?.hasMorePages = false
                        self?.showErrorToastSubject.send(error.errorMessage)
                    }
                }
                self?.isLoading = SearchLoading(value: false, mode: .search)
            }, receiveValue: { [weak self] repositoryData in
                self?.repoDataDict.merge(repositoryData.reduce(into: [:]) { dict, repo in
                    dict[repo.id] = repo
                }, uniquingKeysWith: { _, new in new })
                self?.searchResultSubject.send(SearchResult(repositoryData: repositoryData.map{ $0.id }, type: .continuous))
                self?.isLoading = SearchLoading(value: false, mode: .search)
            })
            .store(in: &cancelBag)
    }

    func refreshData(completion: @escaping () -> Void) {
        search(for: prevQuery, searchCompletion: completion, mode: .refresh)
    }

    func changeFavorite(repositoryId: Int) {
        if let repositoryData = repoDataDict[repositoryId] {
            let newFavorite = !repositoryData.isFavorite
            favoriteRepoDataMananger.change(data: repositoryData, isFavorite: newFavorite)
        }
    }

    func routeToDetailViewController(repositoryID: Int) {
        if let payload = repoDataDict[repositoryID] {
            router.routeToDetailPage(payload: payload)
        }
    }
}

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
    private(set) var showToastSubject = PassthroughSubject<String, Never>()

    private(set) var changedRepositoryDataSubject = PassthroughSubject<RepositoryData.ID, Never>()
    private(set) var repositoryDataListDict: [RepositoryData.ID: RepositoryData] = [:]

    private var prevQuery: String = ""
    private var currentPage: Int = 1
    private var hasMorePages: Bool = true
    private var isTemporaryPreventPaging = false

    private var isPagingPossible: Bool {
        !isLoading.value && hasMorePages && !isTemporaryPreventPaging
    }

    private let repositoryDataUseCase: SearchRepositoryDataUseCase
    private let favoriteRepositoryDataMananger: FavoriteRepositoryDataMananger
    private let router: FeatureBuilder.Router

    private var cancelBag = Set<AnyCancellable>()

    init(repositoryDataUseCase: SearchRepositoryDataUseCase, favoriteRepositoryDataMananger: FavoriteRepositoryDataMananger, router: FeatureBuilder.Router) {
        self.repositoryDataUseCase = repositoryDataUseCase
        self.favoriteRepositoryDataMananger = favoriteRepositoryDataMananger
        self.router = router

        favoriteRepositoryDataMananger.changedRepositoryData
            .sink { [weak self] changedRepositoryData in
                if let id = self?.repositoryDataListDict.first(where: { $0.value.id == changedRepositoryData.id })?.value.id {
                    self?.repositoryDataListDict[id]?.isFavorite = changedRepositoryData.favorite
                    self?.changedRepositoryDataSubject.send(id)
                }
            }
            .store(in: &cancelBag)
    }


    func search(for query: String, searchCompletion: (() -> Void)? = nil, mode: SearchMode) {
        guard !isLoading.value else { return }
        isLoading = SearchLoading(value: true, mode: mode)

        self.currentPage = 1
        self.prevQuery = query

        repositoryDataUseCase.repositoryDataList(query: query, page: currentPage)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    switch error {
                    case .badServerResponse, .tooManyRequest:
                        switch mode {
                        case .search:
                            self?.searchResultSubject.send(SearchResult(repositoryData: [], type: .all))
                            self?.searchResultViewState = .networkError(error.errorMessage)
                        case .refresh:
                            self?.showToastSubject.send(error.errorMessage)
                        }
                    default:
                        break
                    }
                }
                self?.isLoading = SearchLoading(value: false, mode: mode)
                searchCompletion?()
            }, receiveValue: { [weak self] repositoryData in
                self?.repositoryDataListDict = repositoryData.reduce(into: [:]) { dict, repo in
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

        repositoryDataUseCase.repositoryDataList(query: prevQuery, page: currentPage)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    switch error {
                    case .badServerResponse, .tooManyRequest:
                        self?.isTemporaryPreventPaging = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self?.isTemporaryPreventPaging = false
                        }
                        self?.showToastSubject.send(error.errorMessage)
                    case .noMorePageAvailable:
                        self?.hasMorePages = false
                        self?.showToastSubject.send(error.errorMessage)
                    case .unknown:
                        break
                    }
                }
                self?.isLoading = SearchLoading(value: false, mode: .search)
            }, receiveValue: { [weak self] repositoryData in
                self?.repositoryDataListDict.merge(repositoryData.reduce(into: [:]) { dict, repo in
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
        if let repositoryData = repositoryDataListDict[repositoryId] {
            let newFavorite = !repositoryData.isFavorite
            favoriteRepositoryDataMananger.change(data: repositoryData, isFavorite: newFavorite)
        }
    }

    func routeToDetailViewController(repositoryID: Int) {
        if let payload = repositoryDataListDict[repositoryID] {
            router.routeToDetailPage(payload: payload)
        }
    }
}

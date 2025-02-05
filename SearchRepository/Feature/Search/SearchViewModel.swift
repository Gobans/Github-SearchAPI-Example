//
//  SearchViewModel.swift
//  SearchRepository
//
//  Created by Lee Myeonghwan on 2/5/25.
//

import Foundation
import Combine

final class SearchViewModel {

    @Published private(set) var searchResults: [RepositoryData] = []
    @Published var isLoading = SearchLoading(value: false, mode: .search)

    private var prevQuery: String = ""
    private var currentPage: Int = 1
    private var hasMorePages: Bool = true
    let repositoryDataUseCase = SearchRepositoryDataUseCaseImpl(repository: RepositoryDataRemoteRepositoryImpl())

    private var cancelBag = Set<AnyCancellable>()

    func search(for query: String, completion: (() -> Void)? = nil, mode: SearchMode) {
        guard !isLoading.value else { return }
        isLoading = SearchLoading(value: true, mode: mode)

        self.currentPage = 1
        self.prevQuery = query

        repositoryDataUseCase.repositoryDataList(query: query, page: currentPage)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] repositoryData in
                self?.searchResults = repositoryData
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
            }, receiveValue: { [weak self] moreData in
                self?.searchResults.append(contentsOf: moreData)
                self?.isLoading = SearchLoading(value: false, mode: .search)
                self?.hasMorePages = !moreData.isEmpty
            })
            .store(in: &cancelBag)
    }

    func refreshData(completion: @escaping () -> Void) {
        search(for: prevQuery, completion: completion, mode: .refresh)
    }
}

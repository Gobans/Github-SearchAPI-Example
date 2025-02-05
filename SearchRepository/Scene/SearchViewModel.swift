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
    @Published var isLoading = false

    private var prevQuery: String = ""
    private var currentPage: Int = 1
    private var hasMorePages: Bool = true
    let repositoryDataUseCase = SearchRepositoryDataUseCaseImpl(repository: RepositoryDataRemoteRepositoryImpl())

    private var cancelBag = Set<AnyCancellable>()

    func search(for query: String) {
        guard !isLoading else { return }
        isLoading = true

        guard query != prevQuery else { return }
        self.currentPage = 1
        self.prevQuery = query
        searchResults.removeAll()

        repositoryDataUseCase.repositoryDataList(query: query, page: currentPage)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] repositoryData in
                self?.searchResults = repositoryData
                self?.isLoading = false
                self?.hasMorePages = !repositoryData.isEmpty
            }
            .store(in: &cancelBag)
    }

    func loadMoreIfNeeded() {
        guard !isLoading, hasMorePages else { return }
        
        isLoading = true
        currentPage += 1

        // refactor: 네트워크 오류인 경우, hasMorePage 상태를 갱신 x
        repositoryDataUseCase.repositoryDataList(query: prevQuery, page: currentPage)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] _ in
                self?.isLoading = false
            }, receiveValue: { [weak self] moreData in
                self?.searchResults.append(contentsOf: moreData)
                self?.isLoading = false
                self?.hasMorePages = !moreData.isEmpty
            })
            .store(in: &cancelBag)
    }
}

//
//  SearchRepositoryDataUseCaseImpl.swift
//  SearchRepositoryTests
//
//  Created by Lee Myeonghwan on 2/8/25.
//

import Foundation

import XCTest
@testable import SearchRepository
import Combine

final class SearchRepoUseCaseImplTests: XCTestCase {

    var repoDataRepository: MockRepoDataRepository!
    var useCase: SearchRepoUseCase!

    override func setUp() {
        repoDataRepository = MockRepoDataRepository()
        useCase = SearchRepoUseCaseImpl(repository: repoDataRepository)
    }

    func test_검색쿼리가_없다면_빈_검색결과를_반환() throws {
        // given
        let query = ""
        let searchData: [RepositoryData] = [.mock]
        let expectedRepoDataList: [RepositoryData] = []

        repoDataRepository.stubbedRepoDataListResult = Just(searchData)
            .setFailureType(to: SearchError.self)
            .eraseToAnyPublisher()

        // when
        var receivedRepoDataList: [RepositoryData] = []
        let expectation = XCTestExpectation(description: "Fetch repo data")
        let cancellable = useCase.repoDataList(query: query, page: 1)
            .sink(receiveCompletion: { _ in

            }, receiveValue: { data in
                receivedRepoDataList = data
                expectation.fulfill()
            })

        // then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedRepoDataList, expectedRepoDataList)
        cancellable.cancel()
    }

    func test_페이징중_검색결과가_없다면_페이징을_중단() throws {
        // given
        let query = "test"
        let page = 10
        let searchData: [RepositoryData] = []
        let expectedSearchError: SearchError = .noMorePageAvailable

        repoDataRepository.stubbedRepoDataListResult = Just(searchData)
            .setFailureType(to: SearchError.self)
            .eraseToAnyPublisher()

        // when
        var receivedSearchError: SearchError?
        let expectation = XCTestExpectation(description: "Fetch repo data")
        let cancellable = useCase.repoDataList(query: query, page: page)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    receivedSearchError = error
                    expectation.fulfill()
                }
            }, receiveValue: { _ in })

        // then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedSearchError, expectedSearchError)
        cancellable.cancel()
    }
}

fileprivate extension RepositoryData {
    static let mock = RepositoryData(id: 0, name: "", owner: Owner(login: "", avatarURL: ""), description: "", stargazersCount: 0, forksCount: 0, openIssuesCount: 0, isFavorite: false)
}

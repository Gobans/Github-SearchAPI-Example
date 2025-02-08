//
//  RepositorySearchTests.swift
//  RepositorySearchTests
//
//  Created by Lee Myeonghwan on 2/4/25.
//

import XCTest
@testable import SearchRepository
import Combine

final class SearchViewModelTests: XCTestCase {

    var searchRepoUseCase: MockSearchRepoUseCase!
    var favoriteRepoDataManager: FavoriteRepoDataMananger!
    var detailPageRouter: DetailPageRouter!
    var viewModel: SearchViewModel!

    override func setUp() {
        searchRepoUseCase = MockSearchRepoUseCase()
        favoriteRepoDataManager = FavoriteRepoManangerImpl(userDefaults: MockUserDefaults())
        detailPageRouter = MockDetailPageRouter()
        viewModel = SearchViewModel(repoUseCase: searchRepoUseCase, favoriteRepoDataMananger: favoriteRepoDataManager, router: detailPageRouter)
    }

    // MARK: 검색 기능

    func test_검색했을때_검색데이터가_없다면_검색결과를_빈데이터로_전체_초기화() throws {
        // given
        let searchData: [RepositoryData] = []
        let expectedSearchResult: SearchResult = SearchResult(repositoryData: [], type: .all)

        searchRepoUseCase.stubbedRepoDataListResult = Just(searchData)
            .setFailureType(to: SearchError.self)
            .eraseToAnyPublisher()
        let query = "test"

        // when
        viewModel.search(for: query, mode: .search)
        let expectation = XCTestExpectation(description: "Fetch repo data")
        var receivedSearchResult: SearchResult?

        let cancellable = viewModel.searchResultSubject
            .sink{ data in
                receivedSearchResult = data
                expectation.fulfill()
            }

        wait(for: [expectation], timeout: 1.0)

        // then
        XCTAssertEqual(receivedSearchResult?.repositoryData, expectedSearchResult.repositoryData)
        XCTAssertEqual(receivedSearchResult?.type, expectedSearchResult.type)
        cancellable.cancel()
    }

    func test_검색했을때_검색데이터가_없다면_검색결과_없음을_표시() throws {
        // given
        let searchData: [RepositoryData] = []
        let expectedViewSate: SearchResultViewState = .noResult

        searchRepoUseCase.stubbedRepoDataListResult = Just(searchData)
            .setFailureType(to: SearchError.self)
            .eraseToAnyPublisher()
        let query = "test"

        // when
        viewModel.search(for: query, mode: .search)
        let expectation = XCTestExpectation(description: "Fetch repo data")
        var receivedViewState: SearchResultViewState?

        let cancellable = viewModel.$searchResultViewState
            .dropFirst()
            .sink{ data in
                receivedViewState = data
                expectation.fulfill()
            }

        wait(for: [expectation], timeout: 1.0)

        // then
        XCTAssertEqual(receivedViewState, expectedViewSate)
        cancellable.cancel()
    }

    func test_검색했을때_검색데이터가_있다면_검색결과를_전체_업데이트() throws {
        // given
        let searchData: [RepositoryData] = [.mock]
        let expectedSearchResult: SearchResult = SearchResult(repositoryData: [RepositoryData.mock.id], type: .all)

        searchRepoUseCase.stubbedRepoDataListResult = Just(searchData)
            .setFailureType(to: SearchError.self)
            .eraseToAnyPublisher()
        let query = "test"

        // when
        viewModel.search(for: query, mode: .search)
        let expectation = XCTestExpectation(description: "Fetch repo data")
        var receivedSearchResult: SearchResult?

        let cancellable = viewModel.searchResultSubject
            .sink{ data in
                receivedSearchResult = data
                expectation.fulfill()
            }

        wait(for: [expectation], timeout: 1.0)

        // then
        XCTAssertEqual(receivedSearchResult?.repositoryData, expectedSearchResult.repositoryData)
        XCTAssertEqual(receivedSearchResult?.type, expectedSearchResult.type)
        cancellable.cancel()
    }

    func test_검색했을때_검색데이터가_있다면_검색결과를_표시() throws {
        // given
        let searchData: [RepositoryData] = [.mock]
        let expectedViewSate: SearchResultViewState = .showResult

        searchRepoUseCase.stubbedRepoDataListResult = Just(searchData)
            .setFailureType(to: SearchError.self)
            .eraseToAnyPublisher()
        let query = "test"

        // when
        viewModel.search(for: query, mode: .search)
        let expectation = XCTestExpectation(description: "Fetch repo data")
        var receivedViewState: SearchResultViewState?

        let cancellable = viewModel.$searchResultViewState
            .dropFirst()
            .sink{ data in
                receivedViewState = data
                expectation.fulfill()
            }

        wait(for: [expectation], timeout: 1.0)

        // then
        XCTAssertEqual(receivedViewState, expectedViewSate)
        cancellable.cancel()
    }

    func test_검색했을때_검색쿼리가_없다면_초기_검색화면을_표시() throws {
        // given
        let query = ""

        // when & then
        viewModel.search(for: query, mode: .search)

        let cancellable = viewModel.$searchResultViewState
            .dropFirst()
            .sink{ data in
                XCTFail("viewSate가 다른 상태로 바뀌면 실패: \(data)")
            }

        cancellable.cancel()
    }

    func test_검색했을때_오류가_발생한다면_오류를_표시() throws {
        // given
        let error: SearchError = .underlyingError(nil)
        let expectedViewSate: SearchResultViewState = .networkError(error.errorMessage)

        searchRepoUseCase.stubbedRepoDataListResult = Fail(error: error)
            .eraseToAnyPublisher()
        let query = "test"

        // when & then
        let expectation = XCTestExpectation(description: "Fetch repo data")
        viewModel.search(for: query, mode: .search)

        let cancellable1 = viewModel.showErrorToastSubject
            .sink{ data in
                expectation.fulfill()
            }

        let cancellable2 = viewModel.$searchResultViewState
            .dropFirst()
            .sink{ data in
                XCTAssertEqual(data, expectedViewSate)
                expectation.fulfill()
            }

        wait(for: [expectation], timeout: 1.0)

        cancellable1.cancel()
        cancellable2.cancel()
    }

    func test_검색중에_새로운_검색_요청은_무시() throws {
        // given
        let expectedSearchCount = 1

        searchRepoUseCase.stubbedRepoDataListResult = Just([])
            .setFailureType(to: SearchError.self)
            .eraseToAnyPublisher()
        let query1 = "test1"
        let query2 = "test2"


        // when
        viewModel.search(for: query1, mode: .search)
        viewModel.search(for: query2, mode: .search)

        // then
        XCTAssertEqual(searchRepoUseCase.repoDataListCallCount, expectedSearchCount)
    }

    // MARK: 페이징 기능

    func test_페이징했을때_검색데이터가_있다면_검색결과를_이어서_업데이트() throws {
        // given
        let searchData: [RepositoryData] = [.mock]
        let expectedSearchResult: SearchResult = SearchResult(repositoryData: [RepositoryData.mock.id], type: .continuous)

        searchRepoUseCase.stubbedRepoDataListResult = Just(searchData)
            .setFailureType(to: SearchError.self)
            .eraseToAnyPublisher()

        // when
        viewModel.loadMoreRepositoryData()
        viewModel.loadMoreRepositoryData()

        let expectation = XCTestExpectation(description: "Fetch repo data")
        var receivedSearchResult: SearchResult?

        let cancellable = viewModel.searchResultSubject
            .sink{ data in
                receivedSearchResult = data
                expectation.fulfill()
            }

        wait(for: [expectation], timeout: 1.0)

        // then
        XCTAssertEqual(receivedSearchResult?.repositoryData, expectedSearchResult.repositoryData)
        XCTAssertEqual(receivedSearchResult?.type, expectedSearchResult.type)

        cancellable.cancel()
    }

    func test_페이징했을때_오류가_발생한다면_오류를_표시() throws {
        // given
        let error: SearchError = .underlyingError(nil)
        let expectedViewSate: SearchResultViewState = .networkError(error.errorMessage)

        searchRepoUseCase.stubbedRepoDataListResult = Fail(error: error)
            .eraseToAnyPublisher()

        // when & then
        let expectation = XCTestExpectation(description: "Fetch repo data")
        viewModel.loadMoreRepositoryData()

        let cancellable1 = viewModel.showErrorToastSubject
            .sink{ data in
                expectation.fulfill()
            }

        let cancellable2 = viewModel.$searchResultViewState
            .dropFirst()
            .sink{ data in
                XCTAssertEqual(data, expectedViewSate)
                expectation.fulfill()
            }

        wait(for: [expectation], timeout: 1.0)

        cancellable1.cancel()
        cancellable2.cancel()
    }

    func test_페이징중에_새로운_페이징_요청은_무시() throws {
        // given
        let expectedPagingCount = 1

        searchRepoUseCase.stubbedRepoDataListResult = Just([])
            .delay(for: 0.5, scheduler: DispatchQueue.main)
            .setFailureType(to: SearchError.self)
            .eraseToAnyPublisher()

        // when
        viewModel.loadMoreRepositoryData()
        viewModel.loadMoreRepositoryData()

        // then
        XCTAssertEqual(searchRepoUseCase.repoDataListCallCount, expectedPagingCount)
    }

    // MARK: 복합 동작

    func test_검색후_페이징한다면_페이지증가() throws {
        // given
        let expectedPagingCount = 2

        searchRepoUseCase.stubbedRepoDataListResult = Just([.mock])
            .setFailureType(to: SearchError.self)
            .eraseToAnyPublisher()
        let query = "test"

        // when
        viewModel.search(for: query, mode: .search)
        let expectation = XCTestExpectation(description: "검색 완료 대기")

        let cancellable = viewModel.$isLoading
            .dropFirst()
            .sink { [weak self] isLoading in
                if isLoading.value == false {
                    self!.viewModel.loadMoreRepositoryData()
                    expectation.fulfill()
                }
            }


        // then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(searchRepoUseCase.pageCount, expectedPagingCount)
        cancellable.cancel()
    }

    func test_페이징중_새로운_검색요청을_하면_페이지초기화() throws {
        // given
        let expectedPagingCount = 1

        searchRepoUseCase.stubbedRepoDataListResult = Just([.mock])
            .setFailureType(to: SearchError.self)
            .eraseToAnyPublisher()
        let query1 = "test1"
        let query2 = "test2"

        // when
        viewModel.search(for: query1, mode: .search)
        viewModel.loadMoreRepositoryData()
        viewModel.search(for: query2, mode: .search)

        // when
        viewModel.search(for: query1, mode: .search)
        let expectation = XCTestExpectation(description: "검색 완료 대기")
        var isLoadMoreRepositoryData = false

        let cancellable = viewModel.$isLoading
            .dropFirst()
            .sink { isLoading in
                if isLoading.value == false {
                    if !isLoadMoreRepositoryData {
                        self.viewModel.loadMoreRepositoryData()
                        isLoadMoreRepositoryData = true
                    } else {
                        self.viewModel.search(for: query2, mode: .search)
                        expectation.fulfill()
                    }
                }
            }

        // then
        XCTAssertEqual(searchRepoUseCase.pageCount, expectedPagingCount)
        cancellable.cancel()
    }

    // MARK: 즐겨찾기 변경
    func test_즐겨찾기를_변경하면_변경결과를_업데이트() throws {
        // given
        let expectedFavorite = true

        searchRepoUseCase.stubbedRepoDataListResult = Just([.mock])
            .setFailureType(to: SearchError.self)
            .eraseToAnyPublisher()

        // when
        viewModel.search(for: "test", mode: .search)

        let expectation = XCTestExpectation(description: "Favorite 변경 대기")

        let cancellable1 = viewModel.searchResultSubject
            .sink { _ in
                self.viewModel.changeFavorite(repositoryId: RepositoryData.mock.id)
            }

        let cancellable2 = viewModel.changedRepoDataSubject
            .sink { changedRepoData in
                expectation.fulfill()
            }

        // then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(viewModel.repoDataDict[RepositoryData.mock.id]?.isFavorite, expectedFavorite)
        cancellable1.cancel()
        cancellable2.cancel()
    }
}

fileprivate extension RepositoryData {
    static let mock = RepositoryData(id: 0, name: "", owner: Owner(login: "", avatarURL: ""), description: "", stargazersCount: 0, forksCount: 0, openIssuesCount: 0, isFavorite: false)
}

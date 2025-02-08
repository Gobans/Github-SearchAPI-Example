//
//  FavoriteRepoDataManager.swift
//  SearchRepositoryTests
//
//  Created by Lee Myeonghwan on 2/8/25.
//

import Foundation

import XCTest
@testable import SearchRepository
import Combine

final class FavoriteRepoDataManagerImplTests: XCTestCase {

    var userDefaults: MockUserDefaults!
    var manager: FavoriteRepoManangerImpl!

    override func setUp() {
        userDefaults = MockUserDefaults()
        manager = FavoriteRepoManangerImpl(userDefaults: userDefaults)
    }

    override func tearDown() {
      super.tearDown()
      userDefaults.clear()
    }

    private func sut() -> FavoriteRepoManangerImpl {
        FavoriteRepoManangerImpl(userDefaults: userDefaults)
    }

    func test_로컬저장소에서_데이터를_패칭() throws {
        // given
        let expectedRepoDataDict = [0 : RepositoryData.mock]
        userDefaults.set(try? JSONEncoder().encode(expectedRepoDataDict.values.map{ $0 }) , forKey: FavoriteRepoManangerImpl.Key.repositoryData)

        // when
        let receivedRepoDataDict = manager.repositoryDataDict()

        // then
        XCTAssertEqual(expectedRepoDataDict, receivedRepoDataDict)
    }

    func test_즐겨찾기를_변경했을때_즐겨찾기한_데이터는_로컬저장소에_저장() throws {
        // given
        let repositoryData: RepositoryData = .mock
        var expectedRepositoryData = repositoryData
        expectedRepositoryData.isFavorite = !repositoryData.isFavorite

        // when
        manager.change(data: repositoryData, isFavorite: true)

        var receivedRepositoryData: RepositoryData?
        if let data = userDefaults.data(forKey: FavoriteRepoManangerImpl.Key.repositoryData), let decodedData = try? JSONDecoder().decode([RepositoryData].self, from: data) {
            receivedRepositoryData = decodedData[0]
        }

        // then
        XCTAssertEqual(expectedRepositoryData, receivedRepositoryData)
    }

    func test_즐겨찾기를_변경했을때_즐겨찾기를_취소한_데이터는_로컬데이터에서_삭제() throws {
        // given
        let repositoryData: RepositoryData = .mock
        userDefaults.set(try? JSONEncoder().encode(repositoryData) , forKey: FavoriteRepoManangerImpl.Key.repositoryData)
        let expectedRepositoryData: [RepositoryData]? = []

        // when
        manager.change(data: repositoryData, isFavorite: false)

        var receivedRepositoryData: [RepositoryData]?
        if let data = userDefaults.data(forKey: FavoriteRepoManangerImpl.Key.repositoryData) {
            receivedRepositoryData = try? JSONDecoder().decode([RepositoryData].self, from: data)
        }

        // then
        XCTAssertEqual(expectedRepositoryData, receivedRepositoryData)
    }
}

fileprivate extension RepositoryData {
    static let mock = RepositoryData(id: 0, name: "", owner: Owner(login: "", avatarURL: ""), description: "", stargazersCount: 0, forksCount: 0, openIssuesCount: 0, isFavorite: false)
}

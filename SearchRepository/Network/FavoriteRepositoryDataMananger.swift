//
//  FavoriteRepository.swift
//  SearchRepository
//
//  Created by Lee Myeonghwan on 2/5/25.
//

import Foundation
import Combine

protocol FavoriteRepositoryDataMananger {
    var favoriteRepositoryData: AnyPublisher<FavoriteRepositoryData, Never> { get }
    func change(data: RepositoryData, isFavorite: Bool)
    func isFavorite(repositoryId: RepositoryData.ID) -> Bool
}

final class FavoriteRepositoryDataManangerImpl: FavoriteRepositoryDataMananger {

    private let userDefaults = UserDefaults()

    private let favoriteSubject = PassthroughSubject<FavoriteRepositoryData, Never>()

    private var favoriteRepositoryDict: [RepositoryData.ID: RepositoryData] = [:]

    private struct Key {
        static let repositoryData = "RepositoryData"
    }

    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    private var repositoryCache: [RepositoryData.ID : RepositoryData]?
    private var repositoryDict: [RepositoryData.ID : RepositoryData] {
        get {
            if let cache = repositoryCache {
                return cache
            }
            if let data = userDefaults.data(forKey: Key.repositoryData), let decodedData = try? decoder.decode([RepositoryData].self, from: data) {
                let dict = decodedData.reduce(into: [:]) { dict, repo in
                    dict[repo.id] = repo
                }
                repositoryCache = dict
                return dict
            }
            return [:]
        }
        set {
            repositoryCache = newValue
            userDefaults.set(try? encoder.encode(newValue.values.map{ $0 }) , forKey: Key.repositoryData)
        }
    }

    var favoriteRepositoryData: AnyPublisher<FavoriteRepositoryData, Never> {
        favoriteSubject.eraseToAnyPublisher()
    }

    func change(data: RepositoryData, isFavorite: Bool) {
        let favoriteRepositoryData = FavoriteRepositoryData(id: data.id, favorite: isFavorite)
        if isFavorite {
            var newData = data
            newData.isFavorite = true
            repositoryDict[newData.id] = newData
        } else {
            repositoryDict.removeValue(forKey: data.id)
        }
        favoriteSubject.send(favoriteRepositoryData)
    }

    func isFavorite(repositoryId: RepositoryData.ID) -> Bool {
        if let favorite = repositoryDict[repositoryId]?.isFavorite, favorite {
            return true
        }
        return false
    }

    func favoriteRepositoryDataList() -> [RepositoryData] {
        return []
    }
}

//
//  MyRepositoryViewModel.swift
//  SearchRepository
//
//  Created by Lee Myeonghwan on 2/6/25.
//

import Foundation
import Combine
import UIKit

final class MyRepositoryViewModel {

    private(set) var updateRepositoryDataListSubject = PassthroughSubject<[RepositoryData.ID], Never>()
    private(set) var changedRepositoryDataSubject = PassthroughSubject<RepositoryData.ID, Never>()

    private(set) var repositoryDataListDict: [RepositoryData.ID: RepositoryData] = [:]
    @Published private(set) var adData: AdData = .init(id: 0, items: [])

    private let favoriteRepositoryDataMananger: FavoriteRepositoryDataMananger
    private let router: FeatureBuilder.Router

    private var cancelBag = Set<AnyCancellable>()

    init(favoriteRepositoryDataMananger: FavoriteRepositoryDataMananger, router: FeatureBuilder.Router) {
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

    func fetchFavoriteRepositoryDataList() {
        repositoryDataListDict = favoriteRepositoryDataMananger.repositoryDataListDict()
        updateRepositoryDataListSubject.send(repositoryDataListDict.keys.map{ $0 } )
    }

    func fetchAdData() {
        adData = AdData(id: 0, items: [.red, .orange, .yellow, .green])
    }
}

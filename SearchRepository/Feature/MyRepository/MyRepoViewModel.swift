//
//  MyRepositoryViewModel.swift
//  SearchRepository
//
//  Created by Lee Myeonghwan on 2/6/25.
//

import Foundation
import Combine
import UIKit

final class MyRepoViewModel {

    private(set) var updateRepoDataListSubject = PassthroughSubject<[RepositoryData.ID], Never>()
    private(set) var changedRepoDataSubject = PassthroughSubject<RepositoryData.ID, Never>()

    private(set) var repoDataDict: [RepositoryData.ID: RepositoryData] = [:]
    @Published private(set) var adData: AdData = .init(id: 0, items: [])

    private var cancelBag = Set<AnyCancellable>()

    private let favoriteRepoDataMananger: FavoriteRepoDataMananger
    private let router: DetailPageRouter

    init(favoriteRepoDataMananger: FavoriteRepoDataMananger, router: DetailPageRouter) {
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

    func changeFavorite(repositoryId: Int) {
        if let repositoryData = repoDataDict[repositoryId] {
            let newFavorite = !repositoryData.isFavorite
            favoriteRepoDataMananger.change(data: repositoryData)
        }
    }

    func routeToDetailViewController(repositoryID: Int) {
        if let payload = repoDataDict[repositoryID] {
            router.routeToDetailPage(payload: payload)
        }
    }

    func fetchFavoriteRepositoryDataList() {
        repoDataDict = favoriteRepoDataMananger.repositoryDataDict()
        updateRepoDataListSubject.send(repoDataDict.keys.map{ $0 } )
    }

    func fetchAdData() {
        adData = AdData(id: 0, items: [.red, .orange, .yellow, .green])
    }
}

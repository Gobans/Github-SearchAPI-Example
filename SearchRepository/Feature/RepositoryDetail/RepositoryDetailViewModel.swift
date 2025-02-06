//
//  RepositoryDetailViewModel.swift
//  SearchRepository
//
//  Created by Lee Myeonghwan on 2/6/25.
//

import Foundation
import Combine

final class RepositoryDetailViewModel {

    var repositoryData: RepositoryData

    private let favoriteRepositoryDataMananger: FavoriteRepositoryDataMananger
    private(set) var favoriteChangedSubject = PassthroughSubject<Bool, Never>()

    private var cancelBag = Set<AnyCancellable>()

    init(repositoryData: RepositoryData, favoriteRepositoryDataManger: FavoriteRepositoryDataMananger) {
        self.repositoryData = repositoryData
        self.favoriteRepositoryDataMananger = favoriteRepositoryDataManger

        favoriteRepositoryDataMananger.changedRepositoryData
            .sink { [weak self] changedRepositoryData in
                if changedRepositoryData.id == self?.repositoryData.id {
                    self?.repositoryData.isFavorite = changedRepositoryData.favorite
                    self?.favoriteChangedSubject.send(changedRepositoryData.favorite)
                }
            }
            .store(in: &cancelBag)

    }

    func changeFavorite() {
        let newFavorite = !repositoryData.isFavorite
        favoriteRepositoryDataMananger.change(data: repositoryData, isFavorite: newFavorite)
    }
}

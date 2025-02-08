//
//  RepositoryDetailViewModel.swift
//  SearchRepository
//
//  Created by Lee Myeonghwan on 2/6/25.
//

import Foundation
import Combine

final class RepoDetailViewModel {

    private var cancelBag = Set<AnyCancellable>()

    var repositoryData: RepositoryData
    private let favoriteRepoDataMananger: FavoriteRepoDataMananger
    private(set) var favoriteChangedSubject = PassthroughSubject<Bool, Never>()

    init(repositoryData: RepositoryData, favoriteRepoDataMananger: FavoriteRepoDataMananger) {
        self.repositoryData = repositoryData
        self.favoriteRepoDataMananger = favoriteRepoDataMananger

        favoriteRepoDataMananger.changedRepositoryData
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
        favoriteRepoDataMananger.change(data: repositoryData, isFavorite: newFavorite)
    }
}

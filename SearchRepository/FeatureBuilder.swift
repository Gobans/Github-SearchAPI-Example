//
//  FeatureBuilder.swift
//  SearchRepository
//
//  Created by Lee Myeonghwan on 2/5/25.
//

import Foundation

final class FeatureBuilder {

    private let favoriteRepositoryDataMananger = FavoriteRepositoryDataManangerImpl()

    func buildSearchViewController() -> SearchViewController {
        let repository = RepositoryDataRemoteRepositoryImpl(favoriteRepositoryDataManager: favoriteRepositoryDataMananger)
        let useCase = SearchRepositoryDataUseCaseImpl(repository: repository)
        let viewModel = SearchViewModel(repositoryDataUseCase: useCase, favoriteRepositoryDataMananger: favoriteRepositoryDataMananger)
        let vc = SearchViewController(viewModel: viewModel)
        return vc
    }

}

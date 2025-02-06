//
//  FeatureBuilder.swift
//  SearchRepository
//
//  Created by Lee Myeonghwan on 2/5/25.
//

import UIKit

final class FeatureBuilder {

    private let favoriteRepositoryDataMananger = FavoriteRepositoryDataManangerImpl()

    final class Router {

        weak var rootVC: UIViewController? = nil

        func routeToDetailPage(payload: RepositoryData) {
            let viewModel = RepositoryDetailViewModel(repositoryData: payload)
            let vc = RepositoryDetailViewController(viewModel: viewModel)
            vc.modalPresentationStyle = .pageSheet
            rootVC?.present(vc, animated: true)
        }
    }

    func buildSearchViewController() -> SearchViewController {
        let router = Router()
        let repository = RepositoryDataRemoteRepositoryImpl(favoriteRepositoryDataManager: favoriteRepositoryDataMananger)
        let useCase = SearchRepositoryDataUseCaseImpl(repository: repository)
        let viewModel = SearchViewModel(repositoryDataUseCase: useCase, favoriteRepositoryDataMananger: favoriteRepositoryDataMananger, router: router)
        let vc = SearchViewController(viewModel: viewModel)
        router.rootVC = vc
        return vc
    }
}

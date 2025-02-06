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

        private let favoriteRepositoryDataMananger: FavoriteRepositoryDataMananger

        init(favoriteRepositoryDataMananger: FavoriteRepositoryDataMananger) {
            self.favoriteRepositoryDataMananger = favoriteRepositoryDataMananger
        }

        func routeToDetailPage(payload: RepositoryData) {
            let viewModel = RepositoryDetailViewModel(repositoryData: payload, favoriteRepositoryDataManger: favoriteRepositoryDataMananger)
            let vc = RepositoryDetailViewController(viewModel: viewModel)
            vc.modalPresentationStyle = .pageSheet
            rootVC?.present(vc, animated: true)
        }
    }

    func buildSearchViewController() -> SearchViewController {
        let router = Router(favoriteRepositoryDataMananger: favoriteRepositoryDataMananger)
        let repository = RepositoryDataRemoteRepositoryImpl(favoriteRepository: favoriteRepositoryDataMananger)
        let useCase = SearchRepositoryDataUseCaseImpl(repository: repository)
        let viewModel = SearchViewModel(repositoryDataUseCase: useCase, favoriteRepositoryDataMananger: favoriteRepositoryDataMananger, router: router)
        let vc = SearchViewController(viewModel: viewModel)
        router.rootVC = vc
        return vc
    }

    func buildMyViewController() -> MyRepositoryViewController {
        let router = Router(favoriteRepositoryDataMananger: favoriteRepositoryDataMananger)
        let viewModel = MyRepositoryViewModel(favoriteRepositoryDataMananger: favoriteRepositoryDataMananger, router: router)
        let vc = MyRepositoryViewController(viewModel: viewModel)
        router.rootVC = vc
        return vc
    }
}

//
//  FeatureBuilder.swift
//  SearchRepository
//
//  Created by Lee Myeonghwan on 2/5/25.
//

import UIKit

final class FeatureBuilder {

    private let favoriteRepoDataMananger = FavoriteRepoManangerImpl()

    final class Router {

        weak var rootVC: UIViewController? = nil

        private let favoriteRepoDataMananger: FavoriteRepoDataMananger

        init(favoriteRepoDataMananger: FavoriteRepoDataMananger) {
            self.favoriteRepoDataMananger = favoriteRepoDataMananger
        }

        func routeToDetailPage(payload: RepositoryData) {
            let viewModel = RepoDetailViewModel(repositoryData: payload, favoriteRepoDataMananger: favoriteRepoDataMananger)
            let vc = RepoDetailViewController(viewModel: viewModel)
            vc.modalPresentationStyle = .pageSheet
            rootVC?.present(vc, animated: true)
        }
    }

    func buildSearchViewController() -> SearchViewController {
        let router = Router(favoriteRepoDataMananger: favoriteRepoDataMananger)
        let repository = RepoDataRepositoryImpl(favoriteRepository: favoriteRepoDataMananger)
        let useCase = SearchRepoUseCaseImpl(repository: repository)
        let viewModel = SearchViewModel(repoUseCase: useCase, favoriteRepoDataMananger: favoriteRepoDataMananger, router: router)
        let vc = SearchViewController(viewModel: viewModel)
        router.rootVC = vc
        return vc
    }

    func buildMyViewController() -> MyRepoViewController {
        let router = Router(favoriteRepoDataMananger: favoriteRepoDataMananger)
        let viewModel = MyRepoViewModel(favoriteRepoDataMananger: favoriteRepoDataMananger, router: router)
        let vc = MyRepoViewController(viewModel: viewModel)
        router.rootVC = vc
        return vc
    }
}

//
//  MyViewController.swift
//  SearchRepository
//
//  Created by Lee Myeonghwan on 2/5/25.
//

import UIKit
import Combine

class MyRepositoryViewController: UIViewController, UISearchBarDelegate, UICollectionViewDelegate {

    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Int, RepositoryData.ID>!

    private let viewModel: MyRepositoryViewModel

    init(viewModel: MyRepositoryViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var cancelBag = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad   ()
        view.backgroundColor = .white
        title = "My"

        setupCollectionView()
        setupDataSource()

        viewModel.updateRepositoryDataListSubject
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] idList in
                self?.updateDataListSnapshot(data: idList)
            }
            .store(in: &cancelBag)

        viewModel.changedRepositoryDataSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] id in
                self?.updateFavoritedSnapshot(data: id)
            }
            .store(in: &cancelBag)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.fetchFavoriteRepositoryDataList()
    }

    private func setupCollectionView() {
        let layout = createCompositionalLayout()

        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.backgroundColor = .white
        collectionView.register(SearchResultCell.self, forCellWithReuseIdentifier: SearchResultCell.reuseIdentifier)

        view.addSubview(collectionView)
    }

    private func createCompositionalLayout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(100))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(100))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 10

        let layout = UICollectionViewCompositionalLayout(section: section)

        return layout
    }

    private func setupDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Int, RepositoryData.ID>(collectionView: collectionView) { (collectionView, indexPath, id) -> UICollectionViewCell? in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SearchResultCell.reuseIdentifier, for: indexPath)
            if let cell = cell as? SearchResultCell, let item = self.viewModel.repositoryDataListDict[id] {
                cell.configure(with: RepositorySummary(id: item.id, name: item.name, owner: item.owner, description: item.description, stargazersCount: item.stargazersCount, isFavorite: item.isFavorite))
                cell.favoriteButtonTapped = { [weak self] repositoryId in
                    self?.viewModel.changeFavorite(repositoryId: repositoryId)
                }
            }
            return cell
        }
    }


    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let id = dataSource.itemIdentifier(for: indexPath) else { return }
        viewModel.routeToDetailViewController(repositoryID: id)
    }

    private func updateDataListSnapshot(data: [RepositoryData.ID]) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, RepositoryData.ID>()
        snapshot.appendSections([0])
        snapshot.appendItems(data)
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    private func updateFavoritedSnapshot(data: RepositoryData.ID) {
        var snapshot = dataSource.snapshot()
        snapshot.reconfigureItems([data])
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}

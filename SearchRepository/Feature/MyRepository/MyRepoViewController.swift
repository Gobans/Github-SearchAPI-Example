//
//  MyViewController.swift
//  SearchRepository
//
//  Created by Lee Myeonghwan on 2/5/25.
//

import UIKit
import Combine

class MyRepoViewController: UIViewController, UISearchBarDelegate, UICollectionViewDelegate {

    enum Section: Int, CaseIterable {
        case ad
        case repository
    }

    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Section, RepositoryData.ID>!

    private let viewModel: MyRepoViewModel

    init(viewModel: MyRepoViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var cancelBag = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "My"

        setupCollectionView()
        setupDataSource()

        viewModel.updateRepoDataListSubject
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] idList in
                self?.updateDataListSnapshot(data: idList)
            }
            .store(in: &cancelBag)

        viewModel.changedRepoDataSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] id in
                self?.updateFavoritedSnapshot(data: id)
            }
            .store(in: &cancelBag)

        viewModel.$adData
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] adData in
                self?.updateAdSnapshot(data: adData.id)
            }
            .store(in: &cancelBag)

        viewModel.fetchAdData()
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
        collectionView.register(AdCell.self, forCellWithReuseIdentifier: AdCell.reuseIdentifier)
        collectionView.register(MyRepoHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: MyRepoHeaderView.reuseIdentifier)


        view.addSubview(collectionView)
    }

    private func createCompositionalLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { (sectionIndex, _) -> NSCollectionLayoutSection? in
            if sectionIndex == 0 {
                return self.createAdSectionLayout()
            } else {
                return self.createRepositorySectionLayout()
            }
        }
    }

    private func createAdSectionLayout() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(100))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(100))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .paging
        section.interGroupSpacing = 10

        return section
    }

    private func createRepositorySectionLayout() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(100))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(100))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 10

        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(44))
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )

        section.boundarySupplementaryItems = [header]

        return section
    }

    private func setupDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Section, RepositoryData.ID>(collectionView: collectionView) { (collectionView, indexPath, id) -> UICollectionViewCell? in
            let section = Section.allCases[indexPath.section]
            switch section {
            case .ad:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AdCell.reuseIdentifier, for: indexPath)
                if let cell = cell as? AdCell {
                    cell.configure(with: self.viewModel.adData)
                }
                return cell

            case .repository:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SearchResultCell.reuseIdentifier, for: indexPath)
                if let cell = cell as? SearchResultCell, let item = self.viewModel.repoDataDict[id] {
                    cell.configure(with: RepositorySummary(id: item.id, name: item.name, owner: item.owner, description: item.description, stargazersCount: item.stargazersCount, isFavorite: item.isFavorite))
                    cell.favoriteButtonTapped = { [weak self] repositoryId in
                        self?.viewModel.changeFavorite(repositoryId: repositoryId)
                    }
                }
                return cell
            }
        }

        dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
            guard kind == UICollectionView.elementKindSectionHeader else { return nil }

            let section = Section.allCases[indexPath.section]
            if section == .repository {
                let headerView = collectionView.dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier: MyRepoHeaderView.reuseIdentifier,
                    for: indexPath
                ) as? MyRepoHeaderView
                return headerView
            }
            return nil
        }
        var snapshot = NSDiffableDataSourceSnapshot<Section, RepositoryData.ID>()
        snapshot.appendSections([.ad, .repository])
        dataSource.apply(snapshot, animatingDifferences: false)
    }


    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let id = dataSource.itemIdentifier(for: indexPath) else { return }
        viewModel.routeToDetailViewController(repositoryID: id)
    }

    private func updateAdSnapshot(data: AdData.ID) {
        var snapshot = dataSource.snapshot()
        snapshot.deleteItems(snapshot.itemIdentifiers(inSection: .ad))
        snapshot.appendItems([data], toSection: .ad)
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    private func updateDataListSnapshot(data: [RepositoryData.ID]) {
        var snapshot = dataSource.snapshot()
        snapshot.deleteItems(snapshot.itemIdentifiers(inSection: .repository))
        snapshot.appendItems(data, toSection: .repository)
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    private func updateFavoritedSnapshot(data: RepositoryData.ID) {
        var snapshot = dataSource.snapshot()
        snapshot.reconfigureItems([data])
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}

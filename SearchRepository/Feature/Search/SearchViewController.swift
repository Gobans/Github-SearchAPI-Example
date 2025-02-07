//
//  SearchViewController.swift
//  SearchRepository
//
//  Created by Lee Myeonghwan on 2/5/25.
//

import UIKit
import Combine

class SearchViewController: UIViewController, UISearchBarDelegate, UICollectionViewDelegate {

    private let stateView: StateView = {
        let view = StateView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()
    private let searchBar = UISearchBar()
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Int, RepositoryData.ID>!
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let refreshControl = UIRefreshControl()
    
    private let viewModel: SearchViewModel
    
    init(viewModel: SearchViewModel) {
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
        title = "Search"

        setupSearchBar()
        setupCollectionView()
        setupActivityIndicator()
        setupDataSource()
        setupStateView()

        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isSearchLoading in
                if isSearchLoading.value, isSearchLoading.mode == .search {
                    self?.activityIndicator.startAnimating()
                } else {
                    self?.activityIndicator.stopAnimating()
                }
            }
            .store(in: &cancelBag)
        
        viewModel.$searchResult
            .receive(on: DispatchQueue.main)
            .sink { [weak self] searchResult in
                self?.updateSearchResultSnapshot(data: searchResult.repositoryData, type: searchResult.type)
                self?.updateViewState(searchResult.type)
            }
            .store(in: &cancelBag)
        
        viewModel.changedRepositoryDataSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] id in
                self?.updateFavoritedSnapshot(data: id)
            }
            .store(in: &cancelBag)
    }
    
    private func setupStateView() {
        view.addSubview(stateView)
        NSLayoutConstraint.activate([
            stateView.topAnchor.constraint(equalTo: view.topAnchor),
            stateView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stateView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    private func setupSearchBar() {
        searchBar.delegate = self
        searchBar.placeholder = "Search..."
        searchBar.enablesReturnKeyAutomatically = false
        navigationItem.titleView = searchBar
    }
    
    private func setupCollectionView() {
        let layout = createCompositionalLayout()
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.backgroundColor = .white
        collectionView.register(SearchResultCell.self, forCellWithReuseIdentifier: SearchResultCell.reuseIdentifier)
        
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        collectionView.refreshControl = refreshControl
        
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
    
    private func setupActivityIndicator() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
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
        var snapshot = NSDiffableDataSourceSnapshot<Int, RepositoryData.ID>()
        snapshot.appendSections([0])
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard viewModel.searchResult.type != .initial else { return }
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.height
        
        if offsetY > contentHeight - frameHeight - 100 {
            viewModel.loadMoreIfNeeded()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        searchBar.resignFirstResponder()
        guard let id = dataSource.itemIdentifier(for: indexPath) else { return }
        viewModel.routeToDetailViewController(repositoryID: id)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        stateView.isHidden = true
        collectionView.isHidden = true
        viewModel.search(for: searchBar.text ?? "", mode: .search)
        searchBar.resignFirstResponder()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        searchBar.resignFirstResponder()
    }

    private func updateViewState(_ state: SearchResultUpdateType) {
        switch state {
        case .initial:
            stateView.image = UIImage(named: "searchInitialImage")
            stateView.text = "원하는 레포지토리를 검색해보세요!"
            stateView.isHidden = false
            collectionView.isHidden = true
        case .empty:
            stateView.image = UIImage(named: "emptySearch")
            stateView.text = "찾으시는 레포지토리가 없어요"
            stateView.isHidden = false
            collectionView.isHidden = true
        case .all, .continuous:
            stateView.isHidden = true
            collectionView.isHidden = false
        }
    }
    
    private func updateSearchResultSnapshot(data: [RepositoryData.ID], type: SearchResultUpdateType) {
        switch type {
        case .initial:
            break
        case .empty, .all:
            var snapshot = NSDiffableDataSourceSnapshot<Int, RepositoryData.ID>()
            snapshot.appendSections([0])
            snapshot.appendItems(data)
            dataSource.apply(snapshot, animatingDifferences: false)
        case .continuous:
            var snapshot = dataSource.snapshot()
            snapshot.appendItems(data)
            dataSource.apply(snapshot, animatingDifferences: true)
        }
    }
    
    private func updateFavoritedSnapshot(data: RepositoryData.ID) {
        var snapshot = dataSource.snapshot()
        snapshot.reconfigureItems([data])
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    @objc private func refreshData() {
        viewModel.refreshData() { [weak self] in
            self?.refreshControl.endRefreshing()
        }
    }
}

extension SearchViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.searchBar.resignFirstResponder()
    }
}

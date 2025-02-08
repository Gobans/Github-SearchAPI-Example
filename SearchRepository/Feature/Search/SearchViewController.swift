//
//  SearchViewController.swift
//  SearchRepository
//
//  Created by Lee Myeonghwan on 2/5/25.
//

import UIKit
import Combine
import Network

class SearchViewController: UIViewController, UISearchBarDelegate, UICollectionViewDelegate {

    private let stateView = StateView()
    private let searchBar = UISearchBar()
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Int, RepositoryData.ID>!
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let refreshControl = UIRefreshControl()
    private let offlineBanner = OfflineBannerView()

    private let networkMonitor = NWPathMonitor()
    private let queue = DispatchQueue.global(qos: .background)

    private var scrollDebounceCancellable: AnyCancellable?

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
        setupOfflineBanner()
        startNetworkMonitoring()

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

        viewModel.showErrorToastSubject
            .receive(on: DispatchQueue.main)
            .throttle(for: .seconds(3), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] errorMessage in
                let toast = ToastView(message: errorMessage)
                guard let view = self?.view else { return }
                toast.show(in: view)
            }
            .store(in: &cancelBag)


        viewModel.$searchResultViewState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] viewState in
                self?.updateViewState(viewState)
            }
            .store(in: &cancelBag)

        viewModel.searchResultSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] searchResult in
                self?.updateSearchResultSnapshot(data: searchResult.repositoryData, type: searchResult.type)
            }
            .store(in: &cancelBag)

        viewModel.changedRepoDataSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] id in
                self?.updateFavoritedSnapshot(data: id)
            }
            .store(in: &cancelBag)
    }

    private func setupStateView() {
        stateView.translatesAutoresizingMaskIntoConstraints = false
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
            if let cell = cell as? SearchResultCell, let item = self.viewModel.repoDataDict[id] {
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
        guard viewModel.searchResultViewState == .showResult else { return }
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.height

        if offsetY > contentHeight - frameHeight - 100 {
            scrollDebounceCancellable = Just(())
                .throttle(for: .seconds(1), scheduler: DispatchQueue.main, latest: true)
                .sink { [weak self] _ in
                    self?.viewModel.loadMoreRepositoryData()
                }
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

    private func updateViewState(_ state: SearchResultViewState) {
        switch state {
        case .initial:
            stateView.image = UIImage(named: "searchInitialImage")
            stateView.text = "원하는 레포지토리를 검색해보세요!"
            stateView.isHidden = false
            collectionView.isHidden = true
        case .noResult:
            stateView.image = UIImage(named: "emptySearch")
            stateView.text = "찾으시는 레포지토리가 없어요"
            stateView.isHidden = false
            collectionView.isHidden = true
        case .showResult:
            stateView.isHidden = true
            collectionView.isHidden = false
        case .networkError(let errorMessage):
            stateView.image = UIImage(named: "networkError")
            stateView.text = errorMessage
            stateView.isHidden = false
            collectionView.isHidden = true
        }
    }

    private func updateSearchResultSnapshot(data: [RepositoryData.ID], type: SearchResultUpdateType) {
        switch type {
        case .all:
            var snapshot = NSDiffableDataSourceSnapshot<Int, RepositoryData.ID>()
            snapshot.appendSections([0])
            snapshot.appendItems(data)
            dataSource.apply(snapshot, animatingDifferences: false)
            if !data.isEmpty {
                scrollToFirstItem()
            }
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

    private func scrollToFirstItem() {
        let firstIndexPath = IndexPath(item: 0, section: 0)
        collectionView.scrollToItem(at: firstIndexPath, at: .top, animated: false)
    }
}

extension SearchViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.searchBar.resignFirstResponder()
    }
}

extension SearchViewController {
    private func setupOfflineBanner() {
        guard let navigationBar = navigationController?.navigationBar else { return }

        navigationBar.addSubview(offlineBanner)
        offlineBanner.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            offlineBanner.leadingAnchor.constraint(equalTo: searchBar.leadingAnchor),
            offlineBanner.trailingAnchor.constraint(equalTo: searchBar.trailingAnchor),
            offlineBanner.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            offlineBanner.heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    private func startNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                if path.status == .satisfied {
                    self?.hideOfflineBanner()
                } else {
                    self?.showOfflineBanner()
                }
            }
        }
        networkMonitor.start(queue: queue)
    }

    private func showOfflineBanner() {
        guard offlineBanner.isHidden else { return }
        offlineBanner.isHidden = false
        offlineBanner.transform = CGAffineTransform(translationX: 0, y: -30)

        UIView.animate(withDuration: 0.5, animations: {
            self.offlineBanner.transform = .identity
        })
    }

    private func hideOfflineBanner() {
        guard !offlineBanner.isHidden else { return }

        UIView.animate(withDuration: 0.5, animations: {
            self.offlineBanner.transform = CGAffineTransform(translationX: 0, y: -30)
        }) { _ in
            self.offlineBanner.isHidden = true
        }
    }
}

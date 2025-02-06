//
//  RepositoryDetailViewController.swift
//  SearchRepository
//
//  Created by Lee Myeonghwan on 2/6/25.
//

import Combine
import UIKit

final class RepositoryDetailViewController: UIViewController {
    private let viewModel: RepositoryDetailViewModel

    init(viewModel: RepositoryDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private let userInfoView = UIView()
    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 15
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 80),
            imageView.heightAnchor.constraint(equalToConstant: 80)
        ])
        return imageView
    }()

    private let nameLabel = UILabel()
    private let ownerLabel = UILabel()
    private let favoriteButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "star"), for: .normal)
        button.setImage(UIImage(systemName: "star.fill"), for: .selected)
        return button
    }()
    private let favoriteStargazersCountLabel = UILabel()
    private let starCountLabel = UILabel()
    private let forkCountLabel = UILabel()
    private let openIssueCountLabel = UILabel()
    private let descriptionLabel = UILabel()
    private lazy var moreButton: UIButton = {
        let button = UIButton(configuration: .borderless())
        button.setTitle("더보기", for: .normal)
        button.addTarget(self, action: #selector(moreButtonTappedAction), for: .touchUpInside)
        return button
    }()

    private var didUpdateHeight = false

    private var cancelBag = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        setupUI()
        configure(with: viewModel.repositoryData)

        viewModel.favoriteChangedSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isFavorite in
                self?.favoriteButton.isSelected = isFavorite
            }
            .store(in: &cancelBag)
    }

    override func viewDidLayoutSubviews() {
        if !didUpdateHeight {
            let textHeight = descriptionLabel.intrinsicContentSize.height
            let maxTextLine = 2
            let correctionValue = 5
            let lineHeight = descriptionLabel.font.lineHeight + CGFloat(correctionValue)
            let maxTextHeight = CGFloat(maxTextLine) * lineHeight

            if textHeight > maxTextHeight {
                descriptionLabel.numberOfLines = maxTextLine
                moreButton.isHidden = false
            } else {
                descriptionLabel.numberOfLines = 0
                moreButton.isHidden = true
            }

            didUpdateHeight = true
        }
    }

    func configure(with data: RepositoryData) {
        nameLabel.text = data.name
        ownerLabel.text = data.owner.login
        descriptionLabel.text = data.description ?? "No description available"
        starCountLabel.text = "\(data.stargazersCount)"
        forkCountLabel.text = "\(data.forksCount)"
        openIssueCountLabel.text = "\(data.openIssuesCount)"
        favoriteButton.isSelected = data.isFavorite
        favoriteButton.addTarget(self, action: #selector(favoriteButtonTappedAction), for: .touchUpInside)
        favoriteStargazersCountLabel.text = String(data.stargazersCount)

        if let url = URL(string: data.owner.avatarURL) {
            loadImage(from: url)
        }
    }

    private func setupUI() {
        nameLabel.font = .boldSystemFont(ofSize: 20)
        ownerLabel.font = .systemFont(ofSize: 20, weight: .bold)
        descriptionLabel.font = .preferredFont(forTextStyle: .body)
        descriptionLabel.numberOfLines = 0
        starCountLabel.font = .systemFont(ofSize: 16)

        let favoriteStackView = UIStackView(arrangedSubviews: [favoriteButton, favoriteStargazersCountLabel])
        favoriteStackView.axis = .horizontal
        favoriteStackView.spacing = 4
        favoriteStackView.alignment = .leading

        let ownerFavoriteStackView = UIStackView(arrangedSubviews: [ownerLabel, favoriteStackView])
        ownerFavoriteStackView.axis = .vertical
        ownerFavoriteStackView.spacing = 4
        ownerFavoriteStackView.alignment = .leading

        let ownerStackView = UIStackView(arrangedSubviews: [avatarImageView, ownerFavoriteStackView])
        ownerStackView.axis = .horizontal
        ownerStackView.spacing = 8
        ownerStackView.alignment = .leading


        let repoStatStackView = UIStackView(arrangedSubviews: [
            statView(title: "Star", count: starCountLabel),
            createVerticalDivider(),
            statView(title: "Fork", count: forkCountLabel),
            createVerticalDivider(),
            statView(title: "Open Issue", count: openIssueCountLabel)
        ])
        repoStatStackView.axis = .horizontal
        repoStatStackView.alignment = .fill
        repoStatStackView.distribution = .fill
        repoStatStackView.spacing = 45
        repoStatStackView.translatesAutoresizingMaskIntoConstraints = false
        repoStatStackView.isLayoutMarginsRelativeArrangement = true
        repoStatStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 0)


        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(repoStatStackView)

        NSLayoutConstraint.activate([
            repoStatStackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            repoStatStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            repoStatStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            repoStatStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            repoStatStackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])

        let titleLabel = UILabel()
        titleLabel.text = "Description"
        titleLabel.font = .boldSystemFont(ofSize: 16)

        let descriptionContainerView = UIView()
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        moreButton.translatesAutoresizingMaskIntoConstraints = false

        descriptionContainerView.addSubview(descriptionLabel)
        descriptionContainerView.addSubview(moreButton)
        NSLayoutConstraint.activate([
            descriptionLabel.topAnchor.constraint(equalTo: descriptionContainerView.topAnchor),
            descriptionLabel.leadingAnchor.constraint(equalTo: descriptionContainerView.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: descriptionContainerView.trailingAnchor),

            moreButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 4),
            moreButton.trailingAnchor.constraint(equalTo: descriptionContainerView.trailingAnchor),
            moreButton.bottomAnchor.constraint(equalTo: descriptionContainerView.bottomAnchor)
        ])

        let descriptionStackView = UIStackView(arrangedSubviews: [titleLabel, descriptionContainerView])
        descriptionStackView.axis = .vertical
        descriptionStackView.spacing = 4
        descriptionStackView.isLayoutMarginsRelativeArrangement = true
        descriptionStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 16, leading: 0, bottom: 0, trailing: 0)

        let stackView = UIStackView(arrangedSubviews: [
            ownerStackView,
            createHorizontalDivider(),
            scrollView,
            createHorizontalDivider(),
            descriptionStackView,
            createHorizontalDivider()
        ])
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -16),
            scrollView.widthAnchor.constraint(equalTo: stackView.widthAnchor)
        ])
    }


    private func statView(title: String, count: UILabel) -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: [
            createLabel(text: title, font: .boldSystemFont(ofSize: 20), alignment: .center),
            count
        ])
        stackView.axis = .vertical
        stackView.alignment = .center
        return stackView
    }

    private func createLabel(text: String, font: UIFont, alignment: NSTextAlignment) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = font
        label.textAlignment = alignment
        return label
    }

    private func createVerticalDivider() -> UIView {
        let divider = UIView()
        divider.backgroundColor = .lightGray
        divider.layer.opacity = 0.3
        divider.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            divider.widthAnchor.constraint(equalToConstant: 1)
        ])
        return divider
    }

    private func createHorizontalDivider() -> UIView {
        let divider = UIView()
        divider.backgroundColor = .lightGray
        divider.layer.opacity = 0.3
        divider.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            divider.heightAnchor.constraint(equalToConstant: 1)
        ])
        return divider
    }

    private func loadImage(from url: URL) {
        DispatchQueue.global().async {
            if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                DispatchQueue.main.async { self.avatarImageView.image = image }
            }
        }
    }

    @objc private func favoriteButtonTappedAction() {
        viewModel.changeFavorite()
    }

    @objc private func moreButtonTappedAction() {
        moreButton.isHidden = true
        descriptionLabel.numberOfLines = 0
    }
}

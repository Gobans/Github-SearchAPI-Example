//
//  SearchResultCell.swift
//  SearchRepository
//
//  Created by Lee Myeonghwan on 2/5/25.
//

import UIKit

class SearchResultCell: UICollectionViewCell {

    static let reuseIdentifier = "SearchResultCell"

    private var repositoryId: Int = 0

    var favoriteButtonTapped: ((_ repositoryId: Int) -> Void)?
    private let nameLabel = UILabel()
    private let ownerLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let favoriteButton: UIButton = {
        let button = UIButton()
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 22)
        button.setImage(UIImage(systemName: "star")?.withConfiguration(imageConfig), for: .normal)
        button.setImage(UIImage(systemName: "star.fill")?.withConfiguration(imageConfig), for: .selected)
        button.tintColor = .black
        return button
    }()
    private let stargazersCountLabel = UILabel()
    private let avatarImageView = UIImageView()

    private let divider: UIView = {
        let view = UIView()
        view.backgroundColor = .lightGray
        view.layer.opacity = 0.3
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    func configure(with data: RepositorySummary) {
        repositoryId = data.id

        nameLabel.text = data.name
        ownerLabel.text = data.owner.login
        descriptionLabel.text = data.description ?? "No description available"
        stargazersCountLabel.text = String(data.stargazersCount)
        favoriteButton.isSelected = data.isFavorite
        favoriteButton.tintColor = favoriteButton.isSelected ? .systemYellow : .black

        avatarImageView.setImage(from: data.owner.avatarURL)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        // 스타일 설정
        nameLabel.font = UIFont.boldSystemFont(ofSize: 16)
        nameLabel.numberOfLines = 1

        ownerLabel.font = UIFont.systemFont(ofSize: 16)
        ownerLabel.numberOfLines = 1

        descriptionLabel.font = UIFont.systemFont(ofSize: 16)
        descriptionLabel.numberOfLines = 0

        favoriteButton.addTarget(self, action: #selector(favoriteButtonTappedAction), for: .touchUpInside)

        stargazersCountLabel.font = UIFont.systemFont(ofSize: 16)
        stargazersCountLabel.numberOfLines = 1
        stargazersCountLabel.translatesAutoresizingMaskIntoConstraints = false

        avatarImageView.layer.cornerRadius = 15
        avatarImageView.clipsToBounds = true
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.widthAnchor.constraint(equalToConstant: 30).isActive = true
        avatarImageView.heightAnchor.constraint(equalToConstant: 30).isActive = true

        let ownerStackView = UIStackView(arrangedSubviews: [avatarImageView, ownerLabel])
        ownerStackView.axis = .horizontal
        ownerStackView.spacing = 8

        let favoriteStackView = UIStackView(arrangedSubviews: [favoriteButton, stargazersCountLabel])
        favoriteStackView.axis = .horizontal
        favoriteStackView.spacing = 4

        let stackView = UIStackView(arrangedSubviews: [ownerStackView, nameLabel, descriptionLabel, favoriteStackView])
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.alignment = .leading
        stackView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stackView)
        stackView.addSubview(divider)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            divider.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 10),
            divider.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1),
            stargazersCountLabel.centerYAnchor.constraint(equalTo: favoriteButton.centerYAnchor)
        ])
    }

    @objc private func favoriteButtonTappedAction() {
        favoriteButtonTapped?(repositoryId)
    }
}

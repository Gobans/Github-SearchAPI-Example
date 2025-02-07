//
//  MyRepositoryHeaderView.swift
//  SearchRepository
//
//  Created by Lee Myeonghwan on 2/7/25.
//

import UIKit

class RepositoryHeaderView: UICollectionReusableView {
    static let reuseIdentifier = "RepositoryHeaderView"

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "즐겨찾기 리스트"
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.textColor = .black
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

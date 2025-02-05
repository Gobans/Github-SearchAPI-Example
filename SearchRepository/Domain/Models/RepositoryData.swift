//
//  RepositoryData.swift
//  RepositorySearch
//
//  Created by Lee Myeonghwan on 2/4/25.
//

import Foundation

struct RepositoryData: Equatable, Hashable, Identifiable, Codable {
    let id: Int
    let name: String
    let owner: Owner
    let description: String?
    let stargazersCount: Int
    let forksCount: Int
    let openIssuesCount: Int
    var isFavorite: Bool

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct Owner: Equatable, Codable {
    let login: String
    let avatarURL: String
}

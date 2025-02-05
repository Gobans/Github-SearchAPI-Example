//
//  RepositoryData.swift
//  RepositorySearch
//
//  Created by Lee Myeonghwan on 2/4/25.
//

import Foundation

struct RepositoryData: Equatable, Hashable {
    let id: Int
    let name: String
    let owner: Owner
    let description: String?
    let stargazersCount: Int
    let forksCount: Int
    let openIssuesCount: Int
}

struct Owner: Equatable, Hashable {
    let login: String
    let avatarURL: String
}

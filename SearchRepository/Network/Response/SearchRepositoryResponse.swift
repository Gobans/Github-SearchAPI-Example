//
//  RepositoryResponse.swift
//  RepositorySearch
//
//  Created by Lee Myeonghwan on 2/4/25.
//

import Foundation

struct SearchRepositoryResponse: Decodable {
    let totalCount: Int
    let incompleteResults: Bool
    let items: [RepositoryResponse]

    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case incompleteResults = "incomplete_results"
        case items
    }
}


struct RepositoryResponse: Decodable {
    let id: Int
    let name: String
    let fullName: String
    let owner: OwnerResponse
    let isPrivate: Bool
    let htmlURL: String
    let description: String?
    let fork: Bool
    let url: String
    let forksCount: Int
    let openIssuesCount: Int
    let watchersCount: Int
    let stargazersCount: Int
    let language: String?
    let topics: [String]?
    let createdAt: String
    let updatedAt: String
    let pushedAt: String
    let license: License?

    enum CodingKeys: String, CodingKey {
        case id, name, fork, url, description, language, topics, license
        case fullName = "full_name"
        case owner
        case isPrivate = "private"
        case htmlURL = "html_url"
        case forksCount = "forks_count"
        case openIssuesCount = "open_issues_count"
        case watchersCount = "watchers_count"
        case stargazersCount = "stargazers_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case pushedAt = "pushed_at"
    }
}

struct OwnerResponse: Decodable {
    let login: String
    let id: Int
    let avatarURL: String
    let htmlURL: String

    enum CodingKeys: String, CodingKey {
        case login, id
        case avatarURL = "avatar_url"
        case htmlURL = "html_url"
    }
}
struct License: Decodable {
    let key: String
    let name: String
    let url: String?
}

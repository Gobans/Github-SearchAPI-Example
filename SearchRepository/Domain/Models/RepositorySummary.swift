//
//  RepositorySummary.swift
//  RepositorySearch
//
//  Created by Lee Myeonghwan on 2/4/25.
//

import Foundation

struct RepositorySummary {
    let id: Int
    let name: String
    let owner: Owner
    let description: String?
    let stargazersCount: Int
}

//
//  SearchResult.swift
//  SearchRepository
//
//  Created by Lee Myeonghwan on 2/5/25.
//

import Foundation

struct SearchResult {
    var repositoryData: [RepositoryData.ID]
    let type: SearchResultUpdateType
}

enum SearchResultUpdateType {
    case initial
    case empty
    case all
    case continuous
}

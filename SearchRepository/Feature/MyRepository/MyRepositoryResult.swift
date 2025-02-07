//
//  MyRepositoryResult.swift
//  SearchRepository
//
//  Created by Lee Myeonghwan on 2/7/25.
//

import Foundation

struct MyRepositoryResult: Equatable {
    var repositoryData: [RepositoryData.ID]
    let type: MyRepositoryResultType
}

enum MyRepositoryResultType: Equatable {
    case empty
    case exist
}

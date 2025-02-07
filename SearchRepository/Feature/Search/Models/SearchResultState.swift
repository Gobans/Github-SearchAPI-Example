//
//  SearchResultState.swift
//  SearchRepository
//
//  Created by Lee Myeonghwan on 2/7/25.
//

import Foundation

enum SearchResultViewState: Equatable {
    case initial
    case noResult
    case showResult
    case networkError(String)
}


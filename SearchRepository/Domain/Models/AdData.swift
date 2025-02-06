//
//  AdData.swift
//  SearchRepository
//
//  Created by Lee Myeonghwan on 2/6/25.
//

import Foundation

struct AdData: Hashable, Identifiable {
    let id: Int
    let items: [AdColor]
}

enum AdColor: String, Hashable {
    case red, orange, yellow, green
}

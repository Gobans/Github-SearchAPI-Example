//
//  HTTPError.swift
//  SearchRepository
//
//  Created by Lee Myeonghwan on 2/7/25.
//

import Foundation

enum HTTPError: Error {
    case badServerResponse(statusCode: Int)

    var statusCode: Int {
        switch self {
            case .badServerResponse(statusCode: let code):
            return code
        }
    }
}

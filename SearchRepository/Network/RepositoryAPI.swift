//
//  RepositoryAPI.swift
//  RepositorySearch
//
//  Created by Lee Myeonghwan on 2/4/25.
//

import Foundation

protocol TargetType {
    func asURLRequest() -> URLRequest
}

enum RepositoryAPI: TargetType {
    case search(query: String, page: Int)

    var baseURL: URL {
        return URL(string: "https://api.github.com/")!
    }

    var path: String {
        return "search/repositories"
    }

    var method: String {
        return "GET"
    }

    func asURLRequest() -> URLRequest {
        var url = baseURL
        switch self {
        case .search(let query, let page):
            url = url.appending(queryItems: [URLQueryItem(name: "q", value: query), URLQueryItem(name: "page", value: String(page))])
        }
        url = url.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = method

        return request
    }
}

extension URL {
    func appending(queryItems: [URLQueryItem]) -> URL {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: true)
        components?.queryItems = queryItems
        return components?.url ?? self
    }
}

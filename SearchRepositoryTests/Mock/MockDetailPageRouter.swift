//
//  MockDetailPageRouter.swift
//  SearchRepositoryTests
//
//  Created by Lee Myeonghwan on 2/8/25.
//

import Foundation
@testable import SearchRepository

final class MockDetailPageRouter: DetailPageRouter {
    private(set) var didRouteToDetailPage = false
    private(set) var receivedPayload: RepositoryData?

    func routeToDetailPage(payload: RepositoryData) {
        didRouteToDetailPage = true
        receivedPayload = payload
    }
}

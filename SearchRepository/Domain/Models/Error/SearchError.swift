//
//  SearchError.swift
//  SearchRepository
//
//  Created by Lee Myeonghwan on 2/7/25.
//

import Foundation

enum SearchError: Error {
    case badServerResponse
    case tooManyRequest
    case noMorePageAvailable
    case unknown

    var errorMessage: String {
        switch self {
        case .badServerResponse:
            return "서버 에러가 발생했어요. 잠시 후 다시 시도해주세요"
        case .tooManyRequest:
            return "요청 횟수가 너무 많아요. 잠시 후 다시 시도해주세요"
        case .noMorePageAvailable:
            return "더 이상 찾을 수 있는 레포지토리가 없어요"
        case .unknown:
            return "알수없는 에러가 발생했어요"
        }
    }
}

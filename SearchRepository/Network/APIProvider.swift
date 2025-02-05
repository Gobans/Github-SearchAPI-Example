//
//  APIProvider.swift
//  RepositorySearch
//
//  Created by Lee Myeonghwan on 2/4/25.
//

import Foundation
import Combine

final class APIProvider<Target: TargetType> {

    private let decoder: JSONDecoder

    init(decoder: JSONDecoder = JSONDecoder()) {
        self.decoder = decoder
    }

    func request<Value: Decodable>(target: Target) -> AnyPublisher<Value, Error> {
        let request = target.asURLRequest()

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return data
            }
            .decode(type: Value.self, decoder: decoder)
            .eraseToAnyPublisher()
    }
}

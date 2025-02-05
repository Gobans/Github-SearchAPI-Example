//
//  MyPageRepositoryDataUseCase.swift
//  SearchRepository
//
//  Created by Lee Myeonghwan on 2/5/25.
//


protocol MyPageRepositoryDataUseCase {
    func repositoryDataList() -> [RepositoryData]
}

final class MyPageRepositoryDataUseCaseImpl: MyPageRepositoryDataUseCase {

    let repository: RepositoryDataLocalRepository

    init(repository: RepositoryDataLocalRepository) {
        self.repository = repository
    }

    func repositoryDataList() -> [RepositoryData] {
        repository.fetchRepositoryDataList()
    }
}

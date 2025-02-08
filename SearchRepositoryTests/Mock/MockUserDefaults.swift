//
//  UserDefaultsMock.swift
//  SearchRepositoryTests
//
//  Created by Lee Myeonghwan on 2/8/25.
//

import Foundation

final class MockUserDefaults: UserDefaults {

  override init?(suiteName: String?) {
    super.init(suiteName: "mock.searchRepository")
  }

  deinit {
    clear()
  }

  func clear() {
    dictionaryRepresentation().keys.forEach { key in
      self.removeObject(forKey: key)
    }
  }
}

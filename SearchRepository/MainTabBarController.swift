//
//  ViewController.swift
//  RepositorySearch
//
//  Created by Lee Myeonghwan on 2/4/25.
//

import UIKit

class MainTabBarController: UITabBarController {

    private let builder = FeatureBuilder()

    override func viewDidLoad() {
        super.viewDidLoad()

        let searchVC = UINavigationController(rootViewController: builder.buildSearchViewController())
        searchVC.tabBarItem = UITabBarItem(tabBarSystemItem: .search, tag: 0)
        searchVC.tabBarItem.title = "Search"

        let myVC = UINavigationController(rootViewController: builder.buildMyViewController())
        myVC.tabBarItem = UITabBarItem(tabBarSystemItem: .favorites, tag: 1)

        viewControllers = [searchVC, myVC]
    }
}

//
//  ViewController.swift
//  RepositorySearch
//
//  Created by Lee Myeonghwan on 2/4/25.
//

import UIKit

class MainTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let searchVC = UINavigationController(rootViewController: SearchViewController())
        searchVC.tabBarItem = UITabBarItem(tabBarSystemItem: .search, tag: 0)

        let myVC = UINavigationController(rootViewController: MyViewController())
        myVC.tabBarItem = UITabBarItem(tabBarSystemItem: .favorites, tag: 1)

        viewControllers = [searchVC, myVC]
    }
}

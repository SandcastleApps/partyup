//
//  TutorialController.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-12-13.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import UIKit

class TutorialController: UIViewController, UIPageViewControllerDataSource {

	let pageCount = 5

	override func preferredStatusBarStyle() -> UIStatusBarStyle {
		return .LightContent
	}

    override func viewDidLoad() {
        super.viewDidLoad()

		UIPageControl.appearance().pageIndicatorTintColor = UIColor.lightGrayColor()
		UIPageControl.appearance().currentPageIndicatorTintColor = UIColor.orangeColor()

		if let page = dequeTutorialPageController(0) {
			(childViewControllers.first as? UIPageViewController)?.dataSource = self
			(childViewControllers.first as? UIPageViewController)?.setViewControllers([page], direction: UIPageViewControllerNavigationDirection.Forward, animated: false, completion: nil)
		}
    }

	func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
		var newVC: UIViewController?
		if let pageVC = viewController as? TutorialPageController {
			newVC = dequeTutorialPageController(pageVC.page+1)
		}
		return newVC
	}

	func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
		var newVC: UIViewController?
		if let pageVC = viewController as? TutorialPageController {
			newVC = dequeTutorialPageController(pageVC.page-1)
		}
		return newVC
	}

	func dequeTutorialPageController(page: Int) -> UIViewController? {
		var pageVC: TutorialPageController?
		if page >= 0 && page < pageCount {
			pageVC = storyboard?.instantiateViewControllerWithIdentifier("Tutorial Page") as? TutorialPageController
			pageVC?.page = page
			pageVC?.pageCount = pageCount
		}
		return pageVC
	}

	func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
		return pageCount
	}

	func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int {
		return 0
	}
}

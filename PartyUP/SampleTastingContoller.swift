//
//  SampleTastingContoller.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-09-22.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import UIKit

class SampleTastingContoller: UIViewController, UIPageViewControllerDataSource {

	var eventIdentifier: Int = 0 {
		didSet {
			fetch(eventIdentifier) { (samples: [Sample]) in
				dispatch_async(dispatch_get_main_queue()) {self.samples = samples}
			}
		}
	}

	private var samples: [Sample]? {
		didSet {
			if let page = dequeTastePageController(0) {
				navigator?.setViewControllers([page], direction: UIPageViewControllerNavigationDirection.Forward, animated: false, completion: nil)
			}
		}
	}

	private var navigator: UIPageViewController?

	private var pages: [SampleTastePageController] = []

    override func viewDidLoad() {
        super.viewDidLoad()

		for _ in 0..<2 {
			pages.append(storyboard!.instantiateViewControllerWithIdentifier("Sample Taste Page Controller") as! SampleTastePageController)
		}
    }

	override func prefersStatusBarHidden() -> Bool {
		return true
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

	func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {

		var toVC: SampleTastePageController?

		if let fromVC = viewController as? SampleTastePageController {
			toVC = dequeTastePageController(fromVC.page + 1)
		}

		return toVC
	}

	func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
		var toVC: SampleTastePageController?

		if let fromVC = viewController as? SampleTastePageController {
			toVC = dequeTastePageController(fromVC.page - 1)
		}

		return toVC
	}

	func dequeTastePageController(page: Int) -> SampleTastePageController? {
		var pageVC: SampleTastePageController?

		if let localSamples = samples where page < localSamples.count && page >= 0 {
			pageVC = storyboard?.instantiateViewControllerWithIdentifier("Sample Taste Page Controller") as? SampleTastePageController
			pageVC?.page = page
			pageVC?.sample = localSamples[page]
		}

		return pageVC
	}


    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if let toVC = segue.destinationViewController as? UIPageViewController {
			navigator = toVC
			navigator?.dataSource = self
		}
    }


}

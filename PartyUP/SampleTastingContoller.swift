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
			fetch(eventIdentifier) { (var samples: [Sample]) in
				samples.sortInPlace{ $0.time.compare($1.time) == .OrderedDescending }
				dispatch_async(dispatch_get_main_queue()) {self.samples = samples}
			}
		}
	}

	private var samples: [Sample]? {
		didSet {
			if let page = dequeTastePageController(0) {
				navigator?.dataSource = self
				navigator?.setViewControllers([page], direction: UIPageViewControllerNavigationDirection.Forward, animated: false, completion: nil)
			} else {
				navigator?.dataSource = nil
			}
		}
	}

	private var navigator: UIPageViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
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
		}
    }


}

//
//  SampleTastingContoller.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-09-22.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import UIKit
import Flurry_iOS_SDK

class SampleTastingContoller: UIViewController, UIPageViewControllerDataSource {

	@IBOutlet weak var container: UIView!
	@IBOutlet weak var loadingProgress: UIActivityIndicatorView!

	var partyId: String? {
		didSet {
			if let party = partyId {
				fetch(party) { (let samples: [Sample]) in
					let sorted = samples.sort{ $0.time.compare($1.time) == .OrderedDescending }.filter{ abs($0.time.timeIntervalSinceNow) < NSUserDefaults.standardUserDefaults().doubleForKey(PartyUpPreferences.StaleSampleInterval)}
					dispatch_async(dispatch_get_main_queue()) {self.samples = sorted}
				}
			}
		}
	}

	private var samples: [Sample]? {
		didSet {
			loadingProgress.stopAnimating()
			
			if let page = dequeTastePageController(0) {
				navigator?.dataSource = self
				navigator?.setViewControllers([page], direction: UIPageViewControllerNavigationDirection.Forward, animated: false, completion: nil)
			}
		}
	}

	private weak var navigator: UIPageViewController?

	func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
		var toVC: UIViewController?

		if let fromVC = viewController as? PageProtocol {
			toVC = dequeTastePageController(fromVC.page + 1)
		}
		return toVC
	}

	func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
		var toVC: UIViewController?
		if let fromVC = viewController as? PageProtocol {
			toVC = dequeTastePageController(fromVC.page - 1)
		}
		return toVC
	}

	func dequeTastePageController(page: Int) -> UIViewController? {
		if page >= 0 {
			if let localSamples = samples where page < localSamples.count {
				let pageVC = storyboard?.instantiateViewControllerWithIdentifier("Sample Taste Page Controller") as? SampleTastePageController
				pageVC?.page = page
				pageVC?.sample = localSamples[page]
				return pageVC
			} else if samples?.count ?? 0 == page {
				let pageVC = storyboard?.instantiateViewControllerWithIdentifier("Recruit Page Controller") as? RecruitPageController
				pageVC?.page = page
				return pageVC
			}
		}

		return nil
	}

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if let toVC = segue.destinationViewController as? UIPageViewController {
			navigator = toVC
		}
    }
}

//
//  SampleTastingContoller.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-09-22.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import UIKit

class SampleTastingContoller: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {

	@IBOutlet weak var container: UIView!
	@IBOutlet weak var loadingProgress: UIActivityIndicatorView!
	@IBOutlet weak var nextPage: UIButton!
	@IBOutlet weak var previousPage: UIButton!

	var partyId: String? {
		didSet {
			if let party = partyId {
				fetch(party) { (let samples: [Sample]) in
                    let stale = NSUserDefaults.standardUserDefaults().doubleForKey(PartyUpPreferences.StaleSampleInterval)
                    let suppress = NSUserDefaults.standardUserDefaults().integerForKey(PartyUpPreferences.SampleSuppressionThreshold)
					let sorted = samples.sort{ $0.time.compare($1.time) == .OrderedDescending }.filter{ (abs($0.time.timeIntervalSinceNow) < stale) && ($0.rating[0] - $0.rating[1] > suppress) }
					dispatch_async(dispatch_get_main_queue()) {self.samples = sorted}
				}
			}
		}
	}

	@IBAction func flipPage(sender: UIButton) {
		if let pvc = childViewControllers.first as? UIPageViewController {
			if let index = (pvc.viewControllers?.first as? PageProtocol)?.page {
				if let page = dequeTastePageController(index + sender.tag) {
					pvc.setViewControllers([page], direction: sender.tag > 0 ? UIPageViewControllerNavigationDirection.Forward : UIPageViewControllerNavigationDirection.Reverse, animated: true, completion: nil)
					updateNavigationArrows(pvc)
				}
			}
		}
	}

	private var samples: [Sample]? {
		didSet {
			loadingProgress.stopAnimating()
			
			if let page = dequeTastePageController(0), pvc = childViewControllers.first as? UIPageViewController {
				pvc.dataSource = self
				pvc.delegate = self
				pvc.setViewControllers([page], direction: UIPageViewControllerNavigationDirection.Forward, animated: false, completion: nil)
				updateNavigationArrows(pvc)
			}
		}
	}

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

	func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
		if completed {
			updateNavigationArrows(pageViewController)
		}
	}

	func updateNavigationArrows(pageViewController: UIPageViewController)
	{
		if let index = (pageViewController.viewControllers?.first as? PageProtocol)?.page {
			let prev = !(index > 0)
			let next = !(index < samples?.count)

			if prev != previousPage.hidden {
				UIView.animateWithDuration(0.5, animations: { self.previousPage.transform = prev ? CGAffineTransformMakeScale(0.1, 0.1) : CGAffineTransformIdentity }, completion: { (done) in self.previousPage.hidden = prev })
			}

			if next != nextPage.hidden {
				UIView.animateWithDuration(0.5, animations: { self.nextPage.transform = next ? CGAffineTransformMakeScale(0.1, 0.1) : CGAffineTransformIdentity }, completion: { (done) in self.nextPage.hidden = next })
			}
		}
	}
}

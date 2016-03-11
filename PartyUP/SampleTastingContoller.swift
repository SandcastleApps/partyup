//
//  SampleTastingContoller.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-09-22.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import UIKit

class SampleTastingContoller: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    private enum PageContent {
        case Video(Sample)
        case Ad(Advertisement)
        case Recruit
    }
    
    private var pages = [PageContent]()

	@IBOutlet weak var container: UIView!
	@IBOutlet weak var loadingProgress: UIActivityIndicatorView!
	@IBOutlet weak var nextPage: UIButton!
	@IBOutlet weak var previousPage: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

		NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("sieveOffensiveSamples"), name: Defensive.OffensiveMuteUpdateNotification, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("sieveOffensiveSamples"), name: Sample.FlaggedUpdateNotification, object: nil)

//		if let avc = childViewControllers.dropFirst().first as? AdvertisingOverlayController {
//			avc.url = NSURL(fileURLWithPath: "/Users/fritz/Documents/color_box.html")//NSURL(string: "color_box.html", relativeToURL: NSURL(string: "https://s3.amazonaws.com/com.sandcastleapps.partyup/ads/"))
//		}
    }

	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
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

	var venues: [Venue]? {
		didSet {
			let notify = NSNotificationCenter.defaultCenter()
			let stale = NSUserDefaults.standardUserDefaults().doubleForKey(PartyUpPreferences.StaleSampleInterval)
			let suppress = NSUserDefaults.standardUserDefaults().integerForKey(PartyUpPreferences.SampleSuppressionThreshold)
			if let venues = venues {
				for venue in venues {
					observations.insert(venue)
					notify.addObserver(self, selector: Selector("sampleFetchObserver:"), name: Venue.VitalityUpdateNotification, object: venue)
					venue.fetchSamples(withStaleInterval: stale, andSuppression: suppress)
				}
			}
		}
	}
    
    var ads: [Advertisement] = [] {
        didSet {
            for ad in ads {
                for page in ad.pages {
                    switch ad.style {
                    case .Page:
                        adPages[page] = ad
                    case .Overlay:
                        adOvers[page] = ad
                    }
                }
            }
        }
    }
    private var adPages = [Int:Advertisement]()
    private var adOvers = [Int:Advertisement]()
    
    private var samples = [Sample]()
	private var observations = Set<Venue>()

	func sampleFetchObserver(note: NSNotification) {
		if let venue = note.object as? Venue {
			if observations.remove(venue) != nil, let local = venue.samples {
				samples.appendContentsOf(local)
				if observations.isEmpty {
					samples.sortInPlace { $0.time.compare($1.time) == .OrderedDescending }
					updateSampleDisplay()
				}
			}
		}
	}
    
    private func updateSampleDisplay() {
        loadingProgress?.stopAnimating()
        
        pages = samples.map { .Video($0) }
        adPages.forEach { page, ad in self.pages.insert(.Ad(ad), atIndex: page) }
        
        if let page = dequeTastePageController(0), pvc = childViewControllers.first as? UIPageViewController {
            pvc.dataSource = self
            pvc.delegate = self
            pvc.setViewControllers([page], direction: .Forward, animated: false) { completed in if completed { self.updateNavigationArrows(pvc) } }
        }
    }

	func sieveOffensiveSamples() {
		let filtered = samples.filter { !Defensive.shared.muted($0.user) && !($0.flag ?? false) }
		if filtered.count != samples.count {
			samples = filtered
		}

		if let pvc = childViewControllers.first as? UIPageViewController, visible = pvc.viewControllers?.first as? SampleTastePageController {
			let index = samples.indexOf{ $0.time.compare(visible.sample.time) == .OrderedAscending }
			if let toVC = dequeTastePageController(index ?? samples.count) {
				pvc.setViewControllers([toVC], direction: .Forward, animated: true) { completed in if completed { self.updateNavigationArrows(pvc) } }
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
			if page < samples.count {
				let pageVC = storyboard?.instantiateViewControllerWithIdentifier("Sample Taste Page Controller") as? SampleTastePageController
				pageVC?.page = page
				pageVC?.sample = samples[page]
				return pageVC
			} else if samples.count == page {
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
			let next = !(index < samples.count)

			if prev != previousPage.hidden {
				UIView.animateWithDuration(0.5, animations: { self.previousPage.transform = prev ? CGAffineTransformMakeScale(0.1, 0.1) : CGAffineTransformIdentity }, completion: { (done) in self.previousPage.hidden = prev })
			}

			if next != nextPage.hidden {
				UIView.animateWithDuration(0.5, animations: { self.nextPage.transform = next ? CGAffineTransformMakeScale(0.1, 0.1) : CGAffineTransformIdentity }, completion: { (done) in self.nextPage.hidden = next })
			}
		}
	}
}

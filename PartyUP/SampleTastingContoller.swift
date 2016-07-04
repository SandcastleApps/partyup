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
        case Video(Tastable)
        case Ad(Advertisement)
        case Recruit
    }
    
    private var pages = [PageContent]()

	@IBOutlet weak var container: UIView!
	@IBOutlet weak var loadingProgress: UIActivityIndicatorView!
	@IBOutlet weak var nextPage: UIButton!
	@IBOutlet weak var previousPage: UIButton!
    private var navigationArrowsVisible: Bool = { return NSUserDefaults.standardUserDefaults().boolForKey(PartyUpPreferences.FeedNavigationArrows) }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

		if venues != nil && observations.isEmpty {
			updateSampleDisplay()
		}

		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SampleTastingContoller.sieveOffensiveSamples), name: Defensive.OffensiveMuteUpdateNotification, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SampleTastingContoller.sieveOffensiveSamples), name: Sample.FlaggedUpdateNotification, object: nil)
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
					notify.addObserver(self, selector: #selector(SampleTastingContoller.sampleFetchObserver(_:)), name: Venue.VitalityUpdateNotification, object: venue)
					venue.fetchSamples(withStaleInterval: stale, andSuppression: suppress, andTimeliness: 60)
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
    
    private var samples = [Tastable]()
	private var observations = Set<Venue>()

	func sampleFetchObserver(note: NSNotification) {
		if let venue = note.object as? Venue {
			if observations.remove(venue) != nil, let local = venue.treats {
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
        adPages.forEach { page, ad in self.pages.insert(.Ad(ad), atIndex: min(page, self.pages.count)) }
		pages.append(.Recruit)
        
        if let page = dequeTastePageController(0), pvc = childViewControllers.first as? UIPageViewController {
            pvc.dataSource = self
            pvc.delegate = self
            pvc.setViewControllers([page], direction: .Forward, animated: false) { completed in if completed { self.updateNavigationArrows(pvc) } }
        }
    }

	func sieveOffensiveSamples() {
        let filtered = pages.filter {
            if case .Video(let treat) = $0, let sample = treat as? Votable {
                return !Defensive.shared.muted(sample.user) && !(sample.flag ?? false)
            } else {
                return true
            }
        }
        
		if filtered.count != pages.count {
			pages = filtered
		}

		if let pvc = childViewControllers.first as? UIPageViewController, visible = pvc.viewControllers?.first as? SampleTastePageController {
            let index = pages.indexOf {
                if case .Video(let sample) = $0 {
                    return sample.time.compare(visible.sample.time) == .OrderedAscending
                } else {
                    return false
                }
            }
			if let toVC = dequeTastePageController(index ?? pages.count - 1) {
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
		if page >= 0 && page < pages.count {
			let over = adOvers[page].flatMap { NSURL(string: $0.media, relativeToURL: PartyUpConstants.AdvertisementDistribution) }

			switch pages[page] {
			case .Video(let sample):
				let pageVC = storyboard?.instantiateViewControllerWithIdentifier("Sample Taste Page Controller") as? SampleTastePageController
				pageVC?.page = page
				pageVC?.sample = sample
				pageVC?.ad = over
				return pageVC
			case .Ad(let ad):
				let pageVC = storyboard?.instantiateViewControllerWithIdentifier("Advertising Page Controller") as? AdvertisingOverlayController
				pageVC?.page = page
				pageVC?.url = NSURL(string: ad.media, relativeToURL: PartyUpConstants.AdvertisementDistribution)
				return pageVC
			case .Recruit:
				let pageVC = storyboard?.instantiateViewControllerWithIdentifier("Recruit Page Controller") as? RecruitPageController
				pageVC?.page = page
				pageVC?.ad = over
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
		if navigationArrowsVisible, let index = (pageViewController.viewControllers?.first as? PageProtocol)?.page {
			let prev = !(index > 0)
			let next = !(index < pages.count - 1)

			if prev != previousPage.hidden {
				UIView.animateWithDuration(0.5, animations: { self.previousPage.transform = prev ? CGAffineTransformMakeScale(0.1, 0.1) : CGAffineTransformIdentity }, completion: { (done) in self.previousPage.hidden = prev })
			}

			if next != nextPage.hidden {
				UIView.animateWithDuration(0.5, animations: { self.nextPage.transform = next ? CGAffineTransformMakeScale(0.1, 0.1) : CGAffineTransformIdentity }, completion: { (done) in self.nextPage.hidden = next })
			}
		}
	}
}

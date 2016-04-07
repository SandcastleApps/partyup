//
//  TutorialOverlayManager.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2016-04-06.
//  Copyright © 2016 Sandcastle Application Development. All rights reserved.
//
import Instructions
import Foundation

class TutorialOverlayManager: CoachMarksControllerDataSource, CoachMarksControllerDelegate {
	typealias TutorialMark = (identifier: Int, hint: String)

	var marks: [TutorialMark]? {
		didSet {
			if let marks = marks where !marks.isEmpty{
				if let seen = defaults.arrayForKey(PartyUpPreferences.TutorialViewed) as? [Int] {
					unseen = marks.filter { !seen.contains($0.identifier) }
				}
			} else {
				unseen.removeAll()
			}
		}
	}

	private(set) lazy var coach: CoachMarksController = {
		let coach = CoachMarksController()
		coach.dataSource = self
		coach.delegate = self
		coach.allowOverlayTap = true
		coach.overlayBackgroundColor = UIColor.grayColor().colorWithAlphaComponent(0.4)
		let skip = CoachMarkSkipDefaultView()
		skip.setTitle(NSLocalizedString("Skip coaching for this screen", comment: "Tutorial skip button label"), forState: .Normal)
		coach.skipView = skip
		return coach
	}()

	private let defaults = NSUserDefaults.standardUserDefaults()
	private var unseen = [TutorialMark]()
	private weak var parent: UIView?

	func start(target: UIViewController) {
		if !unseen.isEmpty {
			coach.startOn(target)
			parent = target.view
		}
	}

	func numberOfCoachMarksForCoachMarksController(coachMarksController: CoachMarksController) -> Int {
		return unseen.count
	}

	func coachMarksController(coachMarksController: CoachMarksController, coachMarksForIndex index: Int) -> CoachMark {
		return coachMarksController.coachMarkForView(UIApplication.sharedApplication().keyWindow?.viewWithTag(unseen[index].identifier))
	}

	func coachMarksController(coachMarksController: CoachMarksController, coachMarkViewsForIndex index: Int, coachMark: CoachMark) -> (bodyView: CoachMarkBodyView, arrowView: CoachMarkArrowView?) {
		let hint = NSLocalizedString(unseen[index].hint, comment: "Tutorial Mark \(unseen[index].identifier)")
		var coachViews = coachMarksController.defaultCoachViewsWithArrow(true, arrowOrientation: coachMark.arrowOrientation, hintText: hint, nextText: nil)
		if unseen[index].identifier < 0 {
			coachViews.arrowView = nil
			coachViews.bodyView.center = parent.flatMap { CGPointMake($0.bounds.width/2,$0.bounds.height/2) } ?? CGPointZero
//			var constraints = [NSLayoutConstraint]()
//			constraints.append(NSLayoutConstraint(item: coachViews.bodyView, attribute: .CenterXWithinMargins, relatedBy: .Equal, toItem: parent, attribute: .CenterX, multiplier: 1.0, constant: 0))
//			constraints.append(NSLayoutConstraint(item: coachViews.bodyView, attribute: .CenterYWithinMargins, relatedBy: .Equal, toItem: parent, attribute: .CenterY, multiplier: 1.0, constant: 0))
//			coachViews.bodyView.addConstraints(constraints)
		}
		return (bodyView: coachViews.bodyView, arrowView: coachViews.arrowView)
	}

	func didFinishShowingFromCoachMarksController(coachMarksController: CoachMarksController) {
		if var seen = defaults.arrayForKey(PartyUpPreferences.TutorialViewed) as? [Int] {
			seen.appendContentsOf(unseen.map { $0.identifier})
			defaults.setObject(seen, forKey: PartyUpPreferences.TutorialViewed)
			parent = nil
		}
	}

	func coachMarksController(coachMarksController: CoachMarksController, constraintsForSkipView skipView: UIView, inParentView parentView: UIView) -> [NSLayoutConstraint]? {

		var constraints: [NSLayoutConstraint] = []

		constraints.append(NSLayoutConstraint(item: skipView, attribute: .CenterXWithinMargins, relatedBy: .Equal, toItem: parentView, attribute: .CenterX, multiplier: 1.0, constant: 0))
		constraints.append(NSLayoutConstraint(item: skipView, attribute: .CenterYWithinMargins, relatedBy: .Equal, toItem: parentView, attribute: .CenterY, multiplier: 1.75, constant: 0))

		return constraints
	}
}

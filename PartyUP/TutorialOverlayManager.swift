//
//  TutorialOverlayManager.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2016-04-06.
//  Copyright © 2016 Sandcastle Application Development. All rights reserved.
//
import Instructions
import Foundation

struct TutorialMark {
	let identifier: Int
	let hint: String
	var view: UIView?

	init(identifier: Int, hint: String, view: UIView? = nil){
		self.identifier = identifier
		self.hint = hint
		self.view = view
	}
}

class TutorialOverlayManager: CoachMarksControllerDataSource, CoachMarksControllerDelegate {

	var marks: [TutorialMark]? {
		didSet {
			filterMarks()
		}
	}

	var tutoring: Bool {
		get {
			return coach.flatMap { $0.started } ?? false
		}
	}

	private var coach: CoachMarksController?

	private let skip: CoachMarkSkipDefaultView = {
		let skip = CoachMarkSkipDefaultView()
		skip.setTitle(NSLocalizedString("Skip", comment: "Tutorial skip button label"), forState: .Normal)
		return skip
	}()

	private let defaults = NSUserDefaults.standardUserDefaults()
	private var unseen = [TutorialMark]()
	private weak var target: UIViewController?

	init(marks: [TutorialMark]) {
		self.marks = marks
		filterMarks()
	}

	private func filterMarks() {
		if let marks = marks where !marks.isEmpty{
			if let seen = defaults.arrayForKey(PartyUpPreferences.TutorialViewed) as? [Int] {
				unseen = marks.filter { !seen.contains($0.identifier) }
			}
		} else {
			unseen.removeAll()
		}
	}

	private func create() -> CoachMarksController {
		let coach = CoachMarksController()
		coach.dataSource = self
		coach.delegate = self
		coach.allowOverlayTap = true
		coach.overlayBackgroundColor = UIColor.darkGrayColor().colorWithAlphaComponent(0.4)
		return coach
	}

	func start(target: UIViewController) {
		if !unseen.isEmpty {
			coach = create()
			coach?.skipView = unseen.count > 1 ? skip : nil
			coach?.startOn(target)
			self.target = target

			target.navigationController?.view.userInteractionEnabled = false
			target.view?.userInteractionEnabled = false
		}
	}

	func stop() {
		coach?.stop()
	}

	func pause() {
		coach?.pause()
	}

	func resume() {
		coach?.resume()
	}

	func numberOfCoachMarksForCoachMarksController(coachMarksController: CoachMarksController) -> Int {
		return unseen.count
	}

	func coachMarksController(coachMarksController: CoachMarksController, coachMarksForIndex index: Int) -> CoachMark {
		if unseen[index].view == nil {
			unseen[index].view = UIApplication.sharedApplication().keyWindow?.viewWithTag(unseen[index].identifier)
		}
		return coachMarksController.coachMarkForView(unseen[index].view)
	}

	func coachMarksController(coachMarksController: CoachMarksController, coachMarkViewsForIndex index: Int, coachMark: CoachMark) -> (bodyView: CoachMarkBodyView, arrowView: CoachMarkArrowView?) {
		let hint = NSLocalizedString(unseen[index].hint, comment: "Tutorial Mark \(unseen[index].identifier)")
		var coachViews = coachMarksController.defaultCoachViewsWithArrow(true, arrowOrientation: coachMark.arrowOrientation, hintText: hint, nextText: nil)
		coachViews.bodyView.hintLabel.textAlignment = .Center
		if unseen[index].identifier < 0 {
			coachViews.arrowView = nil
		}
		return (bodyView: coachViews.bodyView, arrowView: coachViews.arrowView)
	}

	func didFinishShowingFromCoachMarksController(coachMarksController: CoachMarksController) {
		if var seen = defaults.arrayForKey(PartyUpPreferences.TutorialViewed) as? [Int] {
			seen.appendContentsOf(unseen.map { $0.identifier})
			defaults.setObject(seen, forKey: PartyUpPreferences.TutorialViewed)
		}

		target?.navigationController?.view.userInteractionEnabled = true
		target?.view?.userInteractionEnabled = true
		unseen.removeAll()
		coach = nil
	}

	func coachMarksController(coachMarksController: CoachMarksController, constraintsForSkipView skipView: UIView, inParentView parentView: UIView) -> [NSLayoutConstraint]? {

		var constraints: [NSLayoutConstraint] = []

		constraints.append(NSLayoutConstraint(item: skipView, attribute: .CenterXWithinMargins, relatedBy: .Equal, toItem: parentView, attribute: .CenterX, multiplier: 1.0, constant: 0))
		constraints.append(NSLayoutConstraint(item: skipView, attribute: .CenterYWithinMargins, relatedBy: .Equal, toItem: parentView, attribute: .CenterY, multiplier: 1.75, constant: 0))

		return constraints
	}
}

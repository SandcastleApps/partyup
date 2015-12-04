//
//  AcknowledgementsController.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-12-03.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import UIKit

class AcknowledgementsController: UITableViewController {

	private var expanded = Set<NSIndexPath>()

	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		if indexPath.section == 2 {
			if expanded.contains(indexPath) {
				expanded.remove(indexPath)
			} else {
				expanded.insert(indexPath)
			}

			tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
		}
	}
}

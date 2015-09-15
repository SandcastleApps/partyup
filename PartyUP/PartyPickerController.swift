//
//  PartyPickerController.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-09-15.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import UIKit
import AWSDynamoDB

class PartyPickerController: UITableViewController {

	private var parties: [Party] = [] {
		didSet {
			partyTable.reloadData()
			self.refreshControl?.endRefreshing()
		}
	}

	@IBOutlet var partyTable: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

		fetchPartyList()
    }

	@IBAction func refreshParties() {
		fetchPartyList()
	}

	func fetchPartyList() {
		AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper().scan(Party.self, expression: AWSDynamoDBScanExpression()).continueWithBlock { (task) in
			if let error = task.error {
				NSLog("Scan Error: \(error.description)")
			}

			if let except = task.exception {
				NSLog("Scan Exception: \(except.description)")
			}

			if let result = task.result as? AWSDynamoDBPaginatedOutput {
				var parties: [Party] = []
				if let items = result.items as? [Party] {
					parties = items.sort { $0.startTime!.doubleValue < $1.startTime!.doubleValue }
				}
				dispatch_async(dispatch_get_main_queue()) { self.parties = parties }
			}

			return nil
		}
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return parties.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PartyPooper", forIndexPath: indexPath)

        cell.textLabel?.text = parties[indexPath.row].name
		cell.detailTextLabel?.text = parties[indexPath.row].details

        return cell
	}



    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

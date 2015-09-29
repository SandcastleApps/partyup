//
//  SampleManager.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-09-28.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import Foundation
import AWSS3
import AWSDynamoDB
import AWSCore

class SampleManager
{
	enum SampleManagerError: ErrorType
	{
		case TransferUtilityUnavailable
		case InvalidFileName(url: NSURL)
	}

	typealias SampleSubmission = (sample:Sample, event:Int)
	private var queue = [(SampleSubmission)]()
	private var active: SampleSubmission?

	func submit(sample: Sample, event: Int) {
		queue.append((sample, event))
		if active == nil {
			process(nil)
		}
	}

	private func process(completedTask: AWSTask?) {
		if let task = completedTask {
			if let error = task.error {
				NSLog("Sample Manager: \(error)")
			}

			if let exception = task.exception {
				NSLog("Sample Manager: \(exception)")
			}
		}

		active = nil

		if queue.count > 0 {
			active = queue.removeFirst()

			do {
				try upload(active!)
			} catch SampleManagerError.TransferUtilityUnavailable {
				NSLog("Sample Manager: Transfer Utility is Unavailable")
			} catch SampleManagerError.InvalidFileName {
				NSLog("Sample Manager: Invalid Filename Provided")
			} catch {
				NSLog("Sample Manager: Shit Hit The Fan")
			}
			
		}



	}

	func upload(submission: SampleSubmission) throws {
		guard let transfer = AWSS3TransferUtility.defaultS3TransferUtility() else { throw SampleManagerError.TransferUtilityUnavailable }

		guard let videoFile = submission.sample.media.path else { throw SampleManagerError.InvalidFileName(url: submission.sample.media) }

		let videoUrl = NSURL(fileURLWithPath: NSTemporaryDirectory() + videoFile)

		transfer.uploadFile(videoUrl,
			bucket: PartyUpConstants.StorageBucket,
			key: PartyUpConstants.StorageKeyPrefix + videoFile,
			contentType: videoUrl.mime,
			expression: nil,
			completionHander: nil).continueWithSuccessBlock({ (task) in
				return push(submission.sample, key: submission.event) }).continueWithBlock({ (task) in
					try! NSFileManager.defaultManager().removeItemAtURL(videoUrl)

					dispatch_async(dispatch_get_main_queue()) { self.process(task) }

					return nil
				})
	}
}
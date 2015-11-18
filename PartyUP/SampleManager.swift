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
		case SubmissionError(error: NSError)
		case SubmissionException(exception: NSException)
	}

	typealias SampleSubmission = (sample: Sample, event: String, completion: (ErrorType?)->Void)
	private var queue = [(SampleSubmission)]()
	private var active: SampleSubmission?

	private static let sharedManager = SampleManager()

	static func defaultManager() -> SampleManager {
		return sharedManager
	}

	func submit(sample: Sample, event: String, completion: (ErrorType?)->Void) {
		queue.append((sample, event, completion))
		if active == nil {
			process(nil)
		}
	}

	private func process(completedTask: AWSTask?) {
		if let task = completedTask {
			var err: SampleManagerError?

			if let error = task.error {
				NSLog("Sample Manager: \(error)")
				err = SampleManagerError.SubmissionError(error: error)
			}

			if let exception = task.exception {
				NSLog("Sample Manager: \(exception)")
				err = SampleManagerError.SubmissionException(exception: exception)
			}

			active?.completion(err)
		}

		active = nil

		if queue.count > 0 {
			active = queue.removeFirst()

			do {
				try upload(active!)
			} catch SampleManagerError.TransferUtilityUnavailable {
				NSLog("Sample Manager: Transfer Utility is Unavailable")
				active?.completion(SampleManagerError.TransferUtilityUnavailable)
			} catch SampleManagerError.InvalidFileName(let url) {
				NSLog("Sample Manager: Invalid Filename Provided")
				active?.completion(SampleManagerError.InvalidFileName(url: url))
			} catch {
				NSLog("Sample Manager: Shit Hit The Fan")
			}
			
		}
	}

	private func upload(submission: SampleSubmission) throws {
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
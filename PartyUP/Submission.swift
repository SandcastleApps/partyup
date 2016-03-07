//
//  Submission.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-09-28.
//  Copyright © 2015 Sandcastle Application Development. All rights reserved.
//

import Foundation
import AWSS3
import AWSDynamoDB
import AWSCore

class Submission
{
    let sample: Sample
    lazy var name: String? = { return self.sample.media.path.flatMap({String($0.characters.dropFirst())}) }()
    lazy var file: NSURL? = { return self.name.flatMap({NSURL(fileURLWithPath: NSTemporaryDirectory() + $0)}) }()

	var error: Error?

	typealias CompletionHandler = (Submission)->Void
    
    init(sample: Sample) {
        self.sample = sample
    }

	deinit {
		let _ = file.flatMap{ try? NSFileManager.defaultManager().removeItemAtURL($0) }
	}
    
	func submitWithCompletionHander(handler: CompletionHandler) {
		complete = handler

		do {
			switch state {
			case .Idle:
				try upload()
			case .Upload(let task):
				if task.faulted {
					try upload()
				} else {
					record()
				}
			case .Record(let task):
				if task.faulted {
					record()
				}
			}
		} catch let bad as Error {
			error = bad
			dispatch_async(dispatch_get_main_queue()) { self.complete?(self) }
		} catch {
//			error = SubmissionError.UnknownError
			dispatch_async(dispatch_get_main_queue()) { self.complete?(self) }
		}
    }

	private func upload() throws {
		error = nil

		guard let transfer = AWSS3TransferUtility.defaultS3TransferUtility() else { throw Error.TransferUtilityUnavailable }
		guard let url = file else { throw Error.InvalidFileName(url: sample.media) }
		guard let name = name else { throw Error.InvalidFileName(url: sample.media) }

        let uploadExpr = AWSS3TransferUtilityUploadExpression()
        uploadExpr.setValue("REDUCED_REDUNDANCY", forRequestParameter: "x-amz-storage-class")
        
        let task = transfer.uploadFile(url,
            bucket: PartyUpConstants.StorageBucket,
            key: name,
            contentType: url.mime,
            expression: uploadExpr,
			completionHander: nil).continueWithBlock { task in
			if task.faulted {
				if let err = task.error { self.error = .UploadError(error: err) }
				if let exc = task.exception { self.error = .UploadException(exception: exc) }
				dispatch_async(dispatch_get_main_queue()) { self.complete?(self) }
			} else {
				self.record()
			}

			return nil
		}
        state = .Upload(task: task)
    }
    
    private func record() {
		error = nil

        let task = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper().save(sample.dynamo).continueWithBlock { task in
			if let err = task.error { self.error = .RecordError(error: err) }
			if let exc = task.exception { self.error = .RecordException(exception: exc) }
			dispatch_async(dispatch_get_main_queue()) { self.complete?(self) }

			return nil
		}
		state = .Record(task: task)
    }

    enum Error: ErrorType {
        case UnknownError
        case TransferUtilityUnavailable
        case InvalidFileName(url: NSURL)
        case UploadError(error: NSError)
        case UploadException(exception: NSException)
        case RecordError(error: NSError)
        case RecordException(exception: NSException)
    }
    
    private enum State {
        case Idle
        case Upload(task: AWSTask)
        case Record(task: AWSTask)
    }

	private var complete: CompletionHandler?
    private var state: State = .Idle
}

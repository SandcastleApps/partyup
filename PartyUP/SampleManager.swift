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

class SampleSubmission
{
    let sample: Sample
    lazy var name: String? = { return self.sample.media.path.flatMap({String($0.characters.dropFirst())}) }()
    lazy var file: NSURL? = { return self.name.flatMap({NSURL(fileURLWithPath: NSTemporaryDirectory() + $0)}) }()

	typealias CompletionHandler = (SubmissionError?)->Void
    
    init(sample: Sample) throws {
        self.sample = sample
    }

	deinit {
		if let file = file {
			try! NSFileManager.defaultManager().removeItemAtURL(file)
		}
	}
    
	func submitWithCompletionHander(handler: CompletionHandler) throws {
		complete = handler
		try step()
    }

	private func step() throws {
		switch state {
		case .Idle:
			try upload()
		case .Upload(let task):
			if task.faulted || task.cancelled {
				try upload()
			} else {
				try record()
			}
		case .Record(let task):
			if task.faulted {
				try record()
			}
		}
	}

	private func back() {
//		switch state {
//		case .Idle:
//			break
//		case .Upload(let task):
//			if task.faulted {
//				step()
//			}
//		case .Record(let task):
//
//		}
	}

	private func upload() throws {
		guard let transfer = AWSS3TransferUtility.defaultS3TransferUtility() else { throw SubmissionError.TransferUtilityUnavailable }
		guard let url = file else { throw SubmissionError.InvalidFileName(url: sample.media) }
		guard let name = name else { throw SubmissionError.InvalidFileName(url: sample.media) }

        let uploadExpr = AWSS3TransferUtilityUploadExpression()
        uploadExpr.setValue("REDUCED_REDUNDANCY", forRequestParameter: "x-amz-storage-class")
        
        let task = transfer.uploadFile(url,
            bucket: PartyUpConstants.StorageBucket,
            key: name,
            contentType: url.mime,
            expression: uploadExpr,
			completionHander: nil).continueWithBlock { _ in self.back(); return nil }
        state = .Upload(task: task)
    }
    
    private func record() throws {
        let task = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper().save(sample.dynamo).continueWithBlock { _ in
			self.back(); return nil }
		state = .Record(task: task)
    }

    enum SubmissionError: ErrorType {
        case TransferUtilityUnavailable
        case InvalidFileName(url: NSURL)
        case SubmissionError(error: NSError)
        case SubmissionException(exception: NSException)
    }
    
    private enum SubmissionState {
        case Idle
        case Upload(task: AWSTask)
        case Record(task: AWSTask)
    }

	private var complete: CompletionHandler?
    private var state: SubmissionState = .Idle
}

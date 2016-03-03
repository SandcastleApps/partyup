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
    
    init(sample: Sample) throws {
        self.sample = sample
    }
    
    func process() throws {
        switch state {
        case .Idle:
            try upload()
        case .Upload(let task):
            if task.faulted {
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
    
    private func upload() throws {
        guard let transfer = AWSS3TransferUtility.defaultS3TransferUtility() else { throw SubmissionError.TransferUtilityUnavailable }
        guard let videoUrl = file else { throw SubmissionError.InvalidFileName(url: sample.media) }
        guard let videoName = name else { throw SubmissionError.InvalidFileName(url: sample.media) }
        
        let uploadExpr = AWSS3TransferUtilityUploadExpression()
        uploadExpr.setValue("REDUCED_REDUNDANCY", forRequestParameter: "x-amz-storage-class")
        
        let task = transfer.uploadFile(videoUrl,
            bucket: PartyUpConstants.StorageBucket,
            key: videoName,
            contentType: videoUrl.mime,
            expression: uploadExpr,
            completionHander: nil).continueWithBlock { _ in self.process() }
        state = .Upload(task: task)
    }
    
    private func record() throws {
        state = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper().save(sample.dynamo)})
        state.continueWithBlock({ (task) in
            dispatch_async(dispatch_get_main_queue()) { self.process(task) }
            return nil
        })
    }

    enum SubmissionError: ErrorType
    {
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
    
    private var state: SubmissionState = .Idle
}

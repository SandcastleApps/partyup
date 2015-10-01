//
//  VideoRecordController.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-09-06.
//  Copyright © 2015 Sancastle Application Development. All rights reserved.
//

import UIKit
import AVFoundation

protocol VideoRecorderDelegate
{
	var targetUrl: NSURL { get }

	func beganRecording()
	func endedRecording(error: ErrorType?)

	func deviceError(error: ErrorType)
}

class VideoRecordController: UIViewController {
	
	private let feedSession = AVCaptureSession()
	private var videoInput: AVCaptureDeviceInput? = nil
	private var audioInput: AVCaptureDeviceInput? = nil
	private var movieOutput = AVCaptureMovieFileOutput()
	
	private var previewLayer: AVCaptureVideoPreviewLayer! = nil
	private let sessionQueue = dispatch_queue_create("capture", DISPATCH_QUEUE_SERIAL)

	var delegate: VideoRecorderDelegate?

	@IBOutlet weak var movieView: UIView!
	
	override func viewDidLoad() {
		super.viewDidLoad()

		feedSession.sessionPreset = AVCaptureSessionPresetMedium

		previewLayer = AVCaptureVideoPreviewLayer(session: feedSession)
		previewLayer.frame = movieView.bounds
		movieView.layer.addSublayer(previewLayer)

		dispatch_async(sessionQueue) { [unowned self] in

			do {
				if let videoDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo) {
					self.videoInput = try AVCaptureDeviceInput(device: videoDevice)

					if self.feedSession.canAddInput(self.videoInput){
						self.feedSession.addInput(self.videoInput)
					}

					let audioDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeAudio)
					self.audioInput = try AVCaptureDeviceInput(device: audioDevice)

					if self.feedSession.canAddInput(self.audioInput) {
						self.feedSession.addInput(self.audioInput)
					}

					if self.feedSession.canAddOutput(self.movieOutput){
						self.feedSession.addOutput(self.movieOutput)
					}

					self.feedSession.startRunning()
				} else {
					throw NSError(domain: "Video Recorder", code: 0, userInfo: nil)
				}
			} catch {
				dispatch_async(dispatch_get_main_queue()) { self.delegate?.deviceError(error) }
			}
		}

		NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("orientationChangeNotification"), name: UIDeviceOrientationDidChangeNotification, object: nil)
		UIDevice.currentDevice().beginGeneratingDeviceOrientationNotifications()
	}

	override func prefersStatusBarHidden() -> Bool {
		return true
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		previewLayer.frame = movieView.bounds
	}

	func orientationChangeNotification() {
		var avOrientation = AVCaptureVideoOrientation.Portrait

		switch(UIDevice.currentDevice().orientation){
		case .Portrait:
			avOrientation = .Portrait
		case .PortraitUpsideDown:
			avOrientation = .PortraitUpsideDown
		case .LandscapeLeft:
			avOrientation = .LandscapeRight
		case .LandscapeRight:
			avOrientation = .LandscapeLeft
		default:
			avOrientation = .Portrait
		}

		previewLayer.connection.videoOrientation = avOrientation
		movieOutput.connectionWithMediaType(AVMediaTypeVideo).videoOrientation = avOrientation
	}

	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		dispatch_async(sessionQueue) { self.feedSession.stopRunning() }
	}
	
	func start() {
		if let target = delegate?.targetUrl {
			movieOutput.startRecordingToOutputFileURL(target, recordingDelegate: self)
		}
	}

	func stop() {
		movieOutput.stopRecording()
	}
}

extension VideoRecordController: AVCaptureFileOutputRecordingDelegate {
	
	func captureOutput(captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAtURL fileURL: NSURL!, fromConnections connections: [AnyObject]!) {
		dispatch_async(dispatch_get_main_queue()) { self.delegate?.beganRecording() }
	}
	
	func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError?) {
		dispatch_async(dispatch_get_main_queue()) { self.delegate?.endedRecording(error) }
	}
}


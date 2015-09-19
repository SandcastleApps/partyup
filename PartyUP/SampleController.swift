//
//  SamplingController.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2015-09-06.
//  Copyright © 2015 Sancastle Application Development. All rights reserved.
//

import UIKit
import AVFoundation

class SamplingController: UIViewController {

	var recordingFile: NSURL?
	var comment: String?
	
	private let feedSession = AVCaptureSession()
	private var videoInput: AVCaptureDeviceInput? = nil
	private var audioInput: AVCaptureDeviceInput? = nil
	private var movieOutput = AVCaptureMovieFileOutput()
	
	private var previewLayer: AVCaptureVideoPreviewLayer! = nil
	private let sessionQueue = dispatch_queue_create("capture", DISPATCH_QUEUE_SERIAL)
	
	@IBOutlet weak var movieView: UIView!
	@IBOutlet weak var cancelMovie: UIButton!
	@IBOutlet weak var acceptMovie: UIButton!
	@IBOutlet weak var recordMovie: UIButton!
	
	override func viewDidLoad() {
		super.viewDidLoad()

		feedSession.sessionPreset = AVCaptureSessionPresetMedium

		previewLayer = AVCaptureVideoPreviewLayer(session: feedSession)
		previewLayer.frame = movieView.bounds
		movieView.layer.addSublayer(previewLayer)

		dispatch_async(sessionQueue) { [unowned self] in
			if let videoDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo) {
				self.videoInput = try! AVCaptureDeviceInput(device: videoDevice)

				if self.feedSession.canAddInput(self.videoInput){
					self.feedSession.addInput(self.videoInput)
				}

				let audioDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeAudio)
				self.audioInput = try! AVCaptureDeviceInput(device: audioDevice)

				if self.feedSession.canAddInput(self.audioInput) {
					self.feedSession.addInput(self.audioInput)
				}

				if self.feedSession.canAddOutput(self.movieOutput){
					self.feedSession.addOutput(self.movieOutput)
				}

				self.feedSession.startRunning()

				dispatch_async(dispatch_get_main_queue()) { self.recordMovie.enabled = true }
			} else {
				dispatch_async(dispatch_get_main_queue()) { UIAlertView(title: "No Video Device", message: "No point recording", delegate: nil, cancelButtonTitle: "Shit!").show(); self.comment = "well done" }

				try! "We're off to see the wizard \(self.recordingFile)".writeToFile(self.recordingFile!.path!, atomically: false, encoding: NSUTF8StringEncoding)
			}
		}

		NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("observeOrientationChange"), name: UIDeviceOrientationDidChangeNotification, object: nil)
		UIDevice.currentDevice().beginGeneratingDeviceOrientationNotifications()
	}

	override func prefersStatusBarHidden() -> Bool {
		return true
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		previewLayer.frame = movieView.bounds
	}

	func observeOrientationChange() {
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
	
	@IBAction func beginRecord(sender: UIButton) {

		if let recording = recordingFile {
			movieOutput.startRecordingToOutputFileURL(recording, recordingDelegate: self)

			cancelMovie.enabled = false
			acceptMovie.enabled = false
		} else {
			UIAlertView(title: "No Output File", message: "Recording would be pointless", delegate: nil, cancelButtonTitle: "Shit").show()
		}
	}
	
	@IBAction func endRecord() {
		movieOutput.stopRecording()
		cancelMovie.enabled = true
	}
	
	@IBAction func accept(sender: UIButton) {
		sender.enabled = false
	}
}

extension SamplingController: AVCaptureFileOutputRecordingDelegate {
	
	func captureOutput(captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAtURL fileURL: NSURL!, fromConnections connections: [AnyObject]!) {
	}
	
	func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {
		dispatch_async(dispatch_get_main_queue()) { self.acceptMovie.enabled = (error == nil) }
	}
}


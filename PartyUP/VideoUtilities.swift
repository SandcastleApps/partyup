//
//  VideoUtilities.swift
//  PartyUP
//
//  Created by Fritz Vander Heide on 2016-05-01.
//  Copyright © 2016 Sandcastle Application Development. All rights reserved.
//

import AVFoundation

typealias VideoEffectApplicator = (AVMutableVideoComposition) -> Void
typealias VideoExportCompletion = (AVAssetExportSessionStatus) -> Void

func applyToVideo(fromInput input: NSURL, toOutput output: NSURL, effectApplicator effect: VideoEffectApplicator, exportCompletionHander exportHandler: VideoExportCompletion) -> AVAssetExportSession? {
    var export: AVAssetExportSession?
	let asset = AVAsset(URL: input)
	let composition = AVMutableComposition()
	let video = composition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)
	let audio = composition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: kCMPersistentTrackID_Invalid)

	do {
		if let videoAssetTrack = asset.tracksWithMediaType(AVMediaTypeVideo).first, audioAssetTrack = asset.tracksWithMediaType(AVMediaTypeAudio).first
		{
			try video.insertTimeRange(CMTimeRangeMake(kCMTimeZero, asset.duration), ofTrack: videoAssetTrack, atTime: kCMTimeZero)
			try audio.insertTimeRange(CMTimeRangeMake(kCMTimeZero, asset.duration), ofTrack: audioAssetTrack, atTime: kCMTimeZero)

			let videoInstruction = AVMutableVideoCompositionInstruction()
			videoInstruction
			videoInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration)

			let videoComposition = AVMutableVideoComposition()

			videoComposition.renderSize = videoAssetTrack.naturalSize
			videoComposition.instructions = [videoInstruction]
			videoComposition.frameDuration = CMTimeMake(1, 30)
            
            let track = composition.tracksWithMediaType(AVMediaTypeVideo).first!
			let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
			layerInstruction.setTransform(track.preferredTransform, atTime: kCMTimeZero)
            videoInstruction.layerInstructions = [layerInstruction]
            videoComposition.instructions = [videoInstruction]

			effect(videoComposition)

            export = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetMediumQuality)
			if let export = export {
				export.outputURL = output
				export.outputFileType = AVFileTypeQuickTimeMovie
				export.shouldOptimizeForNetworkUse = true
				export.videoComposition = videoComposition

				export.exportAsynchronouslyWithCompletionHandler({
					dispatch_async(dispatch_get_main_queue(),{
						exportHandler(export.status)
					})
				})
			}
		}
	} catch {
        export = nil
	}
    
    return export
}
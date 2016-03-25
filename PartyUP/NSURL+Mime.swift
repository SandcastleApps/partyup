//
//  NSURL+Mime.swift
//  MediaMonkey
//
//  Created by Fritz Vander Heide on 2015-09-07.
//  Copyright © 2015 AppleTrek. All rights reserved.
//

import Foundation
import MobileCoreServices

extension NSURL
{
	var mime: String {
		get{
			var mime: String = "application/octet-stream"
			if let ext = self.pathExtension {
				if let cfUti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, ext, nil) {
					if let cfMime = UTTypeCopyPreferredTagWithClass(cfUti.takeRetainedValue() as String, kUTTagClassMIMEType) {
						mime = cfMime.takeRetainedValue() as String
					}
				}
			}
			
			return mime
		}
	}
}

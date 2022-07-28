//
//  XCTTemporaryFile.swift
//
//  Copyright © 2022 Darren Ford. All rights reserved.
//
//  MIT license
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
//  documentation files (the "Software"), to deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
//  permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial
//  portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
//  WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS
//  OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
//  OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import XCTest
import Foundation

/// A temporary file class that removes the temporary file when it goes out of scope
class XCTTemporaryFile: CustomDebugStringConvertible {

	let fileURL: URL

	var debugDescription: String { "\(self.fileURL)" }

	init(_ filename: String, contents: Data? = nil) throws {
		// create the temporary file url
		let tempURL = try FileManager.default.url(
			for: .itemReplacementDirectory,
			in: .userDomainMask,
			appropriateFor: URL(fileURLWithPath: NSTemporaryDirectory()),
			create: true
		)
			.appendingPathComponent(filename)

		// if contents were specified, write the file with the contents
		if let contents = contents {
			try contents.write(to: tempURL, options: .atomicWrite)
		}

		self.fileURL = tempURL
	}

	init(prefix: String? = nil, fileExtension: String? = nil, contents: Data? = nil) throws {
		var tempFilename = ""

		// prefix
		if let prefix = prefix {
			tempFilename += prefix + "_"
		}

		// unique name
		tempFilename += ProcessInfo.processInfo.globallyUniqueString

		// extension
		if let fileExtension = fileExtension {
			tempFilename += "." + fileExtension
		}

		// create the temporary file url
		let tempURL = try FileManager.default.url(
			for: .itemReplacementDirectory,
			in: .userDomainMask,
			appropriateFor: URL(fileURLWithPath: NSTemporaryDirectory()),
			create: true
		)
			.appendingPathComponent(tempFilename)

		// if contents were specified, write the file with the contents
		if let contents = contents {
			try contents.write(to: tempURL, options: .atomicWrite)
		}

		self.fileURL = tempURL
	}

	func remove() throws {
		try FileManager.default.removeItem(at: fileURL)
	}

	deinit {
		try? remove()
	}
}

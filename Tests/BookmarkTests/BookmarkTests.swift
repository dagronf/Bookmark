//
//  BookmarkTests.swift
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
@testable import Bookmark

import UniformTypeIdentifiers

final class BookmarkTests: XCTestCase {

	func testBasicFunctionality() throws {

		// Create a file to bookmark
		let linkedFile = try XCTTemporaryFile("book.txt", contents: "This is a test".data(using: .utf8))

		let bookmark = try XCTUnwrap(try Bookmark(targetFileURL: linkedFile.fileURL))

		let targetResult = try bookmark.targetURL()
		XCTAssertEqual(targetResult.state, .valid)
		XCTAssertEqual(linkedFile.fileURL.standardizedFileURL, targetResult.url.standardizedFileURL)

		// Create a bookmark file
		let bookmarkFile = try XCTTemporaryFile("bookmark", contents: bookmark.bookmarkData)
		XCTAssertTrue(FileManager.default.fileExists(atPath: bookmarkFile.fileURL.path))

		// Load the bookmark from the bookmark file
		let bookmarkData = try XCTUnwrap(Data(contentsOf: bookmarkFile.fileURL))
		let wBookmark = try XCTUnwrap(Bookmark(bookmarkData: bookmarkData))
		let wTargetResult = try wBookmark.targetURL()
		XCTAssertEqual(wTargetResult.state, .valid)
		XCTAssertEqual(linkedFile.fileURL.standardizedFileURL, wTargetResult.url.standardizedFileURL)
	}

	func testRenameFunctionality() throws {
		// Create a file to bookmark
		let originalData = "This is a test".data(using: .utf8)
		let originalFile = try XCTTemporaryFile("book.txt", contents: originalData)
		let originalURL = originalFile.fileURL.standardizedFileURL
		let originalBookmark = try XCTUnwrap(try Bookmark(targetFileURL: originalURL))

		let targetResult = try originalBookmark.targetURL()
		XCTAssertEqual(targetResult.state, .valid)
		XCTAssertEqual(originalURL, targetResult.url.standardizedFileURL)

		// Move the file to a new name
		var movedURL = originalURL
		movedURL = movedURL.deletingLastPathComponent().appendingPathComponent("renamed-book.txt")
		try FileManager.default.moveItem(at: originalURL, to: movedURL)

		// The bookmark should automatically point to the new location, but the bookmark will be marked as stale
		let targetResult2 = try originalBookmark.targetURL()
		XCTAssertEqual(targetResult2.state, .stale)
		let bookmarkForMovedURL = targetResult2.url.standardizedFileURL
		XCTAssertEqual(bookmarkForMovedURL, movedURL)

		// Check that the data at the bookmark url matches the original data
		let state = try originalBookmark.usingTargetURL { url in
			let standardized = url.standardizedFileURL
			let movedData = try? Data(contentsOf: standardized)
			XCTAssertEqual(originalData, movedData)
		}
		XCTAssertEqual(state.bookmarkState, .stale)

		// Delete the moved file
		try FileManager.default.removeItem(at: movedURL)

		// The bookmark should now be invalid
		XCTAssertEqual(originalBookmark.state, .invalid)
		XCTAssertThrowsError(try originalBookmark.targetURL())
	}

	func testWriteAliasFile() throws {
		let originalData = "This is a test".data(using: .utf8)
		let originalFile = try XCTTemporaryFile("book.txt", contents: originalData)
		let originalURL = originalFile.fileURL.standardizedFileURL
		let originalBookmark = try XCTUnwrap(try Bookmark(targetFileURL: originalURL))
		let originalResult = try originalBookmark.targetURL()
		XCTAssertEqual(originalResult.state, .valid)
		XCTAssertEqual(originalURL, originalResult.url.standardizedFileURL)

		// Check that the string uti for the 'target' url
		XCTAssertEqual("public.plain-text", try originalBookmark.utiStringForTargetURL())
		// Check that the uti for the 'target' url
		XCTAssertEqual(UTType.plainText, try originalBookmark.utiForTargetURL())

		// Write an alias file to disk
		let aliasFile = try XCTTemporaryFile("book.txt alias")
		try originalBookmark.writeAliasFile(to: aliasFile.fileURL, options: .minimalBookmark)
		XCTAssertTrue(FileManager.default.isReadableFile(atPath: aliasFile.fileURL.path))

		let typeID = try? aliasFile.fileURL.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier
		XCTAssertEqual("com.apple.alias-file", typeID)
	}

	func testSecurityState() throws {

		do {
			let originalData = "This is a test".data(using: .utf8)
			let originalFile = try XCTTemporaryFile("book.txt", contents: originalData)
			let originalURL = originalFile.fileURL.standardizedFileURL
			let originalBookmark = try XCTUnwrap(try Bookmark(targetFileURL: originalURL))
			let originalResult = try originalBookmark.targetURL()
			XCTAssertEqual(originalResult.state, .valid)
			XCTAssertEqual(originalURL, originalResult.url.standardizedFileURL)

			let state = try originalBookmark.usingTargetURL() { url in
				XCTAssertEqual(originalURL, url.standardizedFileURL)
			}
			XCTAssertEqual(state.bookmarkState, .valid)
		}

		#if os(macOS)
		do {
			let originalData = "This is a test".data(using: .utf8)
			let originalFile = try XCTTemporaryFile("book.txt", contents: originalData)
			let originalURL = originalFile.fileURL.standardizedFileURL
			let originalBookmark = try XCTUnwrap(try Bookmark(targetFileURL: originalURL, options: .withSecurityScope))
			let originalResult = try originalBookmark.targetURL()
			XCTAssertEqual(originalURL, originalResult.url.standardizedFileURL)

			let state = try originalBookmark.usingTargetURL(options: .withSecurityScope) { url in
				XCTAssertEqual(originalURL, url.standardizedFileURL)
			}
			XCTAssertEqual(state.bookmarkState, .valid)
		}
		#endif
	}
}

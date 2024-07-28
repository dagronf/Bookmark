//
//  BookmarkTests.swift
//
//  Copyright © 2024 Darren Ford. All rights reserved.
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

#if compiler(>=5.3)
import UniformTypeIdentifiers
#endif

final class BookmarkTests: XCTestCase {

	func testBasicFunctionality() throws {

		// Create a file to bookmark
		let linkedFile = try XCTTemporaryFile("book.txt", contents: "This is a test".data(using: .utf8))

		let bookmark = try Bookmark(targetFileURL: linkedFile.fileURL)

		let targetResult = try bookmark.resolved()
		XCTAssertEqual(targetResult.state, .valid)
		XCTAssertEqual(linkedFile.fileURL.standardizedFileURL, targetResult.url.standardizedFileURL)

		// Create a bookmark file
		let bookmarkFile = try XCTTemporaryFile("bookmark", contents: bookmark.bookmarkData)
		XCTAssertTrue(FileManager.default.fileExists(atPath: bookmarkFile.fileURL.path))

		// Load the bookmark from the bookmark file
		let bookmarkData = try Data(contentsOf: bookmarkFile.fileURL)
		let wBookmark = try Bookmark(bookmarkData: bookmarkData)
		let wTargetResult = try wBookmark.resolved()
		XCTAssertEqual(wTargetResult.state, .valid)
		XCTAssertEqual(linkedFile.fileURL.standardizedFileURL, wTargetResult.url.standardizedFileURL)
	}

	func testRenameFunctionality() throws {
		// Create a file to bookmark
		let originalData = "This is a test".data(using: .utf8)
		let originalFile = try XCTTemporaryFile("book.txt", contents: originalData)
		let originalURL = originalFile.fileURL.standardizedFileURL
		let originalBookmark = try Bookmark(targetFileURL: originalURL)

		let targetResult = try originalBookmark.resolved()
		XCTAssertEqual(targetResult.state, .valid)
		XCTAssertEqual(originalURL, targetResult.url.standardizedFileURL)

		// Move the file to a new name
		var movedURL = originalURL
		movedURL = movedURL.deletingLastPathComponent().appendingPathComponent("renamed-book.txt")
		try FileManager.default.moveItem(at: originalURL, to: movedURL)

		// The bookmark should automatically point to the new location, but the bookmark will be marked as stale
		let targetResult2 = try originalBookmark.resolved()
		XCTAssertEqual(targetResult2.state, .stale)
		let bookmarkForMovedURL = targetResult2.url.standardizedFileURL
		XCTAssertEqual(bookmarkForMovedURL, movedURL)

		// Check that the data at the bookmark url matches the original data
		try originalBookmark.resolving { bookmark in
			XCTAssertEqual(bookmark.state, .stale)
			let standardized = bookmark.url.standardizedFileURL
			let movedData = try? Data(contentsOf: standardized)
			XCTAssertEqual(originalData, movedData)
		}

		// Delete the moved file
		try FileManager.default.removeItem(at: movedURL)

		// The bookmark should now be invalid
		XCTAssertEqual(originalBookmark.state, .invalid)
		XCTAssertThrowsError(try originalBookmark.resolved())
	}

	func testWriteAliasFile() throws {
		let originalData = "This is a test".data(using: .utf8)
		let originalFile = try XCTTemporaryFile("book.txt", contents: originalData)
		let originalURL = originalFile.fileURL.standardizedFileURL
		let originalBookmark = try Bookmark(targetFileURL: originalURL)
		let originalResult = try originalBookmark.resolved()
		XCTAssertEqual(originalResult.state, .valid)
		XCTAssertEqual(originalURL, originalResult.url.standardizedFileURL)

		// Check that the string uti for the 'target' url
		XCTAssertEqual("public.plain-text", try originalBookmark.resolvedUTIString())
		// Check that the uti for the 'target' url
		#if compiler(>=5.3)
		if #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) {
			XCTAssertEqual(UTType.plainText, try originalBookmark.resolvedUTI())
		}
		#endif

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
			let originalBookmark = try Bookmark(targetFileURL: originalURL)
			#if os(macOS)
			XCTAssertEqual(.notSecurityScoped, originalBookmark.isSecurityScoped)
			#else
			XCTAssertEqual(.securityScoped, originalBookmark.isSecurityScoped)
			#endif

			let originalResult = try originalBookmark.resolved()
			XCTAssertEqual(originalResult.state, .valid)
			XCTAssertEqual(originalURL, originalResult.url.standardizedFileURL)

			try originalBookmark.resolving() { bookmark in
				XCTAssertEqual(.valid, bookmark.state)
				XCTAssertEqual(originalURL, bookmark.url.standardizedFileURL)
			}
		}

		#if os(macOS)
		do {
			let originalData = "This is a test".data(using: .utf8)
			let originalFile = try XCTTemporaryFile("book.txt", contents: originalData)
			let originalURL = originalFile.fileURL.standardizedFileURL
			let originalBookmark = try Bookmark(targetFileURL: originalURL, security: .securityScopingReadWrite)
			XCTAssertEqual(.securityScoped, originalBookmark.isSecurityScoped)
			let originalResult = try originalBookmark.resolved()
			XCTAssertEqual(originalURL, originalResult.url.standardizedFileURL)

			try originalBookmark.resolving(options: .withSecurityScope) { bookmarked in
				XCTAssertEqual(bookmarked.state, .valid)
				XCTAssertEqual(bookmarked.url.standardizedFileURL, originalURL)
			}
		}
		#endif
	}

	func testURLExtension() throws {
		let text = "This is a test of bookmark data"
		let originalData = text.data(using: .utf8)
		let originalFile = try XCTTemporaryFile("book3.txt", contents: originalData)

		let originalURL = originalFile.fileURL.standardizedFileURL
		let originalBookmark = try originalURL.bookmark()

		let bookmarkURL = try originalBookmark.resolved().url
		XCTAssertEqual(try Data(contentsOf: originalURL), try Data(contentsOf: bookmarkURL))

		try originalBookmark.resolving() { bookmark in
			XCTAssertEqual(.valid, bookmark.state)
			XCTAssertEqual(originalURL, bookmark.url.standardizedFileURL)
		}
	}

	func temporaryFile(name: String, containing text: String) throws -> XCTTemporaryFile {
		let text = "This data is to be deleted"
		let originalData = text.data(using: .utf8)
		return try XCTTemporaryFile(name, contents: originalData)
	}

	func testDeleted() throws {
		let text = "This data is to be deleted"
		let file = try temporaryFile(name: "book4.txt", containing: text)
		let url = file.fileURL.standardizedFileURL
		let bookmark = try url.bookmark()

		XCTAssertEqual(.valid, bookmark.state)

		try FileManager.default.removeItem(at: url)

		// A usingTargetURL() call will throw if the bookmark can no longer be resolved
		XCTAssertThrowsError(
			try bookmark.resolving { bookmark in
				assert(false)
			}
		)

		XCTAssertEqual(.invalid, bookmark.state)
	}

	func testCodable() throws {
		struct Thing: Codable {
			let text: String
			let bookmark: Bookmark
		}

		let text = "This bookmark"
		let file = try temporaryFile(name: "book6.txt", containing: text)
		let url = file.fileURL.standardizedFileURL
		let bookmark = try url.bookmark()

		// Verify the uttype for the target
		XCTAssertEqual("public.plain-text", try bookmark.resolvedUTIString())

		#if compiler(>=5.3)
		if #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) {
			XCTAssertEqual(.plainText, try bookmark.resolvedUTI())
		}
		#endif

		let t = Thing(text: "Booboo", bookmark: bookmark)

		let data = try JSONEncoder().encode(t)

		let te = try JSONDecoder().decode(Thing.self, from: data)

		XCTAssertEqual("Booboo", te.text)
		XCTAssertEqual(bookmark.bookmarkData, te.bookmark.bookmarkData)
	}
}

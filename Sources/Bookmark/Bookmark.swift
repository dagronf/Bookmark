//
//  Bookmark.swift
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

import Foundation
import UniformTypeIdentifiers

/// A bookmark object that describes the location of a file.
///
/// Whereas path and file reference URLs are potentially fragile between launches of your app, a bookmark can
/// usually be used to re-create a URL to a file even in cases where the file was moved or renamed.
///
/// Links :-
///
/// [Locating Files Using Bookmarks](https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/AccessingFilesandDirectories/AccessingFilesandDirectories.html#//apple_ref/doc/uid/TP40010672-CH3-SW10)
///
/// [Enabling Security-Scoped Bookmark and URL Access](https://developer.apple.com/documentation/professional_video_applications/fcpxml_reference/asset/media-rep/bookmark/enabling_security-scoped_bookmark_and_url_access)
///
/// [Bookmarks and Security Scope](https://developer.apple.com/documentation/foundation/nsurl#1663783)
@available(macOS 10.12, iOS 14, tvOS 14, *)
public class Bookmark: CustomStringConvertible, Codable {
	enum CodingKeys: CodingKey {
		case bookmarkData
	}

	/// Bookmark-specific errors
	public enum BookmarkError: Error {
		case cantAccessTargetUTType
		case invalidTargetUTType
		case cantAccessSecurityScopedResource
	}

	/// The raw bookmark data
	public let bookmarkData: Data

	/// A base-64 string representation for the bookmark data
	public private(set) lazy var bookmarkBase64: String = self.bookmarkData.base64EncodedString()

	/// Returns true if the bookmark's target is able to be resolved
	public var isValidTarget: Bool {
		((try? self.targetURL()) != nil) ? true : false
	}

	/// Is the bookmark data stale and requiring a rebuild?
	public var isStale: Bool {
		var isStale = false
		let _ = try? URL(resolvingBookmarkData: self.bookmarkData, bookmarkDataIsStale: &isStale)
		return isStale
	}

	/// Returns true if the bookmark was created with security scope (creation options contained `.withSecurityScope`)
	/// and the target for the bookmark is still resolvable.
	///
	/// iOS bookmarks are ALWAYS security scoped
	public var isSecurityScoped: Bool {
		#if os(macOS)
		((try? targetURL(options: .withSecurityScope)) != nil) ? true : false
		#else
		return true
		#endif
	}

	/// Create a bookmark object from a target file url
	/// - Parameters:
	///   - targetFileURL: The target url to bookmark
	///   - includingResourceValuesForKeys: Resource keys to store in the bookmark
	///   - options: Bookmark creation options
	public init(
		targetFileURL: URL,
		includingResourceValuesForKeys keys: Set<URLResourceKey>? = nil,
		options: URL.BookmarkCreationOptions = []
	) throws {
		assert(targetFileURL.isFileURL)

		self.bookmarkData = try targetFileURL.bookmarkData(
			options: options,
			includingResourceValuesForKeys: keys,
			relativeTo: nil
		)
	}

	/// Create a bookmark object from raw bookmark data
	/// - Parameter bookmarkData: The bookmark data
	/// - Parameter validate: Validate that the bookmark data is valid, and the target url is resolvable.
	public init(bookmarkData: Data, validate: Bool = false) throws {
		if validate {
			var isStale = false
			let _ = try URL(resolvingBookmarkData: bookmarkData, bookmarkDataIsStale: &isStale)
		}
		self.bookmarkData = bookmarkData
	}

	/// Create a bookmark by copying another bookmark
	@inlinable public convenience init(_ bookmark: Bookmark) throws {
		try self.init(bookmarkData: bookmark.bookmarkData)
	}

	/// Create from data within a decoder
	public required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.bookmarkData = try container.decode(Data.self, forKey: .bookmarkData)
	}

	/// Encode the bookmark data to an encoder
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(self.bookmarkData, forKey: .bookmarkData)
	}
}

public extension Bookmark {
	/// A textual representation of this instance.
	var description: String {
		#if os(macOS)
		if let url = try? targetURL(options: .withSecurityScope) {
			return "Bookmark(🔒): '\(url)'"
		}
		#endif
		if let url = try? self.targetURL() {
			return "Bookmark: '\(url)'"
		}
		return "<invalid bookmark>"
	}
}

// MARK: - Accessing the bookmark's target

public extension Bookmark {
	/// Returns the bookmark's target url
	/// - Parameters:
	///   - options: Additional bookmark resolution options (See: [Bookmark Resolution Options](https://developer.apple.com/documentation/foundation/nsurl/bookmarkresolutionoptions)
	/// - Returns: The bookmark's URL
	@inlinable func targetURL(
		options: NSURL.BookmarkResolutionOptions = []
	) throws -> URL {
		var isStale = false
		return try URL(resolvingBookmarkData: self.bookmarkData, options: options, bookmarkDataIsStale: &isStale)
	}

	/// Access the bookmark's target url in a block scope
	/// - Parameters:
	///   - options: Additional bookmark resolution options
	///   - scopedBlock: The block to perform.
	///                  If securityScoped is true, the url will automatically be wrapped in
	///                  `startAccessingSecurityScopedResource` and `stopAccessingSecurityScopedResource`
	/// - Returns: Return type
	func usingTargetURL<ReturnType>(
		options: NSURL.BookmarkResolutionOptions = [],
		_ scopedBlock: (URL) -> ReturnType
	) throws -> ReturnType {
		let url = try targetURL(options: options)
		#if os(macOS)
		let securityScoped = options.contains(.withSecurityScope)
		#else
		let securityScoped = true
		#endif
		if securityScoped {
			guard url.startAccessingSecurityScopedResource() == true else {
				throw BookmarkError.cantAccessSecurityScopedResource
			}
		}
		defer { if securityScoped { url.stopAccessingSecurityScopedResource() } }
		return scopedBlock(url)
	}
}

// MARK: - UTI/UTType

public extension Bookmark {
	/// Returns the UTI for the bookmark's target
	func utiStringForTargetURL() throws -> String {
		guard
			let typeString = try self.targetURL().resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier
		else {
			throw BookmarkError.cantAccessTargetUTType
		}
		return typeString
	}

	/// Returns the UTI for the bookmark's target
	@available(macOS 11.0, iOS 14.0, tvOS 14.0, *)
	func utiForTargetURL() throws -> UTType {
		let utiString = try utiStringForTargetURL()
		guard let t = UTType(utiString) else {
			throw BookmarkError.invalidTargetUTType
		}
		return t
	}
}

// MARK: - Retrieving bookmark resource values

public extension Bookmark {
	/// Returns resource values that were stored during bookmark creation
	///
	/// See: `init(targetFileURL:includingResourceValuesForKeys:options:)`
	@inlinable func resourceValues(forKeys keys: Set<URLResourceKey>) -> URLResourceValues? {
		URL.resourceValues(
			forKeys: keys,
			fromBookmarkData: self.bookmarkData
		)
	}
}

// MARK: - Writing bookmark data

public extension Bookmark {
	/// Write the bookmark data to an alias file
	/// - Parameters:
	///   - fileURL: The file url to write the alias file to
	///   - options: data writing options (See: [WritingOptions](https://developer.apple.com/documentation/foundation/nsdata/writingoptions))
	@inlinable func writeBookmarkData(
		to fileURL: URL,
		options: Data.WritingOptions = []
	) throws {
		assert(fileURL.isFileURL)
		try self.bookmarkData.write(to: fileURL, options: options)
	}

	/// Create an alias file.
	/// - Parameters:
	///   - aliasFileUrl: The location of the alias file to create
	///   - options: Bookmark creation options (See: [BookmarkCreationOptions](https://developer.apple.com/documentation/foundation/nsurl/bookmarkcreationoptions))
	func writeAliasFile(
		to aliasFileUrl: URL,
		options: URL.BookmarkCreationOptions
	) throws {
		assert(aliasFileUrl.isFileURL)

		// Make sure we write a suitable bookmark file
		var options = options
		options.insert(.suitableForBookmarkFile)

		// Grab out the url for the bookmark
		let u = try self.targetURL()
		// Create a bookmark with the appropriate flags
		let b = try Bookmark(
			targetFileURL: u,
			options: options
		)

		try URL.writeBookmarkData(b.bookmarkData, to: aliasFileUrl)
	}
}

public extension Bookmark {
	/// Make a copy of the bookmark
	@inlinable func copy() throws -> Bookmark {
		return try Bookmark(bookmarkData: self.bookmarkData)
	}

	/// Create a new bookmark referencing this url
	@inlinable func rebuild(
		securityScoped: Bool = false,
		options: URL.BookmarkCreationOptions = []
	) throws -> Bookmark {
		return try Bookmark(
			targetFileURL: try self.targetURL(),
			options: options
		)
	}
}

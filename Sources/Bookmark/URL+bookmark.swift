//
//  Bookmark.swift
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

// Extensions for file URLs dealing with bookmarks

import Foundation

@available(macOS 10.12, iOS 14, tvOS 14, *)
extension URL {
	/// Return a new bookmark object for this fileURL
	/// - Parameters:
	///   - includingResourceValuesForKeys: Resource keys to store in the bookmark
	///   - options: Bookmark creation options
	public func bookmark(
		includingResourceValuesForKeys keys: Set<URLResourceKey>? = nil,
		options: URL.BookmarkCreationOptions = []
	) throws -> Bookmark {
		try Bookmark(targetFileURL: self, includingResourceValuesForKeys: keys, options: options)
	}
}

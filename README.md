# Bookmark

A Swift wrapper for URL bookmarks which allow a file to be located regardless of whether it is moved or renamed.

<p align="center">
    <img src="https://img.shields.io/github/v/tag/dagronf/Bookmark" />
    <img src="https://img.shields.io/badge/License-MIT-lightgrey" />
    <a href="https://swift.org/package-manager">
        <img src="https://img.shields.io/badge/spm-compatible-brightgreen.svg?style=flat" alt="Swift Package Manager" />
    </a>
</p>
<p align="center">
    <img src="https://img.shields.io/badge/macOS-10.11+-red" />
    <img src="https://img.shields.io/badge/iOS-11+-blue" />
    <img src="https://img.shields.io/badge/tvOS-11+-orange" />
    <img src="https://img.shields.io/badge/watchOS-4+-purple" />
</p>

This class wraps Swift's URL `bookmark` functionality. See [Apple's documentation](https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/AccessingFilesandDirectories/AccessingFilesandDirectories.html#//apple_ref/doc/uid/TP40010672-CH3-SW10) for further information.

A bookmark can be stored (eg. on disk, in a database etc.) and reloaded and it will be able to locate the original target for the bookmark, even it has been moved or renamed.

A bookmark is an opaque data structure, enclosed in a `Data` object, that describes the location of a file. Whereas path and file reference URLs are potentially fragile between launches of your app, a bookmark can usually be used to re-create a URL to a file even in cases where the file was moved or renamed.

Some information links :-

* [Locating Files Using Bookmarks](https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/AccessingFilesandDirectories/AccessingFilesandDirectories.html#//apple_ref/doc/uid/TP40010672-CH3-SW10)
* [Enabling Security-Scoped Bookmark and URL Access](https://developer.apple.com/documentation/professional_video_applications/fcpxml_reference/asset/media-rep/bookmark/enabling_security-scoped_bookmark_and_url_access)
* [Bookmarks and Security Scope](https://developer.apple.com/documentation/foundation/nsurl#1663783)

## Usage

### Create and use a bookmark

```swift
// The original file url
let originalURL = URL(targetFileURL: ...)!

// Create a bookmark
let bookmark = try Bookmark(targetFileURL: originalURL)

// Extension on URL to generate a bookmark
let bookmark2 = try originalURL.bookmark()

// Access to the raw bookmark data
let bookmarkData = bookmark.bookmarkData

// Resolve the bookmark and retrieve its state and target url
let resolved = try bookmark.resolved()

try bookmark.resolving { resolvedItem in
   // Do something with the resolvedItem which is the original URL and its state
}

// ... Somewhere in here, the original url file is moved or renamed ...

try bookmark.resolving { resolvedItem in
   // Do something with the resolvedItem (which will correctly point to the new URL location)
}
```

### Save/Load bookmark data

`Bookmark` fully supports the `Codable` protocol.

```swift
// The original file url
let originalURL = URL(targetFileURL: ...)!

// Create a bookmark
let bookmark = try Bookmark(targetFileURL: originalURL)

// Grab out the raw bookmark data
let storableData = bookmark.bookmarkData

// ...Save the bookmark data for later use, eg. in CoreData or in a database...

// Load the bookmark data back out from the storage medium...
let savedBookmarkData = <load bookmark data from somewhere>
// ... and recreate the Bookmark object from the data
let existingBookmark = try Bookmark(bookmarkData: savedBookmarkData)

// Use the loaded bookmark
try existingBookmark.resolving { resolved in
   // ...Do something with the resolved bookmark URL
}
```

## License

```
MIT License

Copyright (c) 2024 Darren Ford

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

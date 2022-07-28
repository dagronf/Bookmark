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
    <img src="https://img.shields.io/badge/macOS-10.12+-red" />
    <img src="https://img.shields.io/badge/iOS-14+-blue" />
    <img src="https://img.shields.io/badge/tvOS-14+-orange" />
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
let originalURL = URL(fileUrlWithPath: ...)!

// Create a bookmark
let bookmark = try Bookmark(targetFileURL: originalURL)

// Access to the raw bookmark data
let bookmarkData = bookmark.bookmarkData

try bookmark.usingTargetURL { targetURL in
   // Do something with the targetURL which is the original URL
}

// ... Somewhere in here, the original url file is moved or renamed ...

try bookmark.usingTargetURL { targetURL in
   // Do something with the targetURL (which will correctly point to the new URL location)
}
```

### Load a bookmark from bookmark data

```swift
// Load the bookmark from stored bookmark data
let someData = /* load bookmark data from somewhere */
let bookmark = try Bookmark(bookmarkData: someData)

try bookmark.usingTargetURL { targetURL in
   // Do something with the targetURL (which is the original target file)
}

```

## License

MIT. Use it for anything you want, just attribute my work if you do. Let me know if you do use it somewhere, I'd love to hear about it!

```
MIT License

Copyright (c) 2022 Darren Ford

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

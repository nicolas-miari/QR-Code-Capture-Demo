# QR Code Capture Demo

Swift port of [Use Your Loaf's tutorial](https://useyourloaf.com/blog/reading-qr-codes/) on how to read QR codes using the iOS SDK.

### Main changes from the original

The original code was written in Objective-C; porting to Swift called for some modernization. Some changes:

  - In several places, iteration was switched to using the swiftier `.forEach {` and `.flatMap {` constructs.  
  - Lazy initialization of the capture session, with the 'side effect' of preview layer creation was split into two explicit methods.
  - The code for creating a path no longer needs to jump through hoops in order to create an array of `CGPoint` (Swift's `Array` can handle value types, unlike `NSArray`).

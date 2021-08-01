# iPadOSPointerContinuity
Demonstration of a macOS-like pointer (aka cursor) interaction for connected displays on iPad.  
This app captures the iPadOS pointer and replaces it with a desktop-like cursor that can move to an external display, if connected. 

Click the screenshot below to watch a very brief demo (YouTube).

[![Screenshot of Pointer Continuity on iPad. Links to a YouTube video of the app in action.](https://user-images.githubusercontent.com/12073163/117293476-b5d36680-ae71-11eb-82b4-2da55b71bc05.jpg)](http://www.youtube.com/watch?v=TZD8NU5ZJbI "")

Note: there is a known issue [#1](https://github.com/conath/iPadOSPointerContinuity/issues/1) that prevents the custom cursor from appearing.  
To work around this, just go to the home screen once and then open the app again if it doesn't work right away.  
This issue does not exist when running from Xcode.

## How to connect to a TV or external screen

On a real iOS device: use AirPlay Mirroring from Control Center or connect directly via a compatible adapter.

In the iOS Simulator: Click "I/O" in the menu bar, then choose any resolution under "External Displays".

## A note on iPhone support
While this app technically works fine on iPhone, as of iOS 14.7 connecting any kind of mouse to iPhone is not officially supported by Apple. Please see [this comment](https://github.com/conath/iPadOSPointerContinuity/issues/2#issuecomment-890590817) for more information.

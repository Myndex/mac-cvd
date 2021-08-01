
//    Copyright 2005-2021 Michel Fortin
//
//    Licensed under the Apache License, Version 2.0 (the "License");
//    you may not use this file except in compliance with the License.
//    You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//    Unless required by applicable law or agreed to in writing, software
//    distributed under the License is distributed on an "AS IS" BASIS,
//    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//    See the License for the specific language governing permissions and
//    limitations under the License.

import Cocoa

class Window: NSPanel {
	
	static let willStartDragging = Notification.Name("WindowWillStartDraggingNotification")
	static let didEndDragging = Notification.Name("WindowDidEndDraggingNotification")

	var dragging = false
	var pausedDragTimer: Timer?

	override func mouseDragged(with event: NSEvent) {
		if !dragging {
			dragging = true
			NotificationCenter.default.post(name: Window.willStartDragging, object: self)
		}
		pausedDragTimer?.invalidate()
		pausedDragTimer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(stoppedDragging), userInfo: nil, repeats: false)

		super.mouseDragged(with: event)
	}

	@objc private func stoppedDragging() {
		dragging = false
		NotificationCenter.default.post(name: Window.didEndDragging, object: self)
	}

	override func orderOut(_ sender: Any?) {
		super.orderOut(sender)
		close()
	}

}

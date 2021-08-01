
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

class FilterSettingsController: NSTitlebarAccessoryViewController {

	@IBOutlet var visionButton: NSButton!
	@IBOutlet var refreshSpeedButton: NSButton!
	@IBOutlet var viewAreaButton: NSButton!

	override func awakeFromNib() {
		NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: UserDefaults.didChangeNotification, object: nil)
	}

	deinit {
		NotificationCenter.default.removeObserver(self)
	}

	@objc func refresh() {
		refreshSpeedButton.image = refreshSpeedDefault.image
		viewAreaButton.image = viewAreaDefault.image
	}

}

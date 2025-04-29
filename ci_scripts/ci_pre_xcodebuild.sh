#!/bin/sh

#  ci_pre_xcodebuild.sh
#  Zotero
#
#  Created by Michal Rentka on 01.06.2023.
#  Copyright © 2023 Corporation for Digital Scholarship. All rights reserved.


# instal NVM
export NVM_DIR="$HOME/.nvm"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.2/install.sh | bash


git clone https://github.com/zotero/pdf-keys.git
license=$(grep -Eo '\"license_key\":\"[A-Za-z0-9_=\-]+\"' pdf-keys/ios_license.json | cut -c 15- | tr -d '"')
plist='<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>pspdfkit</key>
	<string>'"$license"'</string>
</dict>
</plist>'
echo "$plist" > licenses/licenses.plist
rm -rf pdf-keys
// MIT License
//
// Copyright 2019 Electric Imp
//
// SPDX-License-Identifier: MIT
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
// EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
// OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

/**
 * This example emulates a software update process on a device.
 * It shows a serial execution of multiple promises.
 * CheckUpdates, Download and Install methods are executed one by one,
 * if the previous step succeeds. The `install` function returns version
 * of the installed software update (for example 0.57), which is then
 * printed upon successfull installation.
 *
 * NOTE: this code should be run on agent side only!
 */

#require "Promise.lib.nut:4.0.0"

const URL = "https://product-details.mozilla.org/1.0/firefox_versions.json";
const key = "LATEST_FIREFOX_VERSION";

local curVersion = "51.1";
local newVersion = "";

// To make the example more realistic, we'll check for
// a new version from Mozilla API via an HTTP request
function checkUpdates() {
    return Promise(function(resolve, reject) {
        local request = http.get(URL);
        local response = request.sendsync();

        if (response.statuscode == 200) {
            local data = http.jsondecode(response.body);
            newVersion = data[key];

            if (curVersion == newVersion) {
                reject("Latest version is already installed");
            } else {
                server.log("New version available");
            }
            resolve(true);
        } else {
            reject("Connection error");
        }
    });
}

// Emulation of downloading process...
function download() {
    return Promise(function(resolve, reject) {
        server.log("Downloading now...");
        imp.wakeup(4, function() { resolve(true) });
    });
}

// Emulate installation, also update value of current version
function install() {
    server.log("Installation in progress...");
    curVersion = newVersion;
    return Promise.resolve(newVersion);
}

local series = [
    checkUpdates,
    download,
    install
];

Promise.serial(series)
.then(function(ver) {
    server.log("Success. Installed version: " + ver);
})
.fail(function(err) {
    server.log("Error: " + err);
});

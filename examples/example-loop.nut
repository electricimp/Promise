// MIT License
//
// Copyright 2020-23 KOIRE Wireless
// Copyright 2016-19 Electric Imp
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
 * Example of application for security system of the building.
 * The goal is to check that all doors in building are locked or raise an alert otherwise.
 * There are 5 door sensors and a method to check the states by a sensor id.
 * So we call `loop()` which invokes `checkDoorById` method synchronously with ids 1..5.
 * If we've got a rejected promise on any of iterations,
 * the loop execution is aborted and `fail()` is triggered.
 * If all is ok, `then()` is called with the result of the last iteration.
 */

#require "Promise.lib.nut:4.0.1"

/**
 * If the door specified by `id` is locked, it returns a resolved `Promise` with `true`.
 * If the door is not responding or door is unlocked, returns a rejected `Promise`.
 */
function checkDoorById(id) {
    return Promise(function(resolve, reject) {
        local isClosed = true;

        // Check for the door status...
        // isClosed = ...;

        // Emulate an async operation with imp.wakeup
        imp.wakeup(2, function() {
            if (isClosed) {
                resolve(); // door is closed
            } else {
                reject("A door is open!"); // door is open
            }
        });
    });
}

local i = 0;
Promise.loop(
    @() i++ < 5,
    function () {
        return checkDoorById(i);
    }
)
.then(function(x) { // called in 10 seconds
    server.log("All doors are closed");
})
.fail(function(err) {
    server.log("Unlocked door detected: " + err);
});
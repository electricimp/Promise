// MIT License
//
// Copyright 2017 Electric Imp
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

#require "Promise.lib.nut:4.0.0"

/**
 * Example of application for security system of the building.
 * We need to check that all doors in building are locked. We got 5 sensors and one method to check state of
 * sensor by id. So we call loop() which calls checkDoorById method synchronously with ids 1..5. If got rejected 
 * promise on any of iterations, loop execution aborted and .fail() triggered. If all is ok, .then() called with 
 * result of last iteration 
 */

/**
 * If door is locked, it returns resolved promise with value 'true'.
 * If door is not responding or door is unlocked, returns rejected promise
 */
function checkDoorById (id) {
    return Promise(function(resolve, reject) {
        imp.wakeup(2, function() { resolve(true) });
    });
}

local i = 1;
Promise.loop(
    @() i++ < 6,
    function () {
        return checkDoorById(i);
    }
)
.then(function(x) { // called in 10 seconds
    server.log("All doors are closed");
})
.fail(function(err){
    server.log("Unlocked door detected!");
});

// Result:
// (delay 10 seconds)
// All sensors are alive

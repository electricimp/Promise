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
 * Example of loop execution, we have 5 sensors and one method to check state of sensor by id. We 
 * run loop() which calls checkSensor method synchronously with ids 1..5. If got rejected promise
 * on any of iterations, loop execution aborted and .fail() triggered. If all is ok, .then() called
 * with result of last iteration 
 */

/**
 * If sensor is alive, it returns resolved promise with value 'true'.
 * If sensor is not responding, returns rejected promise
 */
function checkSensor (id) {
    return Promise(function(resolve, reject) {
        imp.wakeup(2, function() { resolve(true) });
    });
}

local i = 1;
Promise.loop(
    @() i++ < 6,
    function () {
        return checkSensor(i);
    }
)
.then(function(x) { // called in 10 seconds
    server.log("All sensors are alive");
})
.fail(function(err){
    server.log("Dead sensor detected!");
});

// Result:
// (delay 10 seconds)
// All sensors are alive

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

/**
 * The example demonstrates a parking assistance application.
 *
 * There are three different parkings lots near a shopping center.
 * Each parking lot has its own software API with different methods to find a place.
 * We call three different methods in parallel using race().
 * As soon as any method finds a spot, `then()` handler is triggered.
 */

#require "Promise.lib.nut:4.0.0"

// max value for random generator
const MAX = 20;

// For each method we make random delay
function checkSlot(prefix, found) {
    // When a place is found, call `found(placeId)`
    // with the found slot id as the first argument
    local delay = math.rand() % MAX + 2;
    local place = prefix + (math.rand() % MAX);
    imp.wakeup(delay, function() {
        found(place)
    });
}

function checkParkingA() {
    return Promise(function (resolve, reject) {
        checkSlot("A", resolve);
    });
}

function checkParkingB() {
    return Promise(function (resolve, reject) {
        checkSlot("B", resolve);
    });
}

function checkParkingC() {
    return Promise(function (resolve, reject) {
        checkSlot("C", resolve);
    });
}

server.log("Looking for a place available...");
Promise.race([checkParkingA, checkParkingB, checkParkingC])
.then(function(place) {
    server.log("Found place: " + place);
})

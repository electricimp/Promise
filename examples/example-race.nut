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
 * Example of parking assistance application
 * There are three different parkings near the shopping center. Each parking has its own software API with
 * different methods to find a place. We call three different methods in parallel using race(). As soon as any
 * method will find a place, then() handler will be triggered.
 */

// max value for random generator
const MAX = 20;

// for each method we make random delay
function checkParkingA () {
    return Promise(function (resolve, reject) {
        local delay = math.rand() % MAX + 2;
        local place = "A" + (math.rand() % MAX);
        imp.wakeup(delay, function() { resolve(place) });
    });
}

function checkParkingB () {
    return Promise(function (resolve, reject) {
        local delay = math.rand() % MAX + 2;
        local place = "B" + (math.rand() % MAX);
        imp.wakeup(delay, function() { resolve(place) });
    });
}

function checkParkingC () {
    return Promise(function (resolve, reject) {
        local delay = math.rand() % MAX + 2;
        local place = "C" + (math.rand() % MAX);
        imp.wakeup(delay, function() { resolve(place) });
    });
}

server.log("looking for place on parking...");
Promise.race([checkParkingA, checkParkingB, checkParkingC])
.then(function(place) {
    server.log("Found place: " + place);
})
.fail(function(err) {
    server.log("Sorry, all parkings are busy now");
});



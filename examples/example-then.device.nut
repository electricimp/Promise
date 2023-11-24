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
 * In this example small application for a smart weather station.
 * It reads temperature data from sensor and send it to agent.
 * Example of serial execution using chain of then() handlers.
 *
 * NOTE: this code should be run on device side only!
 */

#require "Promise.lib.nut:4.0.1"

const MAX = 100;

// generating random number as device id, returning as promise
function initSensor() {
    return Promise(function(resolve, reject) {
        local deviceId = math.rand() % MAX;
        resolve(deviceId);
    });
}

// generating some random float value as temperature
function readData(sensor) {
    local temp = math.rand() % MAX + 0.1;
    return temp;
}

initSensor()
.then(function(sensorId){
    return readData(sensorId);
})
.then(function(temp) {
    agent.send("temp", temp);
})
.fail(function(err) {
    server.log("Unexpected error: " + err);
});

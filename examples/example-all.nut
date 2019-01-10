// MIT License
//
// Copyright 2017-19 Electric Imp
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
 * This is example of application for smart weather station. There are multiple sensors and we'll read
 * metrics from all of them in parallel, then send data to agent. Then() handler triggered only when
 * all data collected.
 */

// Generate random values in this methods
function getTemperature () {
    return Promise(function (resolve, reject) {
        local temp = math.rand() % 35;
        resolve(temp);
    });
}

function getBarometer () {
    return Promise(function (resolve, reject) {
        local bar = 0.98 + 0.01 * (math.rand() % 5); 
        resolve(bar);
    });
}

function getHumidity () {
    local value = 0.8 + 0.01 * (math.rand() % 20);
    return Promise.resolve(value);
}

/**
 * Collect metrics from all weather sensors and then send it to agent (on server)
 */
Promise.all([getTemperature, getBarometer, getHumidity])
.then(function(metrics) {
    server.log("Temp (Celsius): " + metrics[0]);
    server.log("Atm pressure (bar): " + metrics[1]);
    server.log("Humidity (%): " + metrics[2]);

    agent.send("weather metrics", metrics);
});



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

const MAX = 100;

/**
 * Simple example of synchronous execution with passing arguments from one step to another:
 */

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


/**
 * This is example of chain of .then() handlers, passing value from one to another:
 */

Promise.resolve("The")
.then(function(res) {
    return res + " world";
})
.then(function(res) {
    return Promise.resolve(res + " is");
})
.then(function(res) {
    return res + " yours";
})
.then(function(x) {
    // Result output: "The world is yours"
    server.log(x);  
});

/**
 * Example of error handling, if any of actions returns rejected Promise, fail() handler triggered:
 */

function actionA () {
    return Promise(function(resolve, reject) {
        resolve("A");
    });
}

// this action will fail
function actionB (arg) {
    return Promise(function(resolve, reject) {
        reject("No such file");
    });
}

function actionC (arg) {
    return Promise(function(resolve, reject) {
        resolve("C");
    });
}

actionA()
.then(actionB)
.then(actionC)
.then(function(x) {
    server.log(x);
})
.fail(function(err) {
    // Output: "Error: No such file"
    server.log("Error: " + err);
});


/**
 * instead of final then/fail handlers we can use finally():
 */

actionA()
.then(actionB)
.then(actionC)
.finally(function(valueOrReason) {
    server.log("resolved or rejected with value or reason: " + valueOrReason);
});



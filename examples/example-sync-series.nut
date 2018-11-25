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
 * Example of resolving Promise after 1 second timeout
 */

function actionA() {
    return Promise(function(resolve, reject) {
        resolve("A");
    });
}

function actionB() {
    return Promise(function(resolve, reject) {
        resolve("B");
    });
}

function actionC() {
    return Promise(function(resolve, reject) {
        resolve("C");
    });
}

local d = Promise(function(resolve, reject) {
   resolve("D"); 
});

/**
 * Simple sync chain of promises
 */

actionA()
.then(actionB)
.then(actionC)
.fail(function() {
    print("Failed");
})
.finally(function(ex) {
    print("Chain executed");
});

/**
 * Example of serial promises execution
 * Executes promises or promise-returning functions one by one
 */

local res = Promise.serial([actionA, actionB, actionC, d]);



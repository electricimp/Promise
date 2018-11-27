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

function actionA() {
    return Promise(function(resolve, reject) {
        imp.wakeup(2, function() { resolve("A") });
    });
}

function actionB() {
    return Promise(function(resolve, reject) {
        imp.wakeup(0.2, function() { resolve("B") });
    });
}

function actionC() {
    return Promise(function(resolve, reject) {
        imp.wakeup(3, function() { resolve("C") });
    });
}

/**
 * Race example, executes all promises in parallel. Returns result of first resolved one.
 */

Promise.race([actionA, actionB, actionC])
.then(function(x) {
    server.log(x);  // <-- B
});

// declared promise like this executed imidately:
local d = Promise(function(resolve, reject) {
   resolve("D"); 
});

// so if now we'll call race() with promise-returning functions and this one, it will be a fastest resolved

Promise.race([actionA, actionB, actionC, d])
.then(function(x) {
    server.log(x); // <-- D
});

// Another example:   first two actions executed right after Promise instance was declared
local action1 = Promise(function(resolve, reject) {
    imp.wakeup(1, function() { resolve(1) });
});

local action2 = Promise(function(resolve, reject) {
    imp.wakeup(1.5, function() { resolve(2) });
});

// this action will be executed only after race() call:
function action3 () {
    return Promise(function(resolve, reject) {
        imp.wakeup(0.3, function() {resolve(3)});
    });
};

// so at this point action1 and action2 already executed and pending for result:
Promise.race([action1, action2, action3])
.then(function(value) {
    server.log(value); // <-- 3
});



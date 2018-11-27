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

// simple example of then() handlers chain
Promise.resolve("The")
.then(function(res) {
    return res + " world";    // then() can return simple value
})
.then(function(res) {
    return Promise.resolve(res + " is");   // or another promise
})
.then(function(res) {
    return res + " yours";
})
.then(function(x) {
    server.log(x);  // <-- "The world is yours"
});

function actionA () {
    return Promise(function(resolve, reject) {
        resolve("A");
    });
}

function actionB (arg) {
    return Promise(function(resolve, reject) {
        resolve("B");
    });
}

function actionC (arg) {
    return Promise(function(resolve, reject) {
        resolve("C");
    });
}

// classic mode:
actionA()
.then(actionB)
.then(actionC)
.then(function(x) {
    server.log(x);  // <-- C
})
.fail(function(err) {
    server.log(err);   // log out error if some action failed
});

server.log(test);

// instead of final then/fail handlers we can use finally:
actionA()
.then(actionB)
.then(actionC)
.finally(function(valueOrReason) {
    server.log("myPromise resolved or rejected with value or reason: " + valueOrReason);
});

Promise.resolve("Woo")
.then(actionB)
.then(actionC)
.then(function(res) {
    return Promise.reject("Error: no file");
})
.finally(function(valueOrReason) {
    server.log(valueOrReason); // <-- "Error: no file"
});

local d = Promise(function(resolve, reject) {
    imp.wakeup(3, function () { resolve("wake up"); });    
});

actionA()
.then(actionB)
.then(function(x) {
    return d;   // returning pending promise
})
.then(function(x) {  // this then() handler executed right after d promise was resolved (after 3 seconds)
    server.log(d); // <-- "wake up"
});




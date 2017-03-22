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

#require "Promise.class.nut:3.0.0"

/**
 * Example of resolving Promise after 1 second timeout
 * @return {Promise}
 */
function a() {
    return Promise(function(resolve, reject) {
        imp.wakeup(1, function() {
          resolve("A");
        });
    });
}

/**
 * Example of resolving Promise with another Promise
 * @return {Promise}
 */
function b() {
    return Promise(function(resolve, reject) {
        resolve(Promise(function(resolve, reject) {
          // finally rejecting it
          reject("B");
        }));
    });
}

a().then(function(e) {
    server.log("a: resolved with \"" + e + "\"")
})
.fail(function(e) {
    server.log("a: failed with \"" + e + "\"")
});

b().then(/* ok callback */ function(e) {
  server.log("b: resolved with \"" + e + "\"")
}, /* error callback */function(e) {
  server.log("b: failed with \"" + e + "\" (handler #1)")
  throw e;
})
.fail(function(e) {
  server.log("b: failed with \"" + e + "\" (handler #2)")
})
.finally(function(e) {
  server.log("b: finally()")
});

/*

Should produce the following output:

b: failed with "B" (handler #1)
b: failed with "B" (handler #2)
b: finally()
(1 second delay)
a: resolved with "A"

*/

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

// -----------------------------------------------------------------------------
// This class exposed a single method fire() which waits a second and then randomly fails or succeeds.
// It returns a Promise which will fire then() or fail() at the conclusion of execution.
//
class RandomFailure {

    function fire() {
        return Promise(function (fulfill, reject){
            imp.wakeup(1, function () {
                if (math.rand() % 9 == 0) {
                    reject("random");
                } else {
                    fulfill("ok");
                }
            }.bindenv(this));
        }.bindenv(this));
    }

}


// -----------------------------------------------------------------------------
// This application executes the class's fire() method repeatedly until it fails.
//
function go() {
    RandomFailure().fire()
    .then(
        function(res) {
            server.log(res);
            go();
        }
    )
    .fail(
        function(err) {
            server.log("Done");
        }
    )
}
go();

// MIT License
//
// Copyright 2016 Electric Imp
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
// "Promise" symbol is injected dependency from ImpUnit_Promise module,
// while class being tested can be accessed from global scope as "::Promise".

class ThenAfterFailTestCase extends ImpTestCase {

    // Test that .then() placed after .fail() should be called on rejection

    function testThenAfterFail() {
        return Promise(function(ok, err) {

            local thenCalled = false;
            local failCalled = false;
            local thenAfterFailedCalled = false;
            local value = -123;

            local p = ::Promise(function (resolve, reject) {
                reject(123);
            });

            p
                .then(function (v) { thenCalled = true; }.bindenv(this)) // should NOT be called
                .fail(function (v) { failCalled = true; value = v; }.bindenv(this)) // should be called
                .then(function (v) { thenAfterFailedCalled = true; value = v; }.bindenv(this)) // should be called
                .finally(function(v) {
                    try {
                        this.assertEqual(false, thenCalled);
                        this.assertEqual(true, failCalled);
                        this.assertEqual(true, thenAfterFailedCalled,
                            ".then() expected to be called after .fail() on rejection");
                        this.assertEqual(null, value);
                        ok();
                    } catch (e) {
                        err(e);
                    }
                }.bindenv(this));

        }.bindenv(this));
    }
}

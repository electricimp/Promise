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

// Test case for Promise.race()

class RaceTestCase extends ImpTestCase {

    // Check return type

    function testReturnType() {
        local p = ::Promise.race([]);
        this.assertTrue(p instanceof ::Promise);
    }


    // Test .race() with empty array

    function testEmptyPromisesArray() {
        return Promise(function(ok, err) {
            local p = ::Promise.race([]);
            p
                .then(@() err("When empty array is passed to .race(), returned promise should not resolve"))
                .fail(@() err("When empty array is passed to .race(), returned promise should not reject"));
            imp.wakeup(0, ok);
        }.bindenv(this));
    }

    // Test .race() with all Promises in the chain resolving

    function testRaceWithAllResolving() {
        return Promise(function(ok, err) {

            local promises = [
                // resolves race as the other one with 0s timeout value
                // starts later from inside .race()
                ::Promise(function (resolve, reject) { imp.wakeup(0, @() resolve(1)) }),
                @() ::Promise(function (resolve, reject) { imp.wakeup(0.5, @() resolve(2)) }),
                @() ::Promise(function (resolve, reject) { imp.wakeup(0, @() resolve(3)) }),
            ];

            ::Promise.race(promises)
                .then(function (v) {
                    try {
                        // .race() should resolve with value of the first resolved promise
                        this.assertEqual(1, v);
                        ok();
                    } catch (e) {
                        err(e);
                    }
                }.bindenv(this));

        }.bindenv(this));
    }


    // Test .race() with rejection

    function testRaceWithRejection() {
        return Promise(function(ok, err) {

            local promises = [
                // rejects first as the other one with 0s timeout value
                // starts later from inside .race()
                ::Promise(function (resolve, reject) { imp.wakeup(0, @() reject(1)) }),
                @() ::Promise(function (resolve, reject) { imp.wakeup(0.5, @() resolve(2)) }),
                @() ::Promise(function (resolve, reject) { imp.wakeup(0, @() reject(3)) }),
            ];

            ::Promise.race(promises)

                .then(@(v) err(".then() should not be called on .race Promise rejection"))

                .fail(function (v) {
                    try {
                        // .race() should reject with value of the first rejected promise
                        this.assertEqual(1, v);
                        ok();
                    } catch (e) {
                        err(e);
                    }
                }.bindenv(this));

        }.bindenv(this));
    }
}

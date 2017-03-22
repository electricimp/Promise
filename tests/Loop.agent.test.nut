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

// Test case for Promise.loop()

class LoopTestCase extends ImpTestCase {

    // Check return type

    function testReturnType() {
        local p = ::Promise.loop(
            function () {},
            function () {}
        );

        this.assertTrue(p instanceof ::Promise);
    }

    // Check immediate stop

    function testImmediateStop() {
        return Promise(function(ok, err) {
            local p = ::Promise.loop(
                @() false,
                function () {
                    throw "next() shold not be called"
                }.bindenv(this)
            );
            p.then(ok, err);
        }.bindenv(this));
    }

    // Test looping with all resolves

    function testLoopingWithResolves() {
        return Promise(function(ok, err) {
            local i = 0;

            local loopPromise = ::Promise.loop(
                @() i++ < 3,
                function () {
                    return ::Promise(function (resolve, reject) {
                        resolve("abc" + i);
                    });
                }
            );

            loopPromise
                .then(function (v) {
                    try {
                        this.assertEqual(4, i); // when i==4, loop should break
                        this.assertEqual("abc3", v); // last value that looped promise resolved with
                        ok();
                    } catch (e) {
                        err(e);
                    }
                }.bindenv(this));

        }.bindenv(this));
    }

    // Test looping with exit on rejection

    function testLoopingWithRejection() {
        return Promise(function(ok, err) {
            local i = 0;

            local loopPromise = ::Promise.loop(
                @() i < 10,
                function () {
                    return ::Promise(function (resolve, reject) {
                        ++i == 5 ? reject("abc" + i) : resolve("abc" + i);
                    });
                }
            );

            loopPromise

                .then(function (v) {
                    err(".then() should not be called on looped Promise rejection")
                })

                .fail(function (v) {
                    try {
                        this.assertEqual(5, i); // when i==5, looped Promise rejects
                        this.assertEqual("abc5", v); // last value that looped promise rejected with
                        ok();
                    } catch (e) {
                        err(e);
                    }
                }.bindenv(this));

        }.bindenv(this));
    }

    // Test .finally() order with loops

    function testLoopFinallyOrder() {
        return Promise(function(ok, err) {

            local i = 0;

            local loopPromise = ::Promise.loop(
                @() i++ < 1,
                function () {
                    return ::Promise(function (resolve, reject) {
                        imp.wakeup(0.5, function() {
                            resolve();
                            ok(); // if it's called, successive err() calls are ignored
                        })
                    });
                }
            );

            loopPromise
                .then(function (v) {
                }.bindenv(this))
                .finally(function (v) {
                    err("Finally shoul be called after .loop() resolves");
                }.bindenv(this));

        }.bindenv(this));
    }
}

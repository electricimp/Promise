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

// Test case for Promise.serial()

class SerialTestCase extends ImpTestCase {

    // Check return type

    function testReturnType() {
        local p = ::Promise.serial([]);
        this.assertTrue(p instanceof ::Promise);
    }

    // Test .serial() with all Promises in the chain resolving

    function testSerialWithAllResolving() {
        return Promise(function(ok, err) {

            local promises = [
                ::Promise(function (resolve, reject) { resolve(1) }),
                ::Promise(function (resolve, reject) { resolve(2) }),
                ::Promise(function (resolve, reject) { resolve(3) })
            ];

            ::Promise.serial(promises)
                .then(function (v) {
                    try {
                        // .serial() should resolve with value of the last value
                        // if all Promise's are resolving
                        this.assertEqual(3, v);
                        ok();
                    } catch (e) {
                        err(e);
                    }
                }.bindenv(this));

        }.bindenv(this));
    }

    // Test .serial() with one of the Promises in the chain rejects

    function testSerialWithRejecting() {
        return Promise(function(ok, err) {

            local promises = [
                ::Promise(function (resolve, reject) { resolve(1) }),
                ::Promise(function (resolve, reject) { reject(2) }),
                ::Promise(function (resolve, reject) { resolve(3) })
            ];

            ::Promise.serial(promises)

                .then(function (v) {
                    err(".then() should not be called on serial Promise rejection")
                })

                .fail(function (v) {
                    try {
                        // .serial() should reject with value of the rejected promise
                        this.assertEqual(2, v);
                        ok();
                    } catch (e) {
                        err(e);
                    }
                }.bindenv(this));

        }.bindenv(this));
    }

    // Test .serial() with array of functions

    function testSerialWithFunctions() {
        return Promise(function(ok, err) {

            local promises = [
                @() ::Promise(function (resolve, reject) { resolve(1) }),
                @() ::Promise(function (resolve, reject) { reject(2) }),
                ::Promise(function (resolve, reject) { resolve(3) })
            ];

            ::Promise.serial(promises)

                .then(function (v) {
                    err(".then() should not be called on serial Promise rejection")
                })

                .fail(function (v) {
                    try {
                        // .serial() should reject with value of the rejected promise
                        this.assertEqual(2, v);
                        ok();
                    } catch (e) {
                        err(e);
                    }
                }.bindenv(this));

        }.bindenv(this));
    }
}

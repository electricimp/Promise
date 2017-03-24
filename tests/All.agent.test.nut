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


// Test case for Promise.all()

class AllTestCase extends ImpTestCase {

    // Check return type

    function testReturnType() {
        local p = ::Promise.all([]);
        this.assertTrue(p instanceof ::Promise);
    }

    // Test .all() with empty array

    function testEmptyPromisesArray() {
        return Promise(function(ok, err) {
            local p = ::Promise.all([]);
            p.then(function (v) {
                try {
                    this.assertDeepEqual([], v);
                    ok();
                } catch (e) {
                    err(e);
                }
            }.bindenv(this));
        }.bindenv(this));
    }

    // Test .all() with all Promises in the chain resolving

    function testAllWithAllResolving() {
        return Promise(function(ok, err) {

            local promises = [
                ::Promise(function (resolve, reject) { resolve(1) }),
                @() ::Promise(function (resolve, reject) { resolve(2) }),
                ::Promise(function (resolve, reject) { resolve(3) })
            ];

            ::Promise.all(promises)
                .then(function (v) {
                    try {
                        // .all() should resolve with array of all values
                        // if all Promise's are resolving
                        this.assertEqual(1, v[0]);
                        this.assertEqual(2, v[1]);
                        this.assertEqual(3, v[2]);
                        ok();
                    } catch (e) {
                        err(e);
                    }
                }.bindenv(this));

        }.bindenv(this));
    }

    // Test .all() with some Promises in the chain rejecting

    function testAllWithRejection() {
        return Promise(function(ok, err) {
            local promises = [
                ::Promise(function (resolve, reject) { resolve(1) }),
                @() ::Promise(function (resolve, reject) { reject(2) }),
                ::Promise(function (resolve, reject) { reject(3) })
            ];

            ::Promise.all(promises)
                .then(function (v) {
                    err(".then() should not be called on all Promise rejection")
                })

                .fail(function (v) {
                    try {
                        //this.assertEqual(2, v);
                        this.assert(v == 2 || v == 3);
                        ok();
                    } catch (e) {
                        err(e);
                    }
                }.bindenv(this));

        }.bindenv(this));
    }
}

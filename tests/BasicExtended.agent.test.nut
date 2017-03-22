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

class BasicTestCase extends ImpTestCase {

    // Test rejection with throw+fail() handler

    function testCatchWithThenHandler1() {
        return Promise(function(ok, err) {
            local p = ::Promise(function (resolve, reject) {
                throw "Error in Promise";
            });

            p.then(err, @(res) ok());
        }.bindenv(this));
    }

    // Test rejection with reject()+fail() handler

    function testCatchWithThenHandler2() {
        return Promise(function(ok, err) {
            local p = ::Promise(function (resolve, reject) {
                reject();
            });
            p.then(err, ok);
        }.bindenv(this));
    }

    // Test rejection with throw+fail() handler

    function testCatchWithFailHandler1() {
        return Promise(function(ok, err) {
            local p = ::Promise(function (resolve, reject) {
                throw "Error in Promise";
            });
            p.then(err).fail(@(res) ok());
        }.bindenv(this));
    }

    // Test rejection with reject()+fail() handler

    function testCatchWithFailHandler2() {
        return Promise(function(ok, err) {
            local p = ::Promise(function (resolve, reject) {
                reject();
            });
            p.then(err).fail(ok);
        }.bindenv(this));
    }

    // Test that finally() is called on rejection

    function testFinallyCallOnRejection() {
        return Promise(function(ok, err) {

            local thenCalled = false;
            local failCalled = false;

            local p = ::Promise(function (resolve, reject) {
                reject();
            });

            p
                .then(function (v) { thenCalled = true; })
                .fail(function (v) { failCalled = true; })
                .finally(function (v) {
                    try {
                        this.assertEqual(false, thenCalled);
                        this.assertEqual(true, failCalled);
                        ok();
                    } catch (e) {
                        err(e);
                    }
                }.bindenv(this));


        }.bindenv(this));
    }

    // Test that finally() is called on resolution

    function testFinallyCallOnResolution() {
        return Promise(function(ok, err) {

            local thenCalled = false;
            local failCalled = false;

            local p = ::Promise(function (resolve, reject) {
                resolve();
            });

            p
                .then(function (v) { thenCalled = true; })
                .fail(function (v) { failCalled = true; })
                .finally(function (v) {
                    try {
                        this.assertEqual(true, thenCalled);
                        this.assertEqual(false, failCalled);
                        ok();
                    } catch (e) {
                        err(e);
                    }
                }.bindenv(this));

        }.bindenv(this));
    }

    // Test that finally() is called on resolution

    function testFinallyCallOnResolution() {
        return Promise(function(ok, err) {
            local p = ::Promise(function (resolve, reject) {resolve();});
            p.finally(ok);
        }.bindenv(this));
    }


    // Test that finally() is called on rejection

    function testFinallyCallOnResolution() {
        return Promise(function(ok, err) {
            local p = ::Promise(function (resolve, reject) {reject();});
            p.finally(ok);
        }.bindenv(this));
    }

    function testHandlerInstances() {
        return Promise(function(ok, err) {
            local p1 = ::Promise(function (resolve, reject) {
            });

            p1.then(function (v) {
                err("p1 handlers should not be called");
            });

            local p2 = ::Promise(function (resolve, reject) {
                imp.wakeup(0.5, function() {
                    resolve();
                });
            });

            p2.then(function (v) {
            });

            p2.then(function (v) {
                ok();
            });

        }.bindenv(this));
    }
}

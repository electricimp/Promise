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

// "Promise" symbol is injected dependency from ImpUnit_Promise module,
// while class being tested can be accessed from global scope as "::Promise".

 // Test case:
 // "then" handlers should not be called if promises in race, all, serial, loop is in pending state
class PendingState extends ImpTestCase {
 
    // race  - then
 
    function testRaceThen() {
        return Promise(function(ok, err) {
            local isResolved = false;
            ::Promise.race([
                    ::Promise(function (resolve, reject) { }),
                    @() ::Promise(function (resolve, reject) { }),
                    ::Promise(function (resolve, reject) { })
                ]).then(function(res) { 
                    isResolved = true;
                }.bindenv(this), function(res) { 
                    isResolved = true;
                }.bindenv(this));
            // wait and verify pending state
            imp.wakeup(10, function() {
                isResolved ? err("Unexpected, Promise is resolved") : ok();
            });
        }.bindenv(this));
    }

    // race  - finally

    function testRaceFinally() {
        return Promise(function(ok, err) {
            local isResolved = false;
            ::Promise.race([
                    @() ::Promise(function (resolve, reject) { }),
                    @() ::Promise(function (resolve, reject) { }),
                    @() ::Promise(function (resolve, reject) { })
                ]).finally(function(res) { 
                    isResolved = true;
                }.bindenv(this));
            // wait and verify pending state
            imp.wakeup(10, function() {
                isResolved ? err("Unexpected, Promise is resolved") : ok();
            });
        }.bindenv(this));
    }

    // all - then

    function testAllThen() {
        return Promise(function(ok, err) {
            local isResolved = false;
            ::Promise.all([
                    ::Promise(function (resolve, reject) { resolve(1) }),
                    @() ::Promise(function (resolve, reject) { resolve(2) }),
                    ::Promise(function (resolve, reject) { })
                ]).then(function(res) { 
                    isResolved = true;
                }.bindenv(this), function(res) { 
                    isResolved = true;
                }.bindenv(this));
            // wait and verify pending state
            imp.wakeup(10, function() {
                isResolved ? err("Unexpected, Promise is resolved") : ok();
            });
        }.bindenv(this));
    }

    // all - finally

    function testAllFinally() {
        return Promise(function(ok, err) {
            local isResolved = false;
            ::Promise.all([
                    @() ::Promise(function (resolve, reject) { }),
                    @()::Promise(function (resolve, reject) { }),
                    ::Promise(function (resolve, reject) { resolve(1) })
                ]).finally(function(res) { 
                    isResolved = true;
                }.bindenv(this));
            // wait and verify pending state
            imp.wakeup(10, function() {
                isResolved ? err("Unexpected, Promise is resolved") : ok();
            });
        }.bindenv(this));
    }

    // serial - then

    function testSerialThen() {
        return Promise(function(ok, err) {
            local isResolved = false;
            ::Promise.serial([
                    @()::Promise(function (resolve, reject) { resolve(2) }),
                    ::Promise(function (resolve, reject) { resolve(1) }),
                    @() ::Promise(function (resolve, reject) { })
                ]).then(function(res) { 
                    isResolved = true;
                }.bindenv(this), function(res) { 
                    isResolved = true;
                }.bindenv(this));
            // wait and verify pending state
            imp.wakeup(10, function() {
                isResolved ? err("Unexpected, Promise is resolved") : ok();
            });
        }.bindenv(this));
    }

    // serial - finally

    function testSerialFinally() {
        return Promise(function(ok, err) {
            local isResolved = false;
            ::Promise.serial([
                    @()::Promise(function (resolve, reject) { resolve(2) }),
                    ::Promise(function (resolve, reject) { resolve(1) }),
                    @() ::Promise(function (resolve, reject) { })
                ]).finally(function(res) { 
                    isResolved = true;
                }.bindenv(this));
            // wait and verify pending state
            imp.wakeup(10, function() {
                isResolved ? err("Unexpected, Promise is resolved") : ok();
            });
        }.bindenv(this));
    }

    // loop - then

    function testLoopThen() {
        return Promise(function(ok, err) {
            local isResolved = false;
            ::Promise.loop(@() true, @() ::Promise(function (resolve, reject) { })).then(function(res) { 
                    isResolved = true;
                }.bindenv(this), function(res) { 
                    isResolved = true;
                }.bindenv(this));
            // wait and verify pending state
            imp.wakeup(10, function() {
                isResolved ? err("Unexpected, Promise is resolved") : ok();
            });
        }.bindenv(this));
    }

    // loop - finally

    function testLoopFinally() {
        return Promise(function(ok, err) {
            local isResolved = false;
            ::Promise.loop(@() true, @() ::Promise(function (resolve, reject) { })).finally(function(res) { 
                    isResolved = true;
                }.bindenv(this));
            // wait and verify pending state
            imp.wakeup(10, function() {
                isResolved ? err("Unexpected, Promise is resolved") : ok();
            });
        }.bindenv(this));
    }
}

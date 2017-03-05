// Copyright (c) 2017 Electric Imp
// This file is licensed under the MIT License
// http://opensource.org/licenses/MIT

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

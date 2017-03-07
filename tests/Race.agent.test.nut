// Copyright (c) 2016 Electric Imp
// This file is licensed under the MIT License
// http://opensource.org/licenses/MIT

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

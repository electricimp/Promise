// Copyright (c) 2016 Electric Imp
// This file is licensed under the MIT License
// http://opensource.org/licenses/MIT

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

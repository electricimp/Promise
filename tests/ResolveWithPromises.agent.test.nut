// Copyright (c) 2017 Electric Imp
// This file is licensed under the MIT License
// http://opensource.org/licenses/MIT

// "Promise" symbol is injected dependency from ImpUnit_Promise module,
// while class being tested can be accessed from global scope as "::Promise".

class ResolveWithPromisesTestCase extends ImpTestCase {

    // Test resolution of Promise with another Promise

    function testResolutionWithPromise() {
        return Promise(function(ok, err) {

            local p = ::Promise(function (resolve1, reject1) {
                resolve1(::Promise(function (resolve2, reject2) {
                    resolve2(::Promise(function (resolve3, reject3) {
                        resolve3("abc");
                    }));
                }));
            });

            p.then(function (res) {
                try {
                    this.assertEqual("abc", res);
                    ok();
                } catch (e) {
                    err(e);
                }
            }.bindenv(this));

        }.bindenv(this));
    }

    // Test resolution of Promise with another Promise and rejection in the end

    function testResolutionWithPromiseAndRejection() {
        return Promise(function(ok, err) {

            local p = ::Promise(function (resolve1, reject1) {
                resolve1(::Promise(function (resolve2, reject2) {
                    resolve2(::Promise(function (resolve3, reject3) {
                        reject3("abc");
                    }));
                }));
            });

            // when resolving with Promise
            // "then" handlers are not called
            // until resolution of the last
            // Promise in chain happens
            p.then(err);

            p.fail(function (v) {
                try {
                    this.assertEqual("abc", v);
                    ok();
                } catch (e) {
                    err(e);
                }
            }.bindenv(this));

        }.bindenv(this));
    }
}

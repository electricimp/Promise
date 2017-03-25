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

    // Test basic resolving

    function testBasicResolving() {
        return Promise(function(ok, err) {
            local isResolved = false;

            local p = ::Promise(function (resolve, reject) {
                resolve();
            });

            p.then(function(res) {isResolved = true;});

            // at this point Promise should not be resolved as it's body is handled in imp.wakeup(0)
            this.assertEqual(false, isResolved);

            // now it should be resolved
            imp.wakeup(0, function() {
                isResolved ? ok() : err("Promise is expected to be resolved");
            });

        }.bindenv(this));
    }

    // Test delayed resolving

    function testDelayedResolving() {
        return Promise(function(ok, err) {
            local p = ::Promise(function (resolve, reject) {
                imp.wakeup(0.1, function () {
                    resolve();
                }.bindenv(this));
            });

            p.then(ok);

        }.bindenv(this));
    }

    // Test delayed rejection

    function testDelayedRejection() {
        return Promise(function(ok, err) {
            local p = ::Promise(function (resolve, reject) {
                imp.wakeup(0.1, function () {
                    reject();
                }.bindenv(this));
            });

            p.fail(ok);

        }.bindenv(this));
    }

    // Test resolving with nested promises

    function testNestedResolve() {
        return Promise(function(ok, err) {
            local res = ::Promise.resolve.bindenv(::Promise);
            res(res(res("value")))
                .then(function(value) {
                    this.assertEqual(value, "value");
                    ok();
                }.bindenv(this)).fail(err);
        }.bindenv(this));
    }

}

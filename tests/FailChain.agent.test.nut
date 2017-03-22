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

class FailChainTestCase extends ImpTestCase {

    // Test a chain of `fail`s, with each thrown value being passed to the next
    // handler

    function testFailChaining() {
        return Promise(function(ok, err) {
            ::Promise.reject("reason")
                .fail(function(res) { throw res + 1})
                .fail(function(res) { throw res + 2})
                .fail(function(res) { throw res + 3})
                .fail(function(res) {
                    this.assertEqual(res, "reason123");
                    ok();
                }.bindenv(this)).fail(err);
        }.bindenv(this));
    }

    function testThenToFail() {
        return Promise(function(ok, err) {
            ::Promise.resolve("value")
                .then(function(v) { throw "reason"; })
                .fail(function(reason) {
                    this.assertEqual(reason, "reason");
                    ok();
                }.bindenv(this))
                .fail(err);
        }.bindenv(this));
    }

    function testFailToThen() {
        return Promise(function(ok, err) {
            ::Promise.reject("reason")
            .fail(function(reason) {
                return "value";
            }).then(function(value) {
                this.assertEqual(value, "value");
                ok();
            }.bindenv(this)).fail(err);
        }.bindenv(this));
    }
}

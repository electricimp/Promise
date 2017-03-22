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

// Case resolve - then(func, func) + fail(func) + finally()
class DifferentValues extends ImpTestCase {

    function _verifyTrue(condition, result, addMsg) {
        if (!condition) {
            result[1] = addMsg + result[1];
            result[0] = false;
        }
    }

    // Wrapper of Perform a deep comparison of two values
    // Useful for comparing arrays or tables
    // @param {*} expected
    // @param {*} actual
    // @param {string} message
    // @private
    function _assertDeepEqualWrap(expected, actual, message) {
        try {
            assertDeepEqual(expected, actual, message);
            return true;
        } catch (err) {
            server.log(err);
            return false;
        }
    }

    function _basicResolving(isDelyed, values) {
        local promises = [];
        foreach (value in values) {
            promises.append(
                ::Promise(function(ok, err) {
                    // State mask
                    // 1 - resolve handler is called
                    // 2 - value is wrong in resolve handler
                    // 4 - reject handler is called
                    // 8 - value is wrong in reject handler
                    // 16 - fail handler is called
                    // 32 - value is wrong in fail handler
                    // 64 - finally handler is called
                    // 128 - value is wrong in finally handlerx
                    local iState = 0;
                    local myValue = value;
                    local p = ::Promise(function (resolve, reject) {
                        if (isDelyed) { // delayed resolving
                            imp.wakeup(0.1, function () {
                                resolve(myValue);
                            }.bindenv(this));
                        } else { // basic resolving
                            resolve(myValue);
                        }
                    }.bindenv(this));
                    p.then(function(res) { 
                        iState = iState | 1; // 1 - resolve handler is called
                        if (_assertDeepEqualWrap(myValue, res, "Resolve handler - wrong value, value='" + myValue + "', res=" + res)) {
                            iState = iState | 2; // 2 - value is wrong in resolve handler
                        }
                    }.bindenv(this), function(res) { 
                        iState = iState | 4; // 4 - reject handler is called
                        if (_assertDeepEqualWrap(myValue, res, "Reject handler - wrong value, value='" + myValue + "', res=" + res)) {
                            iState = iState | 8; // 8 - value is wrong in reject handler
                        }
                    }.bindenv(this));
                    p.fail(function(res) { 
                        iState = iState | 16; // 16 - fail handler is called
                        if (_assertDeepEqualWrap(myValue, res, "Fail handler - wrong value, value='" + myValue + "', res=" + res)) {
                            iState = iState | 32; // 32 - value is wrong in fail handler
                        }
                    }.bindenv(this));
                    p.finally(function(res) {
                        iState = iState | 64; // 64 - finally handler is called
                        if (_assertDeepEqualWrap(myValue, res, "Finally handler - wrong value, value='" + myValue + "', res=" + res)) {
                            iState = iState | 128; // 128 - value is wrong in finally handler
                        }
                    }.bindenv(this));

                    // at this point Promise should not be resolved as it's body is handled in imp.wakeup(0)
                    assertEqual(0, iState, "The Promise should not be resolved strict after the promise declaration");
                    
                    // now it should be resolved
                    imp.wakeup(1 , function() {
                        local result = [true, "Value='" + myValue + "', iState=" + iState];
                        _verifyTrue(iState & 1, result, "Resolve handler is not called. ");
                        _verifyTrue(iState & 2, result, "Value is wrong in resolve handler. ");
                        _verifyTrue(iState & 64, result, "Finally handler is not called. ");
                        _verifyTrue(iState & 128, result, "Value is wrong in finally handler. ");
                        if (iState & 0X3C) { // 0011 1100 = 0X3C
                            err("Failed: unexpected handler call. " + result[1]);
                        } else if (result[0]) {
                            ok("Passed: " + result[1]);
                        } else {
                            err("Failed: " + result[1]);
                        }
                    }.bindenv(this));
                }.bindenv(this))
            );
        }
        return Promise(function(ok, err) {
            ::Promise.all(promises).then(ok, err);
        }.bindenv(this));
    }

    // Test basic resolving
    
    function testBasicResolving_1() {
        return _basicResolving(false, [true, false, 0]);
    }

    function testBasicResolving_2() {
        return _basicResolving(false, [1, -1]);
    }

    function testBasicResolving_3() {
        return _basicResolving(false, ["", "tmp"]);
    }

    function testBasicResolving_4() {
        return _basicResolving(false, [0.001, 0.0]);
    }

    function testBasicResolving_5() {
        return _basicResolving(false, [-0.001, regexp(@"(\d+) ([a-zA-Z]+)(\p)")]);
    }

    function testBasicResolving_6() {
        return _basicResolving(false, [null, blob(4)]);
    }

    function testBasicResolving_7() {
        return _basicResolving(false, [array(5), {
            firstKey = "Max Normal", 
            secondKey = 42, 
            thirdKey = true
        }]);
    }

    function testBasicResolving_8() {
        return _basicResolving(false, [function() {
            return 15;
        }, class {
            tmp = 0;
            constructor(){
                tmp = 15;
            }
        }]);
    }

    function testBasicResolving_9() {
        return _basicResolving(false, [server]);
    }

    // Test delayed resolving

    function testDelayedResolving_1() {
        return _basicResolving(true, [true, false, 0]);
    }

    function testDelayedResolving_2() {
        return _basicResolving(true, [1, -1]);
    }

    function testDelayedResolving_3() {
        return _basicResolving(true, ["", "tmp"]);
    }

    function testDelayedResolving_4() {
        return _basicResolving(true, [0.001, 0.0]);
    }

    function testDelayedResolving_5() {
        return _basicResolving(true, [-0.001, regexp(@"(\d+) ([a-zA-Z]+)(\p)")]);
    }

    function testDelayedResolving_6() {
        return _basicResolving(true, [null, blob(4)]);
    }

    function testDelayedResolving_7() {
        return _basicResolving(true, [array(5), {
            firstKey = "Max Normal", 
            secondKey = 42, 
            thirdKey = true
        }]);
    }

    function testDelayedResolving_8() {
        return _basicResolving(true, [function() {
            return 15;
        }, class {
            tmp = 0;
            constructor(){
                tmp = 15;
            }
        }]);
    }

    function testDelayedResolving_9() {
        return _basicResolving(true, [server]);
    }

    // Test resolving with nested promises

    function _nestedResolve(values) {
        local promises = [];
        foreach (nextValue in values) {
            local res = ::Promise.resolve.bindenv(::Promise);
            promises.append(
                ::Promise(function(ok, err) {
                    local myValue = nextValue;
                    res(res(res(myValue)))
                        .then(function(value) {
                            this.assertEqual(myValue, value);
                            ok();
                        }.bindenv(this)).fail(err);
                }.bindenv(this))
            );
        }
        return Promise(function(ok, err) {
            ::Promise.all(promises).then(ok, err);
        }.bindenv(this));
    }

    function testNestedResolve_1() {
        return _nestedResolve([true, false, 0, 1, -1, "", "tmp"]);
    }

    function testNestedResolve_2() {
        return _nestedResolve([0.001, 0.0, -0.001, regexp(@"(\d+) ([a-zA-Z]+)(\p)")]);
    }

    function testNestedResolve_3() {
        return _nestedResolve([null, blob(4), array(5), {
            firstKey = "Max Normal", 
            secondKey = 42, 
            thirdKey = true
        }, function() {
            return 15;
        }]);
    }

    function testNestedResolve_4() {
        return _nestedResolve([class {
            tmp = 0;
            constructor(){
                tmp = 15;
            }
            
        }, server]);
    }
}

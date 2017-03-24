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

//Case resolve - finally()
class ManyResolveRejectFin extends ImpTestCase {
    middleOfRand = 1.0 * RAND_MAX / 2;

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

    function _manyResolvingRejecting(isDelyed, values) {
        local promises = [];
        foreach (value in values) {
            promises.append(
                Promise(function(ok, err) {
                    // State mask
                    // 1 - resolve handler is called
                    // 2 - value is wrong in resolve handler
                    // 4 - reject handler is called
                    // 8 - value is wrong in reject handler
                    // 16 - fail handler is called
                    // 32 - value is wrong in fail handler
                    // 64 - finally handler is called
                    // 128 - value is wrong in finally handler
                    local iState = 0;
                    local myValue = value;
                    local strChain = "";

                    local cb = function (resolve, reject) { // many resolve/reject call
                        foreach (nextValue in values) {
                            local rnd = math.rand();
                            if (middleOfRand < rnd) {
                                strChain += "1";
                                resolve(nextValue);
                            } else {
                                strChain += "0";
                                reject(nextValue);
                            }
                        }
                    }.bindenv(this);

                    local p = ::Promise(function (resolve, reject) {
                        if (isDelyed) { // delayed resolving
                            imp.wakeup(0.1, function () {
                                resolve(myValue);
                                cb(resolve, reject); // many resolve/reject call
                            }.bindenv(this));
                        } else { // basic resolving
                            resolve(myValue);
                            cb(resolve, reject); // many resolve/reject call
                        }
                    }.bindenv(this));
                    p.finally(function(res) {
                        iState = iState | 64; // 64 - finally handler is called
                        if (_assertDeepEqualWrap(myValue, res, "Finally handler - wrong value, value=" + res)) {
                            iState = iState | 128; // 128 - value is wrong in finally handler
                        }
                    }.bindenv(this));

                    // at this point Promise should not be resolved as it's body is handled in imp.wakeup(0)
                    assertEqual(0, iState, "The Promise should not be resolved strict after the promise declaration");

                    // now it should be resolved
                    imp.wakeup(1, function() {
                        local result = [true, "Value='" + myValue + "', iState=" + iState+", RND=" + strChain];
                        _verifyTrue(iState & 64, result, "Finally handler is not called. ");
                        _verifyTrue(iState & 128, result, "Value is wrong in finally handler. ");
                        if (iState & 0X3F) { // 0011 1111 = 0X3F
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

    // Test resolving with many resolve/reject call

    function testBasicResolving_1() {
        return _manyResolvingRejecting(false, [true, false]);
    }

    function testBasicResolving_2() {
        return _manyResolvingRejecting(false, [0, 1]);
    }

    function testBasicResolving_3() {
        return _manyResolvingRejecting(false, [-1, ""]);
    }

    function testBasicResolving_4() {
        return _manyResolvingRejecting(false, ["tmp", 0.001]);
    }

    function testBasicResolving_5() {
        return _manyResolvingRejecting(false, [0.0, -0.001]);
    }

    function testBasicResolving_6() {
        return _manyResolvingRejecting(false, [regexp(@"(\d+) ([a-zA-Z]+)(\p)"), null]);
    }

    function testBasicResolving_7() {
        return _manyResolvingRejecting(false, [blob(4), array(5)]);
    }

    function testBasicResolving_8() {
        return _manyResolvingRejecting(false, [{
            firstKey = "Max Normal", 
            secondKey = 42, 
            thirdKey = true
        }, function() {
            return 15;
        }]);
    }

    function testBasicResolving_9() {
        return _manyResolvingRejecting(false, [class {
            tmp = 0;
            constructor(){
                tmp = 15;
            }
        }, server]);
    }

    // Test delayed resolving with many resolve/reject call

    function testDelayedResolving_1() {
        return _manyResolvingRejecting(true, [true, false]);
    }

    function testDelayedResolving_2() {
        return _manyResolvingRejecting(true, [0, 1]);
    }

    function testDelayedResolving_3() {
        return _manyResolvingRejecting(true, [-1, ""]);
    }

    function testDelayedResolving_4() {
        return _manyResolvingRejecting(true, ["tmp", 0.001]);
    }

    function testDelayedResolving_5() {
        return _manyResolvingRejecting(true, [0.0, -0.001]);
    }

    function testDelayedResolving_6() {
        return _manyResolvingRejecting(true, [regexp(@"(\d+) ([a-zA-Z]+)(\p)"), null]);
    }

    function testDelayedResolving_7() {
        return _manyResolvingRejecting(true, [blob(4), array(5)]);
    }

    function testDelayedResolving_8() {
        return _manyResolvingRejecting(true, [{
            firstKey = "Max Normal", 
            secondKey = 42, 
            thirdKey = true
        }, function() {
            return 15;
        }]);
    }

    function testDelayedResolving_9() {
        return _manyResolvingRejecting(true, [class {
            tmp = 0;
            constructor(){
                tmp = 15;
            }
        }, server]);
    }
}

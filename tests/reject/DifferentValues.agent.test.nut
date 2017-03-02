// Copyright (c) 2017 Electric Imp
// This file is licensed under the MIT License
// http://opensource.org/licenses/MIT

// "Promise" symbol is injected dependency from ImpUnit_Promise module,
// while class being tested can be accessed from global scope as "::Promise".

// Case reject - then(func, func) + fail(func) + finally()
class DifferentValues extends ImpTestCase {

    function _verifyTrue(condition, result, addMsg) {
        if (!condition) {
            result[1] = addMsg + result[1];
            result[0] = false;
        }
    }

    // Perform a deep comparison of two values
    // @param {*} value1
    // @param {*} value2
    // @param {string} message
    // @param {boolean} isForwardPass - on forward pass value1 is treated "expected", value2 as "actual" and vice-versa on backward pass
    // @param {string} path - current slot path
    // @param {int} level - current depth level
    // @private
    function _assertDeepEqualImpl(value1, value2, message, isForwardPass, path = "", level = 0) {
        local result = true;
        local cleanPath = @(p) p.len() == 0 ? p : p.slice(1);
        if (level > 2) {
            server.log("Possible cyclic reference at " + cleanPath(path));
            return false;
        }
        switch (type(value1)) {
            case "table":
            case "class":
            case "array":
                foreach (k, v in value1) {
                    path += "." + k;
                    if (!(k in value2)) {
                        server.log(format("%s slot [%s] in actual value",
                            isForwardPass ? "Missing" : "Extra", cleanPath(path)));
                        return false;
                    }
                    result = result && _assertDeepEqualImpl(value1[k], value2[k], message, isForwardPass, path, level + 1);
                }
                break;
            case "null":
                break;
            default:
                if (value2 != value1) {
                    server.log(format(message, cleanPath(path), value1 + "", value2 + ""));
                    return false;
                }
                break;
        }
        return result;
    }


    // Perform a deep comparison of two values
    // Useful for comparing arrays or tables
    // @param {*} expected
    // @param {*} actual
    // @param {string} message
    function _assertDeepEqual(expected, actual, message = "At [%s]: expected \"%s\", got \"%s\"") {
        return _assertDeepEqualImpl(expected, actual, message, true) // forward pass
            && _assertDeepEqualImpl(actual, expected, message, false); // backwards pass
    }

    function _basicRejection(isDelyed, values) {
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
                    // 128 - value is wrong in finally handlerx
                    local iState = 0;
                    local myValue = value;

                    local p = ::Promise(function (resolve, reject) {
                        if (isDelyed) { // delayed rejecting
                            imp.wakeup(0.1, function () {
                                reject(myValue);
                            }.bindenv(this));
                        } else { // basic rejecting
                            reject(myValue);
                        }
                    }.bindenv(this));
                    p.then(function(res) { 
                        iState = iState | 1; // 1 - resolve handler is called
                        if (_assertDeepEqual(myValue, res, "Resolve handler - wrong value, value=" + res)) {
                            iState = iState | 2; // 2 - value is wrong in resolve handler
                        }
                    }.bindenv(this), function(res) { 
                        iState = iState | 4; // 4 - reject handler is called
                        if (_assertDeepEqual(myValue, res, "Reject handler - wrong value, value=" + res)) {
                            iState = iState | 8; // 8 - value is wrong in reject handler
                        }
                    }.bindenv(this));
                    p.fail(function(res) { 
                        iState = iState | 16; // 16 - fail handler is called
                        if (_assertDeepEqual(myValue, res, "Fail handler - wrong value, value=" + res)) {
                            iState = iState | 32; // 32 - value is wrong in fail handler
                        }
                    }.bindenv(this));
                    p.finally(function(res) {
                        iState = iState | 64; // 64 - finally handler is called
                        if (_assertDeepEqual(myValue, res, "Finally handler - wrong value, value=" + res)) {
                            iState = iState | 128; // 128 - value is wrong in finally handler
                        }
                    }.bindenv(this));

                    // at this point Promise should not be rejected as it's body is handled in imp.wakeup(0)
                    assertEqual(0, iState, "The Promise should not be rejected strict after the promise declaration");

                    // now it should be resolved
                    imp.wakeup(isDelyed ? 0.2 : 0, function() {
                        local result = [true, "Value='" + myValue + "', iState=" + iState];
                        _verifyTrue(iState & 4, result, "Reject handler is not called. ");
                        _verifyTrue(iState & 8, result, "Value is wrong in reject handler. ");
                        _verifyTrue(iState & 16, result, "Fail handler is not called. ");
                        _verifyTrue(iState & 32, result, "Value is wrong in fail handler. ");
                        _verifyTrue(iState & 64, result, "Finally handler is not called. ");
                        _verifyTrue(iState & 128, result, "Value is wrong in finally handler. ");
                        if (iState & 0X03) { // 0000 0011 = 0X03
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

    // Test basic rejection     

    function testBasicRejection_1() {
        return _basicRejection(false, [true, false]);
    }

    function testBasicRejection_2() {
        return _basicRejection(false, [0, 1]);
    }

    function testBasicRejection_3() {
        return _basicRejection(false, [-1, ""]);
    }

    function testBasicRejection_4() {
        return _basicRejection(false, ["tmp", 0.001]);
    }

    function testBasicRejection_5() {
        return _basicRejection(false, [0.0, -0.001]);
    }

    function testBasicRejection_6() {
        return _basicRejection(false, [regexp(@"(\d+) ([a-zA-Z]+)(\p)"), null]);
    }

    function testBasicRejection_7() {
        return _basicRejection(false, [blob(4), array(5)]);
    }

    function testBasicRejection_8() {
        return _basicRejection(false, [{
            firstKey = "Max Normal", 
            secondKey = 42, 
            thirdKey = true
        }, function() {
            return 15;
        }]);
    }

    function testBasicRejection_9() {
        return _basicRejection(false, [class {
            tmp = 0;
            constructor(){
                tmp = 15;
            }
        }, server]);
    }


    // Test delayed rejection

    function testDelayedRejection_1() {
        return _basicRejection(true, [true, false]);
    }

    function testDelayedRejection_2() {
        return _basicRejection(true, [0, 1]);
    }

    function testDelayedRejection_3() {
        return _basicRejection(true, [-1, ""]);
    }

    function testDelayedRejection_4() {
        return _basicRejection(true, ["tmp", 0.001]);
    }

    function testDelayedRejection_5() {
        return _basicRejection(true, [0.0, -0.001]);
    }

    function testDelayedRejection_6() {
        return _basicRejection(true, [regexp(@"(\d+) ([a-zA-Z]+)(\p)"), null]);
    }

    function testDelayedRejection_7() {
        return _basicRejection(true, [blob(4), array(5)]);
    }

    function testDelayedRejection_8() {
        return _basicRejection(true, [{
            firstKey = "Max Normal", 
            secondKey = 42, 
            thirdKey = true
        }, function() {
            return 15;
        }]);
    }

    function testDelayedRejection_9() {
        return _basicRejection(true, [class {
            tmp = 0;
            constructor(){
                tmp = 15;
            }
        }, server]);
    }

    function _nestedReject(values) {
        local promises = [];
        foreach (nextValue in values) {
            promises.append( 
                ::Promise(function(ok, err) {
                    local myValue = nextValue;
                    local rej = ::Promise.reject.bindenv(::Promise);
                    local isThenCalled = false;
                    local isFailCalled = false;
                    rej(rej(rej(myValue)))
                    .then(err, function(value) {
                        this.assertDeepEqual(myValue, value, "Promise is rejected with wrong value, value=" + value);
                        isThenCalled = true;
                    }.bindenv(this))
                    .fail(function(value) {
                        this.assertDeepEqual(myValue, value, "Promise is rejected with wrong value, value=" + value);
                        isFailCalled = true;
                    }.bindenv(this));
                    imp.wakeup(0, function() {
                        local strFail = "";
                        if (isThenCalled !=true) {
                            strFail += "Function in the then(null, func) is not called, value=" + myValue;
                        } else if (isFailCalled != true) {
                            strFail += "Function in the fail(...) is not called, value=" + myValue;
                        }
                        if (!strFail.len()) {
                            err(strFail);
                        } else {
                            ok();
                        }
                    }.bindenv(this));
                }.bindenv(this))
            );
        }
        return Promise(function(ok, err) {
            ::Promise.all(promises).then(ok, err);
        }.bindenv(this));
    }

    // Test rejection with nested promises

    function testNestedReject_1() {
        return _nestedReject([true, false, 0]);
    }

    function testNestedReject_2() {
        return _nestedReject([1, -1, ""]);
    }

    function testNestedReject_3() {
        return _nestedReject(["tmp", 0.001, 0.0]);
    }

    function testNestedReject_4() {
        return _nestedReject([-0.001, regexp(@"(\d+) ([a-zA-Z]+)(\p)"), null]);
    }

    function testNestedReject_5() {
        return _nestedReject([blob(4), array(5), {
            firstKey = "Max Normal", 
            secondKey = 42, 
            thirdKey = true
        }]);
    }

    function testNestedReject_6() {
        return _nestedReject([function() {
            return 15;
        }, class {
            tmp = 0;
            constructor(){
                tmp = 15;
            }
            
        }, server]);
    }
}

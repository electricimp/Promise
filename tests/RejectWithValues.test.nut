/**
 * "Promise" symbol is injected dependency from ImpUnit_Promise module,
 * while class being tested can be accessed from global scope as "::Promise".
 */

class RejectWithValues extends ImpTestCase {
    values = [true, false, 0, 1, -1, "", "tmp", 0.001, 0.0, -0.001
        , regexp(@"(\d+) ([a-zA-Z]+)(\p)")
        , regexp2(@"(\d+) ([a-zA-Z]+)(\p)")
        , null, blob(4), array(5), {
            firstKey = "Max Normal", 
            secondKey = 42, 
            thirdKey = true
        }, function() {
            return 15;
        },  class {
            tmp = 0;
            constructor(){
                tmp = 15;
            }
            
        }, server];

    function _basicRejection(isDelyed) {
        local promises = [];
        foreach (value in values) {
            promises.append(Promise(function(ok, err) {
                // 0 - test is passed
                // 1 - rejected value is wrong
                // 2 - is not rejected
                local isThenRejected = 2;
                local isFailRejected = 2;

                local p = ::Promise(function (resolve, reject) {
                    if (isDelyed) { // delayed rejecting
                        imp.wakeup(0.1, function () {
                            reject(value);
                        }.bindenv(this));
                    } else { // basic rejecting
                        reject(value);
                    }
                }.bindenv(this));
                p.then(null, function(res) { 
                    if (value == res) {
                        isThenRejected = 0;
                    } else {
                        isThenRejected = 1;
                    }
                }.bindenv(this)).fail(function(res) { 
                    if (value == res) {
                        isFailRejected = 0;
                    } else {
                        isFailRejected = 1;
                    }
                }.bindenv(this));

                // at this point Promise should not be rejected as it's body is handled in imp.wakeup(0)
                this.assertEqual(2, isThenRejected, "The Promise should not be rejected strict after the promise declaration, value=" + value);
                this.assertEqual(2, isFailRejected, "The Promise should not be fialed strict after the promise declaration, value=" + value);

                // now it should be resolved
                imp.wakeup(isDelyed ? 0.2 : 0, function() {
                    if (isThenRejected == 0 && isFailRejected == 0) {
                        ok();
                    } else {
                        local strFail = "";
                        if (isThenRejected = 1) {
                            strFail += "Function in the then(null, func) is called with wrong value in then, value=" + value;
                        } else if (isThenRejected != 0) {
                            strFail += "Function in the then(null, func) is not called, value=" + value;
                        }
                        if (isFailRejected = 1) {
                            strFail += "Function in the fail(...) is called with wrong value in then, value=" + value;
                        } else if (isFailRejected != 0) {
                            strFail += "Function in the fail(...) is not called, value=" + value;
                        }
                        err(strFail);
                    }                    
                }.bindenv(this));
            }.bindenv(this)));
        }
        return promises;
    }

    /**
     * Test basic rejection
     */
    function testBasicRejection() {
        return Promise.all(_basicRejection(false));
    }

    /**
     * Test delayed rejection
     */
    function testDelayedRejection() {
        return Promise.all(_basicRejection(true));
    }


    /**
     * Test rejection with nested promises
     */
    function testNestedResolve() {
        local promises = [];
        local rej = ::Promise.reject.bindenv(::Promise);
        foreach (nextValue in values) {
            promises.append(Promise(function(ok, err) {
                local isThenCalled = false;
                local isFailCalled = false;
                rej(rej(rej(nextValue)))
                .then(err, function(value) {
                    this.assertDeepEqual(nextValue, value, , "Promise is rejected with wrong value, value=" + value);
                    isThenCalled = true;
                    ok();
                }.bindenv(this)).fail(function(value) {
                    this.assertDeepEqual(nextValue, value, , "Promise is rejected with wrong value, value=" + value);
                    isFailCalled = true;
                    ok();
                }.bindenv(this));
                imp.wakeup(isDelyed ? 0.2 : 0, function() {
                    local strFail = "";
                    if (isThenCalled !=true) {
                        strFail += "Function in the then(null, func) is not called, value=" + value;
                    } else if (isFailCalled != true) {
                        strFail += "Function in the fail(...) is not called, value=" + value;
                    }
                    if (!strFail.len()) {
                        err(strFail);
                    } else {
                        ok();
                    }
                }.bindenv(this);
            }.bindenv(this)));
        }
        return Promise.all(promises);
    }
}

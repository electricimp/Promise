/**
 * "Promise" symbol is injected dependency from ImpUnit_Promise module,
 * while class being tested can be accessed from global scope as "::Promise".
 */

class RejectManyCalls extends ImpTestCase {
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

    function _manyResolvingRejecting(isDelyed) {
        local promises = [];
        foreach (value in values) {
            promises.append(Promise(function(ok, err) {
                // 0 - test is passed
                // 1 - rejected value is wrong
                // 2 - is not rejected
                local isThenRejected = 2;
                local isFailRejected = 2;

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
                }.bindenv(this));

                local p = ::Promise(function (resolve, reject) {
                    if (isDelyed) { // delayed rejecting
                        imp.wakeup(0.1, function () {
                            reject(value);
                            cb(resolve, reject); // many resolve/reject call
                        }.bindenv(this));
                    } else { // basic rejecting
                        reject(value);
                        cb(resolve, reject); // many resolve/reject call
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
                this.assertEqual(2, isThenRejected, "The Promise should not be rejected strict after the promise declaration, value=" + value + ", strChain=" + strChain);
                this.assertEqual(2, isFailRejected, "The Promise should not be fialed strict after the promise declaration, value=" + value + ", strChain=" + strChain);

                // now it should be resolved
                imp.wakeup(isDelyed ? 0.2 : 0, function() {
                    if (isThenRejected == 0 && isFailRejected == 0) {
                        ok();
                    } else {
                        local strFail = "";
                        if (isThenRejected = 1) {
                            strFail += "Function in the then(null, func) is called with wrong value in then, value=" + value + ", strChain=" + strChain;
                        } else if (isThenRejected != 0) {
                            strFail += "Function in the then(null, func) is not called, value=" + value + ", strChain=" + strChain;
                        }
                        if (isFailRejected = 1) {
                            strFail += "Function in the fail(...) is called with wrong value in then, value=" + value + ", strChain=" + strChain;
                        } else if (isFailRejected != 0) {
                            strFail += "Function in the fail(...) is not called, value=" + value + ", strChain=" + strChain;
                        }
                        err(strFail);
                    }
                }.bindenv(this));
            }.bindenv(this)));
        }
        return promises;
    }

    /**
     * Test rejection with many resolve/reject call
     */
    function testBasicRejection() {
        return Promise.all(_manyResolvingRejecting(false));
    }

    /**
     * Test delayed rejection with many resolve/reject call
     */
    function testDelayedRejection() {
        return Promise.all(_manyResolvingRejecting(true));
    }
}

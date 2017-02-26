/**
 * "Promise" symbol is injected dependency from ImpUnit_Promise module,
 * while class being tested can be accessed from global scope as "::Promise".
 */

class ResolveManyCalls extends ImpTestCase {
    middleOfRand = 1.0 * RAND_MAX / 2;

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
            promises.append(
                Promise(function(ok, err) {
                    // 0 - test is passed
                    // 1 - resolved value is wrong
                    // 2 - is not resolved
                    // 3 - fail or then(...,func) is called
                    local isResolved = 2;
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
                        if (isDelyed) { // delayed resolving
                            imp.wakeup(0.1, function () {
                                resolve(value);
                                cb(resolve, reject); // many resolve/reject call
                            }.bindenv(this));
                        } else { // basic resolving
                            resolve(value);
                            cb(resolve, reject); // many resolve/reject call
                        }
                    }.bindenv(this));
                    p.then(function(res) { 
                        this.assertDeepEqual(value, res, "Promise is resolved with wrong value, value=" + value + ", strChain=" + strChain);
                        //TODO 
                        isResolved = 0;
                        /*if (value == res) {
                            isResolved = 0;
                        } else {
                            isResolved = 1;
                        }*/
                    }.bindenv(this), function(res) { 
                        isResolved = 3;
                    }).fail(function(res) { 
                        isResolved = 3;
                    }.bindenv(this));

                    // at this point Promise should not be resolved as it's body is handled in imp.wakeup(0)
                    this.assertEqual(2, isResolved, "The Promise should not be resolved strict after the promise declaration, value=" + value + ", strChain=" + strChain);

                    // now it should be resolved
                    imp.wakeup(isDelyed ? 0.2 : 0, function() {
                        if (isResolved == 0) {
                            ok();
                        } else if (isResolved = 1) {
                            err("Promise is resolved with wrong value, value=" + value + ", strChain=" + strChain);
                        } else if (isResolved = 3) {
                            err("Fail or then(.., func) is called, value=" + value + ", strChain=" + strChain);
                        } else {
                            err("Promise is expected to be resolved, value=" + value + ", strChain=" + strChain);
                        }
                    }.bindenv(this));
                })
            );
        }
        return promises;
    }

    /**
     * Test resolving with many resolve/reject call
     */
    function testBasicResolving() {
        return Promise.all(_manyResolvingRejecting(false));
    }

    /**
     * Test delayed resolving with many resolve/reject call
     */
    function testDelayedResolving() {
        return Promise.all(_manyResolvingRejecting(true));
    }

}

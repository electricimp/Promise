/**
 * "Promise" symbol is injected dependency from ImpUnit_Promise module,
 * while class being tested can be accessed from global scope as "::Promise".
 */

class Loop extends ImpTestCase {
    values = [false, 0, "", "tmp", 0.001
        , regexp(@"(\d+) ([a-zA-Z]+)(\p)")
        , null, blob(4), array(5), {
            firstKey = "Max Normal", 
            secondKey = 42, 
            thirdKey = true
        }, function() {
            return "w";
        },  class {
            tmp = 0;
            constructor(){
                tmp = 15;
            }
            
        }, server];

    function testWrongFirst() {
        local promises = [];
        foreach (value in values) {
            promises.append(
                ::Promise(function(ok, err) {
                    local _value = null;
                    try {
                        Promise.loop(value, @() ::Promise(function (resolve, reject) { resolve(2) })).then(function(res) { 
                            assertTrue(false, "Resolve handler is called");
                        }.bindenv(this), function(res) { 
                            _value = res;
                        }.bindenv(this));
                    } catch(err) {
                        assertTrue(false, "Unexpected error "+err);
                    }
                    imp.wakeup(0, function() {
                        if (_value == null) {
                            err("Fail with value="+value);
                        } else {
                            ok();
                        }
                    }.bindenv(this));
                }.bindenv(this))
            );
        }
        return ::Promise.all(promises);
    }

    function testWrongSecond() {
        local promises = [];
        foreach (value in values) {
            promises.append(
                ::Promise(function(ok, err) {
                    local _value = null;
                    try {
                        Promise.loop(@() true, value).then(function(res) { 
                            assertTrue(false, "Resolve handler is called");
                        }.bindenv(this), function(res) { 
                            _value = res;
                        }.bindenv(this));
                    } catch(err) {
                        assertTrue(false, "Unexpected error "+err);
                    }
                    imp.wakeup(0, function() {
                        if (_value == null) {
                            err("Fail with value="+value);
                        } else {
                            ok();
                        }
                    }.bindenv(this));
                }.bindenv(this))
            );
        }
        return ::Promise.all(promises);
    }

    function testWrongCoun_1() {
        local promises = [];
        this.assertTrue(true);
        foreach (value in values) {
            try {
                ::Promise.loop(value);
                this.assertTrue(false, "Exception is expected. Value="+value);
            } catch(err) {
            }
        }
    }

    function testWrongCoun_3() {
        local promises = [];
        this.assertTrue(true);
        foreach (value in values) {
            try {
                ::Promise.loop(value, value, value);
                this.assertTrue(false, "Exception is expected. Value="+value);
            } catch(err) {
            }
        }
    }
}

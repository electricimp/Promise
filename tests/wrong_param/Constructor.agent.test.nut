/**
 * "Promise" symbol is injected dependency from ImpUnit_Promise module,
 * while class being tested can be accessed from global scope as "::Promise".
 */

class Constructor extends ImpTestCase {

    function _wrongType(values) {
        local promises = [];
        foreach (value in values) {
            promises.append(
                ::Promise(function(ok, err) {
                    local myValue = value;
                    local msg = "with value='" + myValue + "'";
                    local _value = null;
                    local p = ::Promise(myValue);
                    p.then(function(res) { 
                        msg = "Resolve handler is called " + msg;
                    }.bindenv(this), function(res) { 
                        _value = res;
                    }.bindenv(this));
                    p.fail(function(res) { 
                        assertDeepEqual(_value, res, "Fail handler - wrong value, value=" + res);
                    }.bindenv(this));
                    p.finally(function(res) {
                        assertDeepEqual(_value, res, "Finally handler - wrong value, value=" + res);
                    }.bindenv(this));
                    imp.wakeup(0, function() {
                        if (_value == null) {
                            server.log("Fail " + msg);
                            err("Fail " + msg);
                        } else {
                            //server.log("Pass " + msg);
                            ok("Pass " + msg);
                        }
                    }.bindenv(this));
                }.bindenv(this))
            );
        }
        return Promise(function(ok, err) {
            ::Promise.all(promises).then(ok, err);
        }.bindenv(this));
    }

    function testWrongType_1() {
        return _wrongType([false, 0, ""]);
    }

    function testWrongType_2() {
        return _wrongType(["tmp", 0.001]);
    }

    function testWrongType_3() {
        return _wrongType([regexp(@"(\d+) ([a-zA-Z]+)(\p)"), null]);
    }

    function testWrongType_4() {
        return _wrongType([blob(4), array(5)]);
    }

    function testWrongType_5() {
        return _wrongType([{
            firstKey = "Max Normal", 
            secondKey = 42, 
            thirdKey = true
        }, function(fff) {
            return fff;
        }]);
    }

    function testWrongType_6() {
        return _wrongType([class {
            tmp = 0;
            constructor(){
                tmp = 15;
            }
        }, server]);
    }

    function testWrongCount() {
        local values = [false, 0, "", "tmp", 0.001
        , regexp(@"(\d+) ([a-zA-Z]+)(\p)")
        , null, blob(4), array(5), {
            firstKey = "Max Normal", 
            secondKey = 42, 
            thirdKey = true
        }, function() {
        },  class {
            tmp = 0;
            constructor(){
                tmp = 15;
            }
            
        }, server];
        foreach (value in values) {
            try {
                local p = ::Promise(value, value);
                this.assertTrue(false, "Exception is expected. Value="+value);
            } catch(err) {
            }
        }
    }
}

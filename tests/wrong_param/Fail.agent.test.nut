// Copyright (c) 2017 Electric Imp
// This file is licensed under the MIT License
// http://opensource.org/licenses/MIT

// "Promise" symbol is injected dependency from ImpUnit_Promise module,
// while class being tested can be accessed from global scope as "::Promise".

class Fail extends ImpTestCase {

    function _wrongType(values) {
        local promises = [];
        foreach (value in values) {
            promises.append(
                ::Promise(function(ok, err) {
                    local myValue = value;
                    local msg = "with value='" + myValue + "'";
                    local _value = null;
                    try {
                        ::Promise(function (resolve, reject) {
                            reject(1);
                        }).fail(myValue).fail(function(res) { 
                            _value = res;
                        }.bindenv(this));
                    } catch(err) {
                        msg = "Unexpected error " + ex + " " + msg;
                    }
                    imp.wakeup(1, function() {
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
        return _wrongType([false]);
    }

    function testWrongType_2() {
        return _wrongType([0, ""]);
    }

    function testWrongType_3() {
        return _wrongType(["tmp", 0.001
        , regexp(@"(\d+) ([a-zA-Z]+)(\p)")]);
    }

    function testWrongType_4() {
        return _wrongType([null, blob(4), array(5)]);
    }

    function testWrongType_5() {
        return _wrongType([{
            firstKey = "Max Normal", 
            secondKey = 42, 
            thirdKey = true
        }, function() {
        },  class {
            tmp = 0;
            constructor(){
                tmp = 15;
            }
            
        }]);
    }

    function testWrongType_6() {
        return _wrongType([server]);
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
                ::Promise(function (resolve, reject) {
                    reject(1);
                }).fail(value, value);
                this.assertTrue(false, "Exception is expected. Value="+value);
            } catch(err) {
            }
        }
    }
}

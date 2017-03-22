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

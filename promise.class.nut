/**
 * This file is licensed under the MIT License
 * http://opensource.org/licenses/MIT
 */

/**
 * Promise class for Squirrel (Electric Imp)
 * This file is licensed under the MIT License
 *
 * Initial version: 08-12-2015
 *
 * @see https://www.promisejs.org/implementing/
 *
 * @copyright (c) 2015 SMS Diagnostics Pty Ltd
 * @author Aron Steg
 * @author Mikhail Yurasov <mikhail@electricimp.com>
 */
class Promise {

    static version = [1, 0, 0];

    _state = null;
    _value = null;
    _handlers = null;
    
    constructor(fn) {

        const PROMISE_STATE_PENDING = 0;
        const PROMISE_STATE_FULFILLED = 1;
        const PROMISE_STATE_REJECTED = 2;

        _state = PROMISE_STATE_PENDING;
        _handlers = [];
        _doResolve(fn, _resolve, _reject);
    }
    
    // **** Private functions ****
    
    function _fulfill(result) {
        _state = PROMISE_STATE_FULFILLED;
        _value = result;
        foreach (handler in _handlers) {
            _handle(handler);
        }
        _handlers = null;
    }
    
    function _reject(error) {
        _state = PROMISE_STATE_REJECTED;
        _value = error;
        foreach (handler in _handlers) {
            _handle(handler);
        }
        _handlers = null;
    }    
    
    function _resolve(result) {
        try {
            local then = _getThen(result);
            if (then) {
                _doResolve(then.bindenv(result), _resolve, _reject);
                return;
            }
            _fulfill(result);
        } catch (e) {
            _reject(e);
        }
    }
    
   /**
    * Check if a value is a Promise and, if it is,
    * return the `then` method of that promise.
    *
    * @param {Promise|*} value
    * @return {function|null}
    */
    function _getThen(value) {

        if (
            // detect that the value is some form of Promise
            // by the fact it has .then() method
            (typeof value == "instance")
            && ("then" in value)
            && (typeof value.then == "function")
          ) {
            return value.then;
        }

        return null;
    }
    
    function _doResolve(fn, onFulfilled, onRejected) {
        local done = false;
        try {
            fn(
                function (value = null /* allow resolving without argument */) {
                    if (done) return;
                    done = true;
                    onFulfilled(value)
                }.bindenv(this), 
                
                function (reason = null /* allow rejection without argument */) {
                    if (done) return;
                    done = true;
                    onRejected(reason)
                }.bindenv(this)
            )
        } catch (ex) {
            if (done) return;
            done = true;
            onRejected(ex);
        }
    }

    function _handle(handler) {
        if (_state == PROMISE_STATE_PENDING) {
            _handlers.push(handler);
        } else {
            if (_state == PROMISE_STATE_FULFILLED && typeof handler.onFulfilled == "function") {
                handler.onFulfilled(_value);
            }
            if (_state == PROMISE_STATE_REJECTED && typeof handler.onRejected == "function") {
                handler.onRejected(_value);
            }
        }
    }
    
    // **** Public functions ****

    /**
     * Execute handler once the Promise is resolved/rejected
     * @param {function|null} onFulfilled
     * @param {function|null} onRejected
     */
    function then(onFulfilled = null, onRejected = null) {
        // ensure we are always asynchronous
        imp.wakeup(0, function () {
            _handle({ onFulfilled=onFulfilled, onRejected=onRejected });
        }.bindenv(this));

        return this;
    }

    /**
     * Execute handler on failure
     * @param {function|null} onRejected
     */
    function fail(onRejected = null) {
        return then(null, onRejected);
    }
    
    /**
     * Execute handler both on success and failure
     * @param {function|null} always
     */
    function finally(always = null) {
      return then(always, always);
    }
}

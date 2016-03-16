/**
 * Promise class for Squirrel (Electric Imp)
 * Licensed under the MIT License
 *
 * @see https://www.promisejs.org/implementing/
 * @author Aron Steg
 * @author Mikhail Yurasov <mikhail@electricimp.com>
 * @version 2.0.0-dev
 */
class Promise {

    static version = [2, 0, 0, "dev1"];

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

    /**
     * While loop with Promise's
     * Stops on continueCallback() == false or first rejection of looped Promise
     *
     * @param {function:boolean} condition - if returns false, loop stops
     * @param {function:Promise} next - function to get next promise in the loop
     * @return {Promise} Promise that is resolved/rejected with the last value that come from looped promise when loop finishes
     */
    static function loop(condition, next) {
        return (this)(function (resolve, reject) {

            local doLoop;
            local lastResolvedWith;

            doLoop = function() {
                if (condition()) {
                    next().then(
                        function (v) {
                            lastResolvedWith = v;
                            imp.wakeup(0, doLoop)
                        },
                        reject
                    );
                } else {
                    resolve(lastResolvedWith);
                }
            }

            imp.wakeup(0, doLoop);

        }.bindenv(this));
    }

    /**
     * Returns Promise that resolves when
     * all promises in chain resolve:
     * one after each other
     *
     * @param {{Promise|function}[]} promises - array of Promises/functions that return Promises
     * @return {Promise} Promise that is resolved/rejected with the last value that come from looped promise
     */
    static function serial(promises) {
        local i = 0;
        return this.loop(
            @() i < promises.len(),
            function () {
                return "function" == type(promises[i])
                    ? promises[i++]()
                    : promises[i++];
            }
        )
    }

    /**
     * Execute Promises in parallel and resolve when they are all done.
     * Returns Promise that resolves with last paralleled Promise value
     * or rejects with first rejected paralleled Promise value.
     *
     * @param {{Primise|functiuon}[]} promises
     * @returns {Promise}
     */
    static function parallel(promises) {
        return (this)(function (resolve, reject) {
            local resolved = 0;

            local checkDone = function(v = null) {
                if (resolved == promises.len()) {
                    resolve(v);
                    return true;
                }
            }

            if (!checkDone()) {
                for (local i = 0; i < promises.len(); i++) {
                    (
                        "function" == type(promises[i])
                            ? promises[i]()
                            : promises[i]
                    )
                    .then(function (v) {
                        resolved++;
                        checkDone(v);
                    }, reject);
                }
            }

        }.bindenv(this));
    }
}

/**
 * Promises for Squirrel (Electric Imp)
 *
 * @author Aron Steg
 * @author Mikhail Yurasov <mikhail@electricimp.com>
 *
  @version 2.0.0
 */
class Promise {
    static version = [2, 0, 0];

    static STATE_PENDING = 0;
    static STATE_RESOLVED = 1;
    static STATE_REJECTED = 2;

    _state = null;
    _value = null;

    /* @var {{resole, reject}[]} _handlers */
    _handlers = [];

    /**
    * @param {function(resolve, reject)} action - action function
    */
    constructor(action) {
        this._state = this.STATE_PENDING;

        try {
            action(
                this._resolve.bindenv(this)
                this._reject.bindenv(this)
            );
        } catch (e) {
            this._reject(e);
        }
    }

    /**
     * Execute chain of handlers
     */
    function _callHandlers() {
        if (this.STATE_PENDING != this._state) {
            foreach (handler in this._handlers) {
                (/* create closure and bind handler to it */ function (handler) {
                    if (this._state == this.STATE_RESOLVED && "resolve" in handler && "function" == type(handler.resolve)) {
                        imp.wakeup(0, function() { handler.resolve(this._value) }.bindenv(this));
                    } else if (this._state == this.STATE_REJECTED && "reject" in handler && "function" == type(handler.reject)) {
                        imp.wakeup(0, function() { handler.reject(this._value) }.bindenv(this));
                    }
                })(handler);
            }

            this._handlers = [];
        }
    }

    /**
     * Resolve promise with a value
     */
    function _resolve(value = null) {
        if (this.STATE_PENDING == this._state) {
            // if promise is resolved with another promise
            // let it resolve/reject this one,
            // otherwise resolve immideately
            if (this._isPromise(value)) {
                value.then(
                    this._resolve.bindenv(this),
                    this._reject.bindenv(this)
                );
            } else {
                this._state = this.STATE_RESOLVED;
                this._value = value;
                this._callHandlers();
            }
        }
    }

    /**
     * Reject promise for a reason
     */
    function _reject(reason = null) {
        if (this.STATE_PENDING == this._state) {
            this._state = this.STATE_REJECTED;
            this._value = reason;
            this._callHandlers();
        }
    }

   /**
    * Check if a value is a Promise.
    * @param {Promise|*} value
    * @return {boolean}
    */
    function _isPromise(value) {
        if (
            // detect that the value is some form of Promise
            // by the fact it has .then() method
            (typeof value == "instance")
            && ("then" in value)
            && (typeof value.then == "function")
          ) {
            return true
        }

        return false
    }

   /**
    * Add handlers on resolve/rejection
    * @param {function} onResolve
    * @param {function|null} onReject
    * @return {this}
    */
    function then(onResolve, onReject = null) {
        this._handlers.push({
            "resolve": onResolve
        })

        if (onReject) {
            this._handlers.push({
                "reject": onReject
            });
        }

        this._callHandlers();
        return this;
    }

   /**
    * Add handler on rejection
    * @param {function} onReject
    * @return {this}
    */
    function fail(onReject) {
        this._handlers.push({
            "reject": onReject
        });

        this._callHandlers();
        return this;
    }

   /**
    * Add handler that is executed both on resolve and rejection
    * @param {function} always
    * @return {this}
    */
    function finally(always) {
        this._handlers.push({
            "resolve": always,
            "reject": always
        });

        this._callHandlers();
        return this;
    }
}

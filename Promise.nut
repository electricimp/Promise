
class Promise {

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
    function _handle() {
        if (this.STATE_PENDING != this._state) {
            foreach (handler in this._handlers) {
                (/* create closure and bind handler to it */ function (handler) {
                    if (this._state == this.STATE_RESOLVED && "resolve" in handler) {
                        imp.wakeup(0, function() { handler.resolve(this._value) }.bindenv(this));
                    } else if (this._state == this.STATE_REJECTED && "reject" in handler) {
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
            this._state = this.STATE_RESOLVED;
            this._value = value;
            this._handle();
        }
    }

    /**
     * Reject promise for a reason
     */
    function _reject(reason = null) {
        if (this.STATE_PENDING == this._state) {
            this._state = this.STATE_REJECTED;
            this._value = reason;
            this._handle();
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

    //

    function then(onResolve, onReject = null) {
        this._handlers.push({
            "resolve": onResolve
        })

        if (onReject) {
            this._handlers.push({
                "reject": onReject
            });
        }

        this._handle();
        return this;
    }

    function fail(onReject) {
        this._handlers.push({
            "reject": onReject
        });

        this._handle();
        return this;
    }

    function finally(always) {
        this._handlers.push({
            "resolve": always,
            "reject": always
        });

        this._handle();
        return this;
    }
}

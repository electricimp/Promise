// Returns a function which expects `expected` as its argument, and complains
// otherwise
function expect(expected, ret = null) {
    return function(actual) {
        server.log((expected == actual)
            ? "PASSED"
            : "expected " + expected + " but got " + actual);
        return (ret == null) ? actual : ret;
    }
}

server.log("RUNNING TESTS");

// Value from onResolve can be thrown to next onReject
Promise.resolve("VALUE")
    .then(Promise.reject, Promise.resolve)
    .then(expect(null), expect("VALUE"));

// Value from onReject can flow through to next onResolve
Promise.reject("VALUE")
    .then(Promise.reject, Promise.resolve)
    .then(expect("VALUE"), expect(null));

// `fail` can pass to next `onResolve`
Promise.reject("ERROR")
    .fail(expect("ERROR", "VALUE"))
    .then(expect("VALUE"), expect(null));

// Empty `then`s just pass through
Promise.resolve("VALUE").then().then().then().then(expect("VALUE"));

// Returning nested promises works fine
Promise.resolve(Promise.resolve(Promise.resolve("VALUE"))).then(expect("VALUE"));

// Testing exceptions - note that exceptions MUST be thrown SYNCHRONOUSLY
Promise(function(resolve, reject) {
    throw "ERROR";
}).then(expect(null), expect("ERROR"));

// All rejects
Promise.all([Promise.resolve("VALUE"), Promise.reject("ERROR")])
    .then(expect(null), expect("ERROR"));

// Race passes resolution or rejection to the right handler
Promise.race([Promise.resolve("VALUE"), Promise.reject("ERROR")])
    .then(expect("VALUE"), expect("ERROR")); // either one could win the race

// Throw errors if you want to chain fails    
Promise.reject("ERROR1")
    .fail(function(err) {
        throw "ERROR2";
    }).fail(function(err) {
        throw "ERROR3";
    }).fail(expect("ERROR3"));
    
// // Simply return to handle an error
Promise.reject("ERROR1")
    .fail(function(err) {
        throw "ERROR2";
    }).fail(function(err) {
        return "VALUE";
    }).then(expect("VALUE"));

// `Then` can throw error to be caught by `fail`
Promise.resolve("VALUE")
    .then(function(val) {
        throw "ERROR";
    }).fail(expect("ERROR"));
    
// "Uncaught" errors are NOT thrown! (this line should not cause anything to "happen")
Promise.reject("ERROR1");

// Errors inside of a promise constructor are REALLY thrown, unless we wrap it up in another promise
Promise.resolve(
    Promise(function(res, rej){
        throw "ERROR";
    })
).fail(expect("ERROR"));

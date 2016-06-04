#require "Promise.class.nut:3.0.0"

/**
 * Example of resolving Promise after 1 second timeout
 * @return {Promise}
 */
function a() {
    return Promise(function(resolve, reject) {
        imp.wakeup(1, function() {
          resolve("A");
        });
    });
}

/**
 * Example of resolving Promise with another Promise
 * @return {Promise}
 */
function b() {
    return Promise(function(resolve, reject) {
        resolve(Promise(function(resolve, reject) {
          // finally rejecting it
          reject("B");
        }));
    });
}

a().then(function(e) {
    server.log("a: resolved with \"" + e + "\"")
})
.fail(function(e) {
    server.log("a: failed with \"" + e + "\"")
});

b().then(/* ok callback */ function(e) {
  server.log("b: resolved with \"" + e + "\"")
}, /* error callback */function(e) {
  server.log("b: failed with \"" + e + "\" (handler #1)")
  throw e;
})
.fail(function(e) {
  server.log("b: failed with \"" + e + "\" (handler #2)")
})
.finally(function(e) {
  server.log("b: finally()")
});

/*

Should produce the following output:

b: failed with "B" (handler #1)
b: failed with "B" (handler #2)
b: finally()
(1 second delay)
a: resolved with "A"

*/

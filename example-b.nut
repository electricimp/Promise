// Promise class is supposed to be available at this point

function a() {
    return Promise(function(resolve, reject) {
        imp.wakeup(1, function() {
          resolve("A");
        });
    });
}

// resolving promise with another promise
function b() {
    return Promise(function(resolve, reject) {
        resolve(Promise(function(resolve, reject) {
          reject("B");
        }));
    });
}

a().then(function(e) {
    server.log("ok: " + e);
}, function(e) {
    server.log("fail: " + e);
});

b().then(function(e) {
  server.log("ok: " + e);
}, function(e) {
  server.log("fail: " + e);
})
.fail(function(e) {
  server.log("b() fail")
})
.finally(function(e) {
  server.log("b() finally")
});

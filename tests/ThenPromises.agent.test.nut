
class ThenPromisesTestCase extends ImpTestCase {
    function test01() {
        return Promise(function(ok, err) {

            local promise = ::Promise(function (resolve, reject) {
                imp.wakeup(0.5, function() {
                    resolve("value 1");
                });
            });

            local promiseFunction = @(v) ::Promise(function (resolve, reject) {
                imp.wakeup(0.5, function() {
                    reject("value 2");
                    ok(); // xxx
                });
            });

            promise
                .then(function (v) {info("OK1:" + v)}.bindenv(this))
                .fail(function (v) {info("ERR1:" + v)}.bindenv(this))
                .then(promiseFunction)
                .then(function (v) {info("OK2:" + v)}.bindenv(this))
                .fail(function (v) {info("ERR2:" + v)}.bindenv(this))

        }.bindenv(this));
    }
}

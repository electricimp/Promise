#require "Promise.class.nut:3.0.0"

// -----------------------------------------------------------------------------
// This class exposed a single method fire() which waits a second and then randomly fails or succeeds.
// It returns a Promise which will fire then() or fail() at the conclusion of execution.
//
class RandomFailure {

    function fire() {
        return Promise(function (fulfill, reject){
            imp.wakeup(1, function () {
                if (math.rand() % 9 == 0) {
                    reject("random");
                } else {
                    fulfill("ok");
                }
            }.bindenv(this));
        }.bindenv(this));
    }

}


// -----------------------------------------------------------------------------
// This application executes the class's fire() method repeatedly until it fails.
//
function go() {
    RandomFailure().fire()
    .then(
        function(res) {
            server.log(res);
            go();
        }
    )
    .fail(
        function(err) {
            server.log("Done");
        }
    )
}
go();

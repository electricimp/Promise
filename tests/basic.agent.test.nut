class BasicTestCase extends ImpTestCase {
  function testSomething() {
    return Promise(function (ok, err) {}).isPending();
  }
}

import { check, sleep } from 'k6';
import http from 'k6/http';

export const options = {
  stages: [
    { duration: '10s', target: 20 },
    { duration: '60s', target: 200 },
    { duration: '20s', target: 0 },
  ],
};

export default function () {
  let res = http.get('http://helloworld-csharp.hello-world.knative.knativetest.localhost/delay')
  check(res, { 'success': (r) => r.status === 200 })
  sleep(0.1)
}

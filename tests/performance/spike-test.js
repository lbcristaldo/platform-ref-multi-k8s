// Spike test to check system behavior under sudden load

import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '10s', target: 10 },    // Baseline
    { duration: '10s', target: 500 },   // SPIKE!
    { duration: '1m', target: 500 },    // Hold spike
    { duration: '10s', target: 10 },    // Recovery
    { duration: '30s', target: 10 },    // Observe recovery
  ],
  thresholds: {
    http_req_duration: ['p(95)<2000'],  // More lenient during spike
    http_req_failed: ['rate<0.10'],     // Allow more errors during spike
  },
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:3000';

export default function () {
  const res = http.get(`${BASE_URL}/health`);
  check(res, {
    'status is 200': (r) => r.status === 200,
  });
  
  sleep(0.5);  // Faster requests during spike
}

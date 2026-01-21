// Stress test to find breaking point

import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '2m', target: 100 },    // Ramp to normal load
    { duration: '5m', target: 200 },    // Push higher
    { duration: '5m', target: 300 },    // Keep pushing
    { duration: '5m', target: 400 },    // Break point?
    { duration: '2m', target: 0 },      // Recovery
  ],
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:3000';

export default function () {
  http.get(`${BASE_URL}/health`);
  sleep(1);
}

// k6 load testing script for chatapp

import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');
const messageLatency = new Trend('message_latency');

// Test configuration
export const options = {
  stages: [
    { duration: '1m', target: 10 },   // Warm up
    { duration: '3m', target: 50 },   // Ramp up
    { duration: '2m', target: 100 },  // Peak load
    { duration: '2m', target: 50 },   // Scale down
    { duration: '1m', target: 0 },    // Cool down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'],  // 95% of requests under 500ms
    http_req_failed: ['rate<0.01'],    // Error rate under 1%
    errors: ['rate<0.05'],             // Custom error rate under 5%
  },
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:3000';

export default function () {
  // Test 1: Health check
  const healthRes = http.get(`${BASE_URL}/health`);
  check(healthRes, {
    'health check status is 200': (r) => r.status === 200,
    'health check response is ok': (r) => JSON.parse(r.body).status === 'ok',
  }) || errorRate.add(1);

  sleep(1);

  // Test 2: Ready check
  const readyRes = http.get(`${BASE_URL}/ready`);
  check(readyRes, {
    'ready check status is 200': (r) => r.status === 200,
    'redis service ok': (r) => JSON.parse(r.body).services.redis === 'ok',
    'mongo service ok': (r) => JSON.parse(r.body).services.mongo === 'ok',
  }) || errorRate.add(1);

  sleep(1);

  // Test 3: Send message (WebSocket simulation via HTTP)
  const messageStart = Date.now();
  const messagePayload = JSON.stringify({
    user: `user_${__VU}`,
    message: `Test message ${Date.now()}`,
    room: 'test-room',
  });

  const messageRes = http.post(
    `${BASE_URL}/api/message`,
    messagePayload,
    {
      headers: { 'Content-Type': 'application/json' },
    }
  );

  const messageEnd = Date.now();
  messageLatency.add(messageEnd - messageStart);

  check(messageRes, {
    'message sent successfully': (r) => r.status === 200 || r.status === 201,
  }) || errorRate.add(1);

  sleep(2);
}

// Setup function (runs once per VU)
export function setup() {
  console.log('Starting load test...');
  console.log(`Target URL: ${BASE_URL}`);
  
  // Verify app is reachable
  const res = http.get(`${BASE_URL}/health`);
  if (res.status !== 200) {
    throw new Error(`App not reachable: ${res.status}`);
  }
  
  return { startTime: Date.now() };
}

// Teardown function
export function teardown(data) {
  const duration = (Date.now() - data.startTime) / 1000;
  console.log(`Load test completed in ${duration}s`);
}

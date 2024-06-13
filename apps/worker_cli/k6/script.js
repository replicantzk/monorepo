import http from 'k6/http';
import { sleep, check } from 'k6';

const URL = `${__ENV.OPENAI_BASE_URL}/chat/completions`;
const TOKEN = __ENV.OPENAI_API_KEY;
const MODEL = __ENV.WORKER_MODEL;
const STREAM = true;
const VUS = 5;

export const options = {
  scenarios: {
    contacts: {
      executor: 'constant-vus',
      vus: VUS,
      duration: '30s',
    },
  },
};

export const prompts = [
    "What was operation Barbarossa?",
    "Who is the best French leader in history?",
    "What ocean has the most biodiversity?",
    "What life is the in Antarctica?",
    "What is the largest industrial machine?"
];

function getRandomPrompt() {
  const randomIndex = Math.floor(Math.random() * prompts.length);
  return prompts[randomIndex];
};

export default function() {
  const prompt = getRandomPrompt();
  const params = {
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${TOKEN}`
    },
  };
  const messages = [
    {
        "role": "user",
        "content": prompt
    }
  ];
  const body = JSON.stringify({
    model: MODEL,
    messages: messages,
    temperature: 0,
    stream: STREAM
  });

  const res = http.post(URL, body, params);
  check(res, {
    'is status 200': (r) => r.status === 200,
  });
  sleep(1);
}

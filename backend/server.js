const express = require('express');
const path = require('path');
const { initializeApp, cert } = require('firebase-admin/app');
const { getMessaging } = require('firebase-admin/messaging');
const app = express();
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

let firebaseApp = null;

if (process.env.FIREBASE_SERVICE_ACCOUNT) {
  firebaseApp = initializeApp({
    credential: cert(JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT))
  });
  console.log('firebase admin initialized');
} else {
  console.log('FIREBASE_SERVICE_ACCOUNT is missing');
}

app.use((req, res, next) => {
  res.header("Access-Control-Allow-Origin", "*");
  res.header("Access-Control-Allow-Headers", "Content-Type");
  res.header("Access-Control-Allow-Methods", "GET,POST");
  next();
});

const PASSWORD = "1234";

let currentOperation = "add";
let lastResult = null;
let deviceToken = null;

app.post('/register-token', (req, res) => {
  deviceToken = req.body.token;
  console.log('token registered:', deviceToken);
  res.json({ success: true });
});

app.post('/login', (req, res) => {
  const { password } = req.body;
  if (password === PASSWORD) {
    res.json({ success: true });
  } else {
    res.json({ success: false });
  }
});

app.post('/operation', (req, res) => {
  const { type } = req.body;
  currentOperation = type;
  res.json({ success: true, currentOperation });
});

app.get('/operation', (req, res) => {
  res.json({ currentOperation });
});

app.post('/calculate', (req, res) => {
  const num1 = Number(req.body.num1);
  const num2 = Number(req.body.num2);
  const operation = currentOperation;

  console.log('calculate called:', num1, operation, num2, 'deviceToken:', deviceToken);

  lastResult = null;
  res.json({ received: true });

  setTimeout(() => {
    lastResult = calculate(num1, num2, operation);
    sendNotification(lastResult);
  }, 60000);
});

app.get('/result', (req, res) => {
  if (lastResult === null) {
    res.json({ ready: false });
  } else {
    res.json({ ready: true, result: lastResult });
  }
});

function sendNotification(result) {
  console.log('sendNotification called, deviceToken:', deviceToken);

  if (!deviceToken) {
    console.log('no device token, skipping notification');
    return;
  }

  const body = result.error ? result.error : "الناتج: " + result.value;

  getMessaging(firebaseApp).send({
    token: deviceToken,
    notification: {
      title: "النتيجة",
      body: body
    }
  }).then(() => {
    console.log('notification sent successfully');
  }).catch((err) => {
    console.log('notification error', err.message);
  });
}

function calculate(num1, num2, type) {
  if (type === 'add') {
    return { value: num1 + num2 };
  }
  if (type === 'sub') {
    return { value: num1 - num2 };
  }
  if (type === 'mul') {
    return { value: num1 * num2 };
  }
  if (type === 'div') {
    if (num2 === 0) {
      return { error: "لا يمكن القسمة على صفر" };
    }
    return { value: num1 / num2 };
  }
  if (type === 'pow') {
    let result = 1;
    for (let i = 0; i < num2; i++) {
      result = result * num1;
    }
    return { value: result };
  }
  return { error: "عملية غير معروفة" };
}

const port = process.env.PORT || 4000;
app.listen(port, () => {
  console.log('Server running on port ' + port);
});

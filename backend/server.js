const express = require('express');
const path = require('path');
const app = express();
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

app.use((req, res, next) => {
  res.header("Access-Control-Allow-Origin", "*");
  res.header("Access-Control-Allow-Headers", "Content-Type");
  res.header("Access-Control-Allow-Methods", "GET,POST");
  next();
});

const PASSWORD = "1234";

let currentOperation = "add";
let lastResult = null;

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

  lastResult = null;
  res.json({ received: true });

  setTimeout(() => {
    lastResult = calculate(num1, num2, operation);
  }, 60000);
});

app.get('/result', (req, res) => {
  if (lastResult === null) {
    res.json({ ready: false });
  } else {
    res.json({ ready: true, result: lastResult });
  }
});

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

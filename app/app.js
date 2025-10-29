const express = require("express");
const mysql = require("mysql2");
const app = express();
const port = 3000;

// Database connection details (these will come from environment variables)
const db = mysql.createConnection({
  host: process.env.DB_HOST || "localhost",
  user: process.env.DB_USER || "admin",
  password: process.env.DB_PASS || "admin1234",
  database: process.env.DB_NAME || "appdb"
});

// Connect to database
db.connect(err => {
  if (err) {
    console.error("❌ Database connection failed:", err);
  } else {
    console.log("✅ Connected to RDS database");
  }
});

// Simple API
app.get("/", (req, res) => {
  res.send("Hello from CloudInfra Automator + RDS 🚀");
});

// Fetch data test route
app.get("/test-db", (req, res) => {
  db.query("SELECT NOW() AS current_time", (err, results) => {
    if (err) {
      res.send("DB Error: " + err);
    } else {
      res.send("DB Connected ✅ | Current time: " + results[0].current_time);
    }
  });
});

app.listen(port, () => {
  console.log(`App running on http://localhost:${port}`);
});


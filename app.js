const express = require("express");
const bodyParser = require("body-parser");
const mongoose = require("mongoose");
const cookieParser = require("cookie-parser");
const dotenv = require("dotenv");

const app = express();

const userRoutes = require("./routes/user");

dotenv.config();

mongoose
  .connect(process.env.MONGO_URI)
  .then(() => console.log("MongoDB Connected..."))
  .catch((err) => console.log(err));

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
app.use(cookieParser());

app.get("/api/ping", (req, res) => {
  res.send("pong");
  console.log(req.body);
});

app.use("/api/users", userRoutes);

app.use((err, req, res) => {
  const status = err.statusCode || 500;
  const message = err.message || "Something went wrong.";
  res.status(status).json({ message: message });
});

// port
app.listen(process.env.PORT, () => {
  console.log(`Connecting to PORT ${process.env.PORT}...`);
});
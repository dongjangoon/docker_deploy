const express = require("express");
const mongoose = require("mongoose");
const cookieParser = require("cookie-parser");
const dotenv = require("dotenv");

const app = express();

const pingRouter = require("./routes/PingRouter");
const userRouter = require("./routes/UserRouter");
const postRouter = require("./routes/PostRouter");

dotenv.config();

mongoose
  .connect(process.env.MONGO_URI)
  .then(() => console.log("MongoDB Connected..."))
  .catch((err) => console.log(err));

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cookieParser());

// route
app.use("/api/ping", pingRouter);
app.use("/api/users", userRouter);
app.use("/api/posts", postRouter);

// error handling
app.use((err, req, res) => {
  const status = err.statusCode || 500;
  const message = err.message || "Something went wrong.";
  res.statusCode(status).json({ message: message });
});

// port
app.listen(process.env.PORT, () => {
  console.log(`Connecting to PORT ${process.env.PORT}...`);
});

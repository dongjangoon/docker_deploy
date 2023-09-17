const express = require("express");
const router = express.Router();

const { User } = require("../models/User");
const { auth } = require("../middleware/Auth");

// get all users
router.get("/", async (req, res, next) => {
  try {
    const users = await User.find();
    res.status(200).json({ users });
  } catch (err) {
    next(err);
  }
});

// logout
router.get("/logout", auth, (req, res) => {
  User.findOneAndUpdate({ email: req.user.email }, { token: "" })
    .then(() => {
      return res.status(200).json({
        success: true,
        message: "logout success",
      });
    })
    .catch((err) => {
      return res.json({ success: false, err });
    });
});

// auth
router.get("/auth", auth, (req, res) => {
  res.status(200).json({
    _id: req.user._id,
    isAuth: true,
    email: req.user.email,
    name: req.user.name,
  });
});

// get a user by email
router.get("/:email", async (req, res, next) => {
  try {
    const userByEmail = await User.findOne({ email: req.params.email });
    res.status(200).json({ userByEmail });
  } catch (err) {
    next(err);
  }
});

// register
router.post("/", async (req, res, next) => {
  const user = new User(req.body);

  // validation logic

  // save logic
  try {
    await user.save();
    res.status(201).json({ message: "User created successfully.", user });
  } catch (err) {
    next(err);
  }
});

// login
router.post("/login", async (req, res) => {
  const user = await User.findOne({ email: req.body.email });

  if (!user) {
    return res.json({
      loginSuccess: false,
      message: "Auth failed, email not found.",
    });
  }

  user.comparePassword(req.body.password, (err, isMatch) => {
    if (!isMatch) {
      return res.json({
        loginSuccess: false,
        message: "Wrong password.",
      });
    }

    user.generateToken((err, user) => {
      if (err) return res.status(400).send(err);
      res
        .cookie("hasVisited", user.token)
        .status(201)
        .json({ loginSuccess: true, userId: user._id });
    });
  });
});

module.exports = router;

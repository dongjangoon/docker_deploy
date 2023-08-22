const mongoose = require("mongoose");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");

const userSchema = mongoose.Schema({
  email: { type: String, trim: true, unique: 1, required: true },
  password: { type: String, minlength: 8, required: true },
  name: { type: String, maxlength: 50, required: true },
  token: { type: String },
  tokenExp: { type: Number },
});

userSchema.pre("save", function (next) {
  const user = this;

  if (user.isModified("password")) {
    bcrypt.genSalt(10, function (err, salt) {
      if (err) return next(err);
      bcrypt.hash(user.password, salt, function (err, hash) {
        if (err) return next(err);
        user.password = hash;
        next();
      });
    });
  } else {
    next();
  }
});

userSchema.methods.comparePassword = function (plainPassword, cb) {
  bcrypt.compare(plainPassword, this.password, (err, isMatch) => {
    if (err) cb(err);
    cb(null, isMatch);
  });
};

userSchema.methods.generateToken = function (cb) {
  const user = this;
  const token = jwt.sign(user.email, "createToken");

  user.token = token;
  user
    .save()
    .then((user) => cb(null, user))
    .catch((err) => cb(err));
};

userSchema.static("findByToken", function (token, cb) {
  const user = this;
  const verified = jwt.verify(token, "createToken");

  user
    .findOne({ email: verified, token: token })
    .then((user) => {
      cb(null, user);
    })
    .catch((err) => cb(err));
});

const User = mongoose.model("User", userSchema);

module.exports = { User };

const { Router } = require("express");
const router = Router();

const { Post } = require("../models/Post");

router.get("/", async (req, res, next) => {
  try {
    const posts = await Post.find();
    res.status(200).json(posts);
  } catch (err) {
    next(err);
  }
});

router.post("/", async (req, res, next) => {
  const post = new Post(req.body)
  try {
    await post.save();
    res.status(201).json(post);
  } catch (err) {
    next(err);
  }
});

router.get("/search", async (req, res, next) => {
  const { content } = req.query;
  try {
    const posts = await Post.find({ content: { $regex: content } });
    res.status(200).json(posts);
  } catch (err) {
    next(err);
  }
});

module.exports = router;

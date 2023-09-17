const { Router } = require("express");
const router = Router();

router.get("/", (req, res) => {
  res.send("pong");
  console.log(req.body);
});

module.exports = router;

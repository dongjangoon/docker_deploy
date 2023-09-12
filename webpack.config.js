const path = require("path");
const nodeExternals = require('webpack-node-externals')

module.exports = {
  mode: "production",
  entry: "./app.js",
  output: {
    path: path.join(__dirname, "dist"),
    publicPath: "/",
    filename: "final.js",
  },
  target: "node",
  externalsPresets: { node: true },
  externals: [nodeExternals()]
};

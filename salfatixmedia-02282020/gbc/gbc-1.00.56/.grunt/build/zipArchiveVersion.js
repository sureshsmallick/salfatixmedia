/// FOURJS_START_COPYRIGHT(D,2015)
/// Property of Four Js*
/// (c) Copyright Four Js 2015, 2019. All Rights Reserved.
/// * Trademark of Four Js Development Tools Europe Ltd
///   in the United States and elsewhere
/// 
/// This file can be modified by licensees according to the
/// product manual.
/// FOURJS_END_COPYRIGHT

"use strict";

module.exports = function(grunt) {
  const path = require("path"),
    fs = require("fs");
  return `${fs.readFileSync(path.join(grunt.__pwd, "VERSION"), "utf8").trim()}.${grunt.__gbc.config.customizationSuffix || "c"}`;
};

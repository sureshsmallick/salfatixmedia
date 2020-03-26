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

const path = require("path");

const getDist = (p, def) => {
  p = p || def || "web";
  return path.isAbsolute(p) ? p : `dist/${p}/`;
};

module.exports = (grunt) => {
  require("../common/buildinfo")(grunt);
  let cust = grunt.__gbc.config.customization;
  if (path.isAbsolute(cust || ".") && !grunt.__gbc.config.buildDist) {
    throw new Error("When providing customization as an absolute path, please provide build-dist as well");
  }
  grunt.__gbc.pathes = grunt.__gbc.pathes || {
    distWeb: getDist(cust ?
      (grunt.__gbc.config.buildDist || cust) : grunt.__gbc.config.buildDist)
  };
  grunt.__gbc.pathes.distWebFlat = grunt.__gbc.pathes.distWeb.replace(/[\\\/]/g, "_");

  grunt.__gbc.pathes.platformBootstrap = {
    "gbc.bootstrap.js": "src/js/sysinit/gbc.bootstrap.js"
  };

  grunt.__gbc.pathes.sources = grunt.file.readJSON(path.join(__dirname, "./codebase.sources.json"));
  grunt.__gbc.pathes.templates = ["src/js/**/*.tpl.html"];
  grunt.__gbc.pathes.locales = ["src/locales/**/*.json"];

  if (grunt.__gbc.config.customization && grunt.__gbc.config.customization !== "ALL") {
    grunt.__gbc.pathes.customizationPath = grunt.__gbc.config.customizationPath;
    grunt.__gbc.pathes.customizationRelPath = path.relative(grunt.__pwd, grunt.__gbc.config.customizationPath);
    grunt.__gbc.pathes.sources.push(path.join(grunt.__gbc.pathes.customizationRelPath, "js/**/*.js"));
    grunt.__gbc.pathes.templates.push(path.join(grunt.__gbc.pathes.customizationRelPath, "js/**/*.tpl.html"));
    grunt.__gbc.pathes.locales.push(path.join(grunt.__gbc.pathes.customizationRelPath, "locales/**/*.json"));
  }
  grunt.__gbc.pathes.sources.push("src/js/sysinit/gbcStart.js");

  return grunt.__gbc.pathes;
};

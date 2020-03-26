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
  var getBuildNumber = function() {
    return grunt.template.date(new Date().getTime(), "yyyymmddHHMM");
  };

  var path = require("path"),
    fs = require("fs");
  grunt.config.merge({
    replace: {
      version: {
        src: [
          path.join(grunt.__gbc.pathes.distWeb, "VERSION"),
          path.join(grunt.__gbc.pathes.distWeb, "PRODUCTINFO"),
          path.join(grunt.__gbc.pathes.distWeb, "js/gbc.js"),
          path.join(grunt.__gbc.pathes.distWeb, "src/js/sysinit/gbc.js")
        ],
        overwrite: true,
        replacements: [{
          from: "%%YEAR%%",
          to: function() {
            return new Date().getFullYear();
          }
        }, {
          from: "%%VERSION%%",
          to: function() {
            var version = fs.readFileSync(path.join(grunt.__pwd, "VERSION"), "utf8").trim();
            return `${version}.${grunt.__gbc.config.customizationSuffix || "c"}`;
          }
        }, {
          from: "%%BUILD%%",
          to: function() {
            return getBuildNumber();
          }
        }, {
          from: "%%TAG%%",
          to: function() {
            var version = fs.readFileSync(path.join(grunt.__pwd, "VERSION"), "utf8").trim();
            return `${version.replace("\n", "")}.${grunt.__gbc.config.customizationSuffix || "c"}`;
          }
        }, {
          from: "%%DIRTY%%",
          to: function() {
            return "";
          }
        }]
      },
      prod: {
        src: [
          path.join(grunt.__gbc.pathes.distWeb, "js/gbc.js"),
          path.join(grunt.__gbc.pathes.distWeb, "src/js/sysinit/gbc.js")
        ],
        overwrite: true,
        replacements: [{
          from: "%%PROD%%",
          to: function() {
            return grunt.__gbc.config.compileMode;
          }
        }]
      }
    }
  });
  grunt.loadNpmTasks("grunt-text-replace");

  grunt.registerTask("__injection", ["gitinfo", "replace:version", "replace:prod"]);
};

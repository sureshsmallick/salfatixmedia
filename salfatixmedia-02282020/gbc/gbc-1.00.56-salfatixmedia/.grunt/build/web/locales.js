/// FOURJS_START_COPYRIGHT(D,2014)
/// Property of Four Js*
/// (c) Copyright Four Js 2014, 2019. All Rights Reserved.
/// * Trademark of Four Js Development Tools Europe Ltd
///   in the United States and elsewhere
/// 
/// This file can be modified by licensees according to the
/// product manual.
/// FOURJS_END_COPYRIGHT

"use strict";

module.exports = function(grunt) {
  const
    _ = require("lodash"),
    path = require("path"),
    fs = require("fs");
  grunt.registerMultiTask('__localesdeploy', 'Deploy locales on dist', function() {
    var computedLocales = {};
    this.files.forEach(function(files) {
      files.src.map(function(file) {
        var localeName = path.basename(file, ".json");
        var contents = {};
        try {
          contents = JSON.parse(fs.readFileSync(file));
        } catch (e) {
          console.log("malformed language file : " + file);
        }
        computedLocales[localeName] = _.merge(computedLocales[localeName] || {}, contents);
      });
      var finalLocales = {};
      for (var k in computedLocales) {
        finalLocales[k] = {
          translation: computedLocales[k]
        };
      }
      fs.writeFileSync(files.dest, 'this["gbcLocales"]=' + JSON.stringify(finalLocales));
    });
  });
  grunt.config.merge({
    __localesdeploy: {
      files: {
        src: grunt.__gbc.pathes.locales,
        dest: path.join(grunt.__gbc.pathes.distWeb, "js/compiledLocales.js")
      }
    }
  });
  grunt.registerTask("__locales", ["__localesdeploy"]);
};

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
  require("./build")(grunt);
  grunt.config.merge({
    watch: {
      options: {
        atBegin: true
      },
      src: {
        files: [
          "src/**/*",
          grunt.__gbc.pathes.customizationPath + "/**/*",
          "tests/**/*",
          "theme/**/*"
        ],
        tasks: ["__compile"]
      }
    }
  });
  grunt.loadNpmTasks("grunt-contrib-watch");

  grunt.registerTask("dev", ["watch:src"]);
};

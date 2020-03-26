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
  var path = require("path");
  grunt.config.merge({
    // use custom extension for the output file
    compress: {
      makegz: {
        options: {
          mode: 'gzip'
        },
        // Each of the files in the src/ folder will be output to
        // the dist/ folder each with the extension .gz.js
        files: [{
          expand: true,
          cwd: path.join(grunt.__gbc.pathes.distWeb, "./"),
          src: ["./**/*.*"],
          filter: function(f) {
            return !(/\.gz$/.test(f));
          },
          dest: path.join(grunt.__gbc.pathes.distWeb, "./"),
          rename: function(f, src) {
            return path.resolve(f, src + '.gz');
          }
        }]
      }
    }
  });
  grunt.loadNpmTasks("grunt-contrib-compress");

  grunt.registerTask("__makeGz", ["compress:makegz"]);
};

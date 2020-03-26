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
  const async = require('async');
  grunt.config.merge({
    __compileall: {
      files: {
        src: ["customization/*", "!customization/tests", "customization/tests/*", "!customization/customers",
          "customization/customers/*/*"
        ]
      }
    }
  });
  grunt.registerMultiTask("__compileall", "", function() {
    let done = this.async(),
      opts = [],
      parallelLimit = parseInt(grunt.option("parallel"), 10) || 1;

    if (grunt.option("create-zip")) {
      opts.push(" --create-zip");
    }
    if (grunt.option("compile-mode")) {
      opts.push("--compile-mode=" + grunt.option("compile-mode"));
    }
    if (grunt.option("themes")) {
      opts.push("--themes=" + grunt.option("themes"));
    }

    async.eachLimit(this.files, 1, (files, cb) => {
      let now = Date.now();
      console.log("compiling without customization");
      grunt.util.spawn({
        grunt: true,
        args: ["--customization=NONE", "--build-dist=web", ...opts]
      }, (error, result, code) => {
        if (code) {
          cb(error);
        } else {
          console.log("Done without customization (" + (Date.now() - now) + " ms)");
          async.eachLimit(files.src, parallelLimit, function(file, cb) {
            var now = Date.now();
            console.log("compiling with customization : " + file);
            grunt.util.spawn({
              grunt: true,
              args: [`--customization=${file}`, `--build-dist=${file}`, ...opts],
              opts: {
                stdio: ['inherit', 'inherit', 'inherit']
              }
            }, (error, result, code) => {
              if (code) {
                cb(error);
              } else {
                console.log("Done " + file + " (" + (Date.now() - now) + " ms)");
                cb();
              }
            });
          }, cb);
        }
      });
    }, done);
  });
};

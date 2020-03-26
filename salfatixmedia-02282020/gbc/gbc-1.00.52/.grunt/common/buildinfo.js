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

module.exports = grunt => {

  const
    _ = require("lodash"),
    fs = require("fs"),
    path = require("path"),
    spawnSync = require("child_process").spawnSync;

  const
    isReadableDirectory = dir => {
      try {
        fs.accessSync(dir, fs.R_OK | fs.X_OK);
        return fs.statSync(dir).isDirectory();
      } catch (e) {
        return false;
      }
    },
    resolveCustomizationPath = custName => {
      let result = null;
      if (path.isAbsolute(custName)) {
        if (isReadableDirectory(custName)) {
          result = [custName, custName];
        }
      } else {
        let custPath = path.join(grunt.__pwd, custName);
        if (isReadableDirectory(custPath)) {
          result = [custName, custPath];
        } else {
          custPath = path.join(grunt.__pwd, "customization", custName);
          if (isReadableDirectory(custPath)) {
            result = [path.join("customization", custName), custPath];
          }
        }
      }
      if (!result) {
        throw new Error(`Customization '${custName}' does not exist.`);
      }
      return result;
    },
    configMerge = (objValue, srcValue, key) => key === "themes" && srcValue || Object.undefined;

  grunt.__gbc = grunt.__gbc || {
    config: {},
    configFile: {}
  };
  // local shortcuts
  let
    config = grunt.__gbc.config,
    confFile = grunt.__gbc.configFile = grunt.file.readJSON(path.join(__dirname, "../defaults.json"));
  try {
    _.mergeWith(grunt.__gbc.configFile, grunt.file.readJSON(grunt.option("configuration") || "custom.json"), configMerge);
  } catch (e) {
    //use fallback values
  }

  config.customization = grunt.option("customization") || confFile.compile.customization;
  if (config.customization === true) {
    config.customization = "customization/sample";
  }
  if (config.customization === "NONE") {
    config.customization = null;
  }
  if (config.customization && config.customization !== "ALL") {
    [config.customization, config.customizationPath] = resolveCustomizationPath(config.customization);

    var customizationConfig = path.join(config.customizationPath, "config.json");
    try {
      fs.accessSync(customizationConfig, fs.R_OK);
      _.mergeWith(grunt.__gbc.configFile, grunt.file.readJSON(customizationConfig), configMerge);
    } catch (e) {
      grunt.verbose.writeln(`no config.json found in ${config.customizationPath}`);
    }
  }

  config.compileMode = grunt.option("compile-mode") || confFile.compile.mode;
  config.htmlCacheQueryStringPart = grunt.option("html-cache") || confFile.compile.htmlCache ? "" : `t=${new Date().getTime()}`;

  config.themeConfiguration = grunt.option("theme-uses") ? [{
      name: grunt.option("theme-name") || "default",
      uses: grunt.option("theme-uses")
    }] :
    confFile.themes;
  if (!config.themeConfiguration || !config.themeConfiguration.length) {
    config.themeConfiguration = [{
      name: "default",
      uses: []
    }];
  }

  config.buildDist = grunt.option("build-dist") || grunt.__gbc.configFile.compile.buildDist;

  let getBuildNumber = () => grunt.template.date(new Date().getTime(), "yyyymmddHHMM");

  try {
    fs.accessSync(".git", fs.R_OK);
    grunt.config.set("gitinfo.currentVersionTimeStamp",
      spawnSync("git", ["log", "--pretty=format:%ct", "-n 1"], {
        encoding: "utf8"
      }).stdout);
    grunt.config.merge({
      gitinfo: {
        commands: {
          currentVersionTimeStamp: ["log", "--pretty=format:%ct", "-n 1"],
          currentVersionTag: ["name-rev", "--tags", "--name-only", "HEAD"],
          currentVersionChanges: ["diff", "--shortstat"]
        }
      }
    });
    grunt.loadNpmTasks("grunt-gitinfo", "gitinfo");

    getBuildNumber = () => grunt.template.date(Number(grunt.config.get("gitinfo.currentVersionTimeStamp")) * 1000, "yyyymmddHHMM");
  } catch (e) {
    grunt.registerTask("gitinfo", "", () => {});

  }
  grunt.config.set("gbcinfo.buildnumber", getBuildNumber());
  grunt.registerTask("getbuildnumber", "Get the build number", function() {
    grunt.log.writeln("BUILD=" + getBuildNumber());
  });
  grunt.registerTask("buildnumber", "Returns the current build number in format 'BUILD=<buildnumber>' on the console", ["gitinfo",
    "getbuildnumber"
  ]);
};

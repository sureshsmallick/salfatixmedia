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

class ThemeVariablesCompiler {
  constructor(data) {
    this._data = data;
  }

  scssRender() {
    return this._scssVariablesRender() + `body:after{display:none;content:"{${this._scssJsonVariables()}}";}\n`;
  }
  _scssVariablesRender() {
    return this._scssVariables();
  }

  _scssVariables() {
    return this._keys.map(key => `$${key}:${this._data[key]};`).join("\n");
  }

  _scssJsonVariables() {
    return this._keys.map(key => `'${key}':` + ((typeof this._data[key] === "string") ? `'#{$${key}}'` : `#{$${key}}`)).join(",");
  }

  get _keys() {
    return Object.keys(this._data);
  }
}
module.exports = ThemeVariablesCompiler;

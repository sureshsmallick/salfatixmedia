/// FOURJS_START_COPYRIGHT(D,2015)
/// Property of Four Js*
/// (c) Copyright Four Js 2015, 2019. All Rights Reserved.
/// * Trademark of Four Js Development Tools Europe Ltd
///   in the United States and elsewhere
/// 
/// This file can be modified by licensees according to the
/// product manual.
/// FOURJS_END_COPYRIGHT

'use strict';

modulum('MenuLabelWidget', ['TextWidgetBase', 'WidgetFactory'],
  function(context, cls) {

    /**
     * MenuLabelWidget widget.
     * @class MenuLabelWidget
     * @memberOf classes
     * @extends classes.LabelWidget
     */
    cls.MenuLabelWidget = context.oo.Class(cls.LabelWidget, function($super) {
      /** @lends classes.MenuLabelWidget.prototype */
      return {
        __name: 'MenuLabelWidget',

        /** @type {HTMLElement}*/
        _imageContainer: null,
        /** @type {HTMLElement}*/
        _commentContainer: null,

        /**
         * @inheritDoc
         */
        _initElement: function() {
          this._ignoreLayout = true;
          $super._initElement.call(this);
          this._imageContainer = this._element.querySelector('.gbc-label-image-container');
          this._commentContainer = this._element.querySelector('.gbc-label-comment-container');
          this._textContainer = this._element.querySelector('.gbc-label-text-container');
        },

        /**
         * @inheritDoc
         */
        _initLayout: function() {
          // no layout
        },

        /**
         * @inheritDoc
         */
        destroy: function() {
          this._imageContainer = null;
          this._commentContainer = null;
          $super.destroy.call(this);
        },

        /**
         * Defines the image source
         * @param {string} imgSrc - url of the label image
         */
        setImage: function(imgSrc) {
          var img = cls.WidgetFactory.createWidget('Image', this.getBuildParameters());
          img.setSrc(imgSrc);
          this._imageContainer.innerHTML = img._element.innerHTML;
          img.destroy();
        },

        /**
         * Set the text of the label comment
         * @param {string} comment - text to set as comment
         */
        setComment: function(comment) {
          this._commentContainer.innerText = comment;
        },

      };
    });
    cls.WidgetFactory.registerBuilder('MenuLabelWidget', cls.MenuLabelWidget);
  });

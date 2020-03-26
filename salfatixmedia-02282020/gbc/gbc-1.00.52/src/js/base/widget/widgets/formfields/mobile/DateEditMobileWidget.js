/// FOURJS_START_COPYRIGHT(D,2018)
/// Property of Four Js*
/// (c) Copyright Four Js 2018, 2019. All Rights Reserved.
/// * Trademark of Four Js Development Tools Europe Ltd
///   in the United States and elsewhere
/// 
/// This file can be modified by licensees according to the
/// product manual.
/// FOURJS_END_COPYRIGHT

'use strict';

modulum('DateEditMobileWidget', ['DateEditWidgetBase', 'WidgetFactory'],
  function(context, cls) {

    /**
     * DateEdit widget Mobile.
     * Limitations: you cannot use some 4ST : daysOff, firstDayOfWeek, showCurrentMonthOnly, showWeekNumber
     * @class DateEditMobileWidget
     * @memberOf classes
     * @extends classes.DateEditWidgetBase
     * @publicdoc Widgets
     */
    cls.DateEditMobileWidget = context.oo.Class(cls.DateEditWidgetBase, function($super) {
      return /** @lends classes.DateEditMobileWidget.prototype */ {
        __name: 'DateEditMobileWidget',

        /**
         * @type {Node}
         */
        _pickerLabel: null,

        // TODO cleaning it should have no pikaday in mobile version ?

        /**
         * @inheritDoc
         */
        _initElement: function() {
          $super._initElement.call(this);

          this._inputElement.setAttribute("data-date", "");

          // Trick to open picker when touching icon
          this._inputElement.setAttribute("id", this.getRootClassName() + "_input");
          this._pickerLabel = this._element.getElementsByTagName("label")[0];
          this._pickerLabel.setAttribute("for", this.getRootClassName() + "_input");

          this._pikerIcon.on('touchstart.IconDateEditWidget', this._onIconClick.bind(this));
          this._element.on('touchstart.DateEditMobileWidget', this._onTouchStart.bind(this));
          this._inputElement.on("change.DateEditMobileWidget", function(event) {
            if (this.isEnabled()) {
              var valueAsDate = event.target.valueAsDate;
              if (valueAsDate) {
                var d = {
                  year: valueAsDate.getUTCFullYear(),
                  month: valueAsDate.getUTCMonth() + 1,
                  day: valueAsDate.getUTCDate()
                };
                var momentDate = gbc.moment(d.year + "-" + d.month + "-" + d.day, "YYYY-MM-DD");
                if (momentDate.isValid()) {
                  this.setValue(momentDate.format(this._displayFormat));
                }
              } else {
                this.setValue("");
              }
              this.emit(context.constants.widgetEvents.change);
            }
          }.bind(this));
        },

        /**
         * @inheritDoc
         */
        destroy: function() {
          this._pikerIcon.off('touchstart.IconDateEditWidget');
          this._element.off('touchstart.DateEditMobileWidget');
          this._inputElement.off("change.DateEditMobileWidget");
          $super.destroy.call(this);
        },

        /**
         * Overrided to prevent pikaday picker to open
         */
        _onIconClick: function(event) {
          event.stopPropagation();
          // if widget already has VM focus, we need to explicitly set focus to input when clicking on dateedit icon, otherwise keyboard binding are not trapped.
          // if widget doesn't have VM focus, VM will set focus to input.
          if (this.hasVMFocus() && this.isEnabled()) {
            this._inputElement.domFocus();
          }
          this._onRequestFocus(event); // request focus
        },

        /**
         * Handler when input is touched
         * @param event
         * @private
         */
        _onTouchStart: function(event) {
          if (this.isEnabled()) {
            this._onRequestFocus(event); // request focus
          } else {
            event.stopPropagation();
            event.stopImmediatePropagation();
            event.preventCancelableDefault();
            return false;
          }
        },

        /**
         * @inheritDoc
         */
        setValue: function(value, fromVM) {
          // if from VM, convert it to good format, so it can open the picker at the right date!
          if (fromVM) {
            var dateObj = context.moment(value, this._displayFormat);
            if (dateObj.isValid()) {
              this._inputElement.value = dateObj.format("YYYY-MM-DD");
            } else {
              this._inputElement.value = value;
            }
          }
          this._inputElement.setAttribute("data-date", value);
        },

        /**
         * @inheritDoc
         */
        getValue: function() {
          return this._inputElement.getAttribute("data-date");
        }

      };
    });
  });

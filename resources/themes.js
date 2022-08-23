const oObjectFreeze = this.Object.freeze;

Object.freeze = function (obj, ...args) {
  if (!obj?.hasOwnProperty) {
    return oObjectFreeze.call(this, obj, ...args);
  }

  try {
    const theme = %@;

    if (obj.hasOwnProperty?.('BACKGROUND_PRIMARY')) {
      return oObjectFreeze.call(this, Object.assign(obj, theme.theme_color_map), ...args);
    }

    if (obj.hasOwnProperty?.('PRIMARY_DARK')) {
      return oObjectFreeze.call(this, Object.assign(obj, theme.colours), ...args);
    }

    if (obj.hasOwnProperty?.('CHAT_GREY')) {
      return oObjectFreeze.call(this, Object.assign(obj,theme.unsafe_colors), ...args);
    }
  } catch (e) {
    console.log(e);
  }

  return oObjectFreeze.apply(this, [obj, ...args]);
};
